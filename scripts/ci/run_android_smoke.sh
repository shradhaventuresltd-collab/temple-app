#!/usr/bin/env bash
# Invoked by android-emulator-runner. The action runs its script with
# /usr/bin/sh (dash), which rejects `set -o pipefail`, so the workflow
# calls this file instead of inlining bash options.
set -euo pipefail

# Used only when the workflow did not record JOB_START_EPOCH.
SCRIPT_START_EPOCH="$(date +%s)"

# shellcheck source=screenshot_budget.sh
source "$(dirname "$0")/screenshot_budget.sh"

export PATH="${PATH}:${HOME}/.maestro/bin"
export MAESTRO_CLI_NO_ANALYTICS=1

PKG=com.shradhaventures.temple
APK=build/app/outputs/flutter-apk/app-profile.apk
# Each Maestro attempt keeps its own debug directory. The workflow uploads
# this tree with actions/upload-artifact, including failed attempts.
DEBUG_ROOT="${MAESTRO_DEBUG_ROOT:-${GITHUB_WORKSPACE:-/tmp}/maestro-debug}"
mkdir -p "$DEBUG_ROOT"

echo "===== wait for boot ====="
adb wait-for-device
boot=""
for _ in $(seq 1 60); do
  boot="$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')"
  if [[ "$boot" == "1" ]]; then
    echo "sys.boot_completed=1"
    break
  fi
  sleep 2
done
if [[ "$boot" != "1" ]]; then
  echo "error: sys.boot_completed did not become 1" >&2
  exit 1
fi

for _ in $(seq 1 30); do
  if adb shell pm path android >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

adb shell input keyevent KEYCODE_WAKEUP || true
adb shell wm dismiss-keyguard || true
# A Pixel Launcher ANR covers the temple app. Do not set
# hide_error_dialogs: that flag hides every ANR, including one from
# com.shradhaventures.temple. Only a Pixel Launcher dialog is dismissed.
# The runner also disables animations. Set them again after boot so a
# late settings restart cannot leave window animations on.
adb shell settings put global window_animation_scale 0 || true
adb shell settings put global transition_animation_scale 0 || true
adb shell settings put global animator_duration_scale 0 || true

echo "===== install apk ====="
# The cached AVD keeps the previous install. Each runner signs the profile
# APK with a new debug key, so replace-install fails until the old package
# is removed.
adb uninstall "$PKG" || true
adb install -r "$APK"
adb shell pm path "$PKG"

bash scripts/ci/install_https_handoff.sh
echo "===== maps handler ====="
adb shell pm resolve-activity -a android.intent.action.VIEW \
  -d "https://www.google.com/maps/search/?api=1&query=9.9195,78.1193" || true

# Log tag only. `io.flutter` in ActivityManager lines is the activity
# class name and appears before the engine has drawn anything.
flutter_engine_logged() {
  adb logcat -d -t 400 \
    | grep -E -q '[VDIWEF][/ ](flutter|FlutterJNI)([^[:alnum:]_]|$)'
}

warn() {
  echo "::warning::$*"
}

# Prove the process can draw before Maestro. A cold profile start on
# swiftshader sometimes never attaches; two relaunches cover that.
echo "===== warm launch ====="
drawn=0
for attempt in 1 2 3; do
  if [[ "$attempt" -gt 1 ]]; then
    warn "Warm launch relaunch ${attempt} was needed; the Flutter engine had not logged yet"
  fi
  echo "warm launch ${attempt}"
  adb logcat -c || true
  adb shell am force-stop "$PKG" || true
  adb shell am start -W -n "${PKG}/.MainActivity" || true
  for _ in $(seq 1 30); do
    if flutter_engine_logged; then
      echo "Flutter engine log seen on warm launch ${attempt}"
      drawn=1
      break
    fi
    sleep 2
  done
  if [[ "$drawn" -eq 1 ]]; then
    break
  fi
  echo "no Flutter engine log on warm launch ${attempt}"
done
if [[ "$drawn" -ne 1 ]]; then
  warn "Warm launch never logged the Flutter engine after 3 attempts; Maestro will retry the launch"
fi
adb shell am force-stop "$PKG" || true

dump_failure() {
  local attempt_dir="$1"
  echo "===== foreground activity ====="
  adb shell dumpsys activity activities \
    | grep -E "topResumedActivity|mResumedActivity|ResumedActivity" \
    | head -n 20 || true
  echo "===== pid ====="
  adb shell pidof "$PKG" || true
  echo "===== maestro hierarchy ====="
  maestro hierarchy || true
  echo "===== logcat ====="
  adb logcat -d -t 250 || true
  if [[ -d "$attempt_dir" ]]; then
    find "$attempt_dir" -type f -name '*.log' -print -exec tail -n 80 {} \;
  fi
}

warn_if_flow_retried() {
  local log="$1"
  local attempt="$2"
  if [[ -f "$log" ]] && grep -E -q 'Retrying the commands|failed for retry command' "$log"; then
    warn "Maestro flow relaunch or retry ran during attempt ${attempt}"
  fi
}

# Tap Wait (or Close app) only on the Pixel Launcher ANR dialog.
# An ANR from this app ("Temple Directory India isn't responding") stays up.
dismiss_anr_dialog() {
  adb shell uiautomator dump /sdcard/uidump.xml >/dev/null 2>&1 || return 0
  local xml
  xml="$(adb exec-out cat /sdcard/uidump.xml 2>/dev/null || true)"
  if ! grep -q "Pixel Launcher isn't responding" <<<"$xml"; then
    return 0
  fi
  warn "Dismissing the Pixel Launcher isn't-responding dialog before Maestro"
  local point
  point="$(python3 -c '
import re, sys
xml = sys.stdin.read()
for label in ("Wait", "Close app"):
    m = re.search(r"text=\"" + label + r"\"[^>]*bounds=\"\[(\d+),(\d+)\]\[(\d+),(\d+)\]\"", xml)
    if not m:
        m = re.search(r"bounds=\"\[(\d+),(\d+)\]\[(\d+),(\d+)\]\"[^>]*text=\"" + label + r"\"", xml)
    if m:
        x1, y1, x2, y2 = map(int, m.groups())
        print((x1 + x2) // 2, (y1 + y2) // 2)
        break
' <<<"$xml" || true)"
  if [[ -n "$point" ]]; then
    # shellcheck disable=SC2086
    adb shell input tap $point || true
    sleep 1
  fi
}

# Read-only shots after the gate. A miss must not fail the 12-minute script.
capture_screenshots() {
  local shot_raw="${GITHUB_WORKSPACE:-/tmp}/screenshots-raw"
  local shot_dir="${GITHUB_WORKSPACE:-/tmp}/screenshots"
  mkdir -p "$shot_raw" "$shot_dir"
  echo "===== screenshots ====="
  set +e
  maestro test \
    --debug-output "$shot_raw" \
    --test-output-dir "$shot_raw" \
    .maestro/screenshots.yaml
  local shot_status=$?
  set -e
  if [[ "$shot_status" -ne 0 ]]; then
    warn "Screenshot flow failed; the smoke gate ignores it"
  fi
  return "$shot_status"
}

# Maestro writes PNGs during the flow. Copy them in the parent so a
# timeout still uploads the shots that already completed.
copy_screenshots() {
  local shot_raw="${GITHUB_WORKSPACE:-/tmp}/screenshots-raw"
  local shot_dir="${GITHUB_WORKSPACE:-/tmp}/screenshots"
  local count
  mkdir -p "$shot_raw" "$shot_dir"
  find "$shot_raw" -name '[0-9][0-9]-*.png' -exec cp --update=none {} "$shot_dir/" \;
  count="$(find "$shot_dir" -name '*.png' | wc -l | tr -d ' ')"
  echo "copied ${count} screenshot(s)"
  if [[ "$count" -eq 0 ]]; then
    warn "Screenshot flow produced no PNGs"
  fi
}

status=1
dismiss_anr_dialog || true
for attempt in 1 2; do
  if [[ "$attempt" -gt 1 ]]; then
    warn "Maestro smoke retry was needed after attempt 1 failed"
  fi
  echo "===== maestro attempt ${attempt} ====="
  out="${DEBUG_ROOT}/attempt-${attempt}"
  mkdir -p "$out"
  set +e
  maestro test --debug-output "$out" .maestro/read_only_smoke.yaml 2>&1 | tee "${out}/maestro-stdout.log"
  status=$?
  set -e
  warn_if_flow_retried "${out}/maestro-stdout.log" "$attempt"
  if [[ "$status" -eq 0 ]]; then
    # The workflow kills this script at 12 minutes. The screenshot budget
    # is measured from JOB_START_EPOCH (the job's first step), not from
    # $SECONDS, which only starts when this script starts. Skip once 600s
    # have passed since job start. Otherwise the timeout is
    # min(180, 780 - elapsed) seconds so the shots cannot run past 13
    # minutes of job time. A non-zero status does not fail the gate.
    job_start="${JOB_START_EPOCH:-}"
    if [[ -z "$job_start" ]]; then
      job_start="${SCRIPT_START_EPOCH}"
      warn "JOB_START_EPOCH is unset; screenshot budget counts from script start"
    fi
    elapsed=$(( $(date +%s) - job_start ))
    cap="$(screenshot_run_seconds "$elapsed")"
    if [[ -z "$cap" ]]; then
      warn "Skipping screenshots; ${elapsed}s have passed since the job started"
    else
      set +e
      timeout --kill-after=10s "${cap}s" bash -c "$(declare -f warn capture_screenshots); capture_screenshots"
      shot_rc=$?
      set -e
      if (( shot_rc != 0 )); then
        warn "Screenshot capture ended with status ${shot_rc}; the smoke gate ignores it"
      fi
      copy_screenshots
    fi
    exit 0
  fi
  dismiss_anr_dialog || true
  dump_failure "$out"
  if [[ "$attempt" -eq 1 ]]; then
    echo "maestro failed; one more full attempt"
    adb shell am force-stop "$PKG" || true
  fi
done

exit "$status"
