#!/usr/bin/env bash
# Invoked by android-emulator-runner. The action runs its script with
# /usr/bin/sh (dash), which rejects `set -o pipefail`, so the workflow
# calls this file instead of inlining bash options.
set -euo pipefail

export PATH="${PATH}:${HOME}/.maestro/bin"
export MAESTRO_CLI_NO_ANALYTICS=1

PKG=com.shradhaventures.temple
APK=build/app/outputs/flutter-apk/app-profile.apk

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
# The runner also disables animations. Set them again after boot so a
# late settings restart cannot leave window animations on.
adb shell settings put global window_animation_scale 0 || true
adb shell settings put global transition_animation_scale 0 || true
adb shell settings put global animator_duration_scale 0 || true

echo "===== install apk ====="
adb install -r "$APK"
adb shell pm path "$PKG"

bash scripts/ci/install_https_handoff.sh
echo "===== maps handler ====="
adb shell pm resolve-activity -a android.intent.action.VIEW \
  -d "https://www.google.com/maps/search/?api=1&query=9.9195,78.1193" || true

# Prove the process can draw before Maestro. A cold profile start on
# swiftshader sometimes never attaches; two relaunches cover that.
echo "===== warm launch ====="
drawn=0
for attempt in 1 2 3; do
  echo "warm launch ${attempt}"
  adb logcat -c || true
  adb shell am force-stop "$PKG" || true
  adb shell am start -W -n "${PKG}/.MainActivity" || true
  for _ in $(seq 1 30); do
    if adb logcat -d -t 400 | grep -E -q "flutter"; then
      echo "Flutter log seen on warm launch ${attempt}"
      drawn=1
      break
    fi
    sleep 2
  done
  if [[ "$drawn" -eq 1 ]]; then
    break
  fi
  echo "no Flutter log on warm launch ${attempt}"
done
if [[ "$drawn" -ne 1 ]]; then
  echo "warning: warm launch never logged Flutter; Maestro will retry the launch"
fi
adb shell am force-stop "$PKG" || true

dump_failure() {
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
  if [[ -d /tmp/maestro-debug ]]; then
    find /tmp/maestro-debug -type f -name '*.log' -print -exec tail -n 80 {} \;
  fi
}

status=1
for attempt in 1 2; do
  echo "===== maestro attempt ${attempt} ====="
  rm -rf /tmp/maestro-debug
  set +e
  maestro test --debug-output /tmp/maestro-debug .maestro
  status=$?
  set -e
  if [[ "$status" -eq 0 ]]; then
    exit 0
  fi
  dump_failure
  if [[ "$attempt" -eq 1 ]]; then
    echo "maestro failed; one more full attempt"
    adb shell am force-stop "$PKG" || true
  fi
done

exit "$status"
