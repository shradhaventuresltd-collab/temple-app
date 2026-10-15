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
# An OS ANR dialog covers the temple app. Do not set hide_error_dialogs:
# that flag hides every ANR, including one from com.shradhaventures.temple.
# Wait is tapped for Process system, Pixel Launcher, System UI, and
# Google Play services (com.google.android.gms). An ANR from this app fails.
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
  if [[ -n "$attempt_dir" ]]; then
    mkdir -p "$attempt_dir"
    # Full buffer since the relaunch cleared logcat. A short tail rotates
    # the crash out by the time Maestro's wait ends.
    adb logcat -d >"${attempt_dir}/logcat.txt" || true
    adb exec-out screencap -p >"${attempt_dir}/relaunch.png" || true
    if [[ -s "${attempt_dir}/logcat.txt" ]]; then
      grep -E 'flutter|FlutterJNI|AndroidRuntime|FATAL|core/no-app' \
        "${attempt_dir}/logcat.txt" | tail -n 80 || true
    fi
  else
    adb logcat -d -t 400 || true
  fi
  if [[ -d "$attempt_dir" ]]; then
    find "$attempt_dir" -type f -name '*.log' -print -exec tail -n 80 {} \;
  fi
}

# Get Directions leaves the https stub resumed. Maestro's launchApp
# force-stops this package and returns as soon as the start is issued,
# so the hierarchy stays on the stub and the new process is not resumed.
# Stop the stub (and press Back) before starting our activity in a fresh
# task. force-stop and CLEAR_TASK do not clear app data.
leave_directions_handoff() {
  adb shell input keyevent KEYCODE_BACK || true
  adb shell am force-stop com.android.fakesystemapp || true
  adb shell am force-stop com.shradhaventures.handoff || true
  adb shell input keyevent KEYCODE_HOME || true
}

temple_resumed() {
  adb shell dumpsys activity activities \
    | grep -E 'topResumedActivity|mResumedActivity' \
    | grep -q "$PKG"
}

# Cold process start with Terms still accepted. FLAG_ACTIVITY_NEW_TASK |
# FLAG_ACTIVITY_CLEAR_TASK (0x10008000) starts a fresh task so the
# directions stub cannot stay resumed. Maestro then asserts Home and must
# not stop the process again (stopApp: false in the flow).
second_process_start() {
  leave_directions_handoff
  adb logcat -c || true
  adb shell am force-stop "$PKG" || true
  sleep 1
  adb shell am start -W -n "${PKG}/.MainActivity" -f 0x10008000 || true
  local pid=""
  local attempt
  for attempt in $(seq 1 20); do
    pid="$(adb shell pidof "$PKG" 2>/dev/null | tr -d '\r' || true)"
    if [[ -n "$pid" ]]; then
      break
    fi
    sleep 1
  done
  if [[ -z "$pid" ]]; then
    echo "Second launch did not keep a process." >&2
    return 1
  fi
  echo "second launch pid ${pid}"
  for attempt in $(seq 1 15); do
    if temple_resumed; then
      echo "second launch is the resumed activity"
      return 0
    fi
    leave_directions_handoff
    adb shell am start -W -n "${PKG}/.MainActivity" -f 0x10008000 || true
    sleep 1
  done
  echo "Second launch process is not the resumed activity." >&2
  return 1
}

warn_if_flow_retried() {
  local log="$1"
  local attempt="$2"
  if [[ -f "$log" ]] && grep -E -q 'Retrying the commands|failed for retry command' "$log"; then
    warn "Maestro flow relaunch or retry ran during attempt ${attempt}"
  fi
}

# Tap Wait on "Process system isn't responding",
# "Pixel Launcher isn't responding", "System UI isn't responding",
# and "Google Play services isn't responding" (including a dialog whose
# text names com.google.android.gms). Any other isn't-responding dialog
# is this app's ANR: save a screenshot and fail the job.
dismiss_anr_dialog() {
  adb shell uiautomator dump /sdcard/uidump.xml >/dev/null 2>&1 || return 0
  local xml labels os_dialog candidate dialog pattern
  xml="$(adb exec-out cat /sdcard/uidump.xml 2>/dev/null || true)"
  os_dialog=""
  for candidate in \
    "Process system isn't responding" \
    "Pixel Launcher isn't responding" \
    "System UI isn't responding" \
    "Google Play services isn't responding"
  do
    if grep -q "$candidate" <<<"$xml"; then
      os_dialog="$candidate"
      break
    fi
  done
  if [[ -z "$os_dialog" ]] && grep -q "isn't responding" <<<"$xml"; then
    pattern='[^"]*isn'"'"'t responding'
    dialog="$(grep -o "$pattern" <<<"$xml" | head -n 1 || true)"
    if [[ "$dialog" == *com.google.android.gms* ]]; then
      os_dialog="$dialog"
    fi
  fi
  if [[ -n "$os_dialog" ]]; then
    warn "Dismissing ${os_dialog} before Maestro"
    labels=$'Wait'
  elif grep -q "isn't responding" <<<"$xml"; then
    pattern='[^"]*isn'"'"'t responding'
    dialog="$(grep -o "$pattern" <<<"$xml" | head -n 1 || true)"
    if [[ -z "$dialog" ]]; then
      dialog="an isn't-responding dialog is on screen"
    fi
    echo "App ANR: ${dialog}. Failing the job." >&2
    mkdir -p "${GITHUB_WORKSPACE:-/tmp}/screenshots"
    adb exec-out screencap -p >"${GITHUB_WORKSPACE:-/tmp}/screenshots/app-anr.png" || true
    exit 1
  else
    return 0
  fi
  local point
  point="$(ANR_LABELS="$labels" python3 -c '
import os, re, sys
xml = sys.stdin.read()
for label in os.environ["ANR_LABELS"].splitlines():
    if not label:
        continue
    m = re.search(
        r"text=\"" + re.escape(label) + r"\"[^>]*bounds=\"\[(\d+),(\d+)\]\[(\d+),(\d+)\]\"",
        xml,
    )
    if not m:
        m = re.search(
            r"bounds=\"\[(\d+),(\d+)\]\[(\d+),(\d+)\]\"[^>]*text=\"" + re.escape(label) + r"\"",
            xml,
        )
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
  if grep -q "App ANR:" "${out}/maestro-stdout.log"; then
    echo "App ANR: Temple Directory India isn't responding. Failing the job." >&2
    exit 1
  fi
  warn_if_flow_retried "${out}/maestro-stdout.log" "$attempt"
  if [[ "$status" -eq 0 ]]; then
    # Terms are already accepted. Relaunch without clearing state and fail
    # if Home paints the release error fallback. This stays inside the
    # 12-minute shell timeout; screenshots are still skipped when the job
    # clock is past 600 seconds.
    echo "===== second launch after terms ====="
    second="${DEBUG_ROOT}/second-launch"
    mkdir -p "$second"
    set +e
    second_process_start
    start_status=$?
    set -e
    if [[ "$start_status" -ne 0 ]]; then
      echo "Second launch did not resume Home." >&2
      dump_failure "$second"
      exit "$start_status"
    fi
    set +e
    maestro test --debug-output "$second" .maestro/second_launch_home.yaml \
      2>&1 | tee "${second}/maestro-stdout.log"
    second_status=$?
    set -e
    adb exec-out screencap -p >"${second}/relaunch.png" || true
    if [[ "$second_status" -ne 0 ]]; then
      echo "Second launch showed an error or did not reach Home." >&2
      dump_failure "$second"
      exit "$second_status"
    fi

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
