#!/usr/bin/env bash
# Install the demo-seed release APK, launch it, and record logcat.
# Called by android-emulator-runner with bash (the action itself uses dash).
#
# The APK is a release build with DEMO_BUILD and ENABLE_ADMIN_TOOLS, the
# same defines as the demo Sanu installs. CI signs it with an ephemeral
# keystore because the Play upload key is not on the runner. Release mode
# (AOT, no assertions, Impeller on) matches that demo.
#
# Success means: the Terms gate is on screen, Accept opens Home, a second
# process start keeps that acceptance and does not paint the error
# fallback (this APK has ENABLE_ADMIN_TOOLS, the build that crashed), and
# the Admin panel opens. The script never taps Seed, so it does not write
# sample temples to production Firestore.
set -euo pipefail

PKG=com.shradhaventures.temple
APK="${DEMO_SEED_APK:-build/app/outputs/flutter-apk/app-release.apk}"
OUT="${DEMO_SEED_OUT:-${GITHUB_WORKSPACE:-/tmp}/demo-seed-launch}"
mkdir -p "$OUT"

dump_logcat() {
  timeout 20s adb logcat -d -v time >"$OUT/logcat.txt" 2>/dev/null || true
  echo "===== flutter / fatal excerpt ====="
  if [[ -f "$OUT/logcat.txt" ]]; then
    grep -E 'flutter|AndroidRuntime|FATAL|Exception|Error:' "$OUT/logcat.txt" | tail -n 160 || true
  fi
}

screenshot() {
  local name="$1"
  adb exec-out screencap -p >"$OUT/${name}.png" 2>/dev/null || true
}

hierarchy() {
  # A stuck dump has taken the emulator offline. Cap it.
  timeout 10s adb shell uiautomator dump /sdcard/uidump.xml >/dev/null 2>&1 || return 0
  timeout 8s adb exec-out cat /sdcard/uidump.xml >"$OUT/uidump.xml" 2>/dev/null || true
}

# Prints "x y" for the first node whose text, content-desc, or resource-id
# contains the needle. Empty when nothing matches.
find_tap() {
  local needle="$1"
  [[ -f "$OUT/uidump.xml" ]] || return 0
  python3 -c '
import re, sys
needle, xml = sys.argv[1], sys.stdin.read()
pattern = re.compile(r"<node\b[^>]*>")
attr = re.compile(r"(text|content-desc|resource-id)=\"([^\"]*)\"")
bounds = re.compile(r"bounds=\"\[(\d+),(\d+)\]\[(\d+),(\d+)\]\"")
for node in pattern.findall(xml):
    fields = dict(attr.findall(node))
    blob = " ".join(fields.values())
    if needle not in blob:
        continue
    match = bounds.search(node)
    if not match:
        continue
    x1, y1, x2, y2 = map(int, match.groups())
    x = (x1 + x2) // 2
    y = (y1 + y2) // 2
    # App-bar actions are drawn under the status bar. The center
    # (More is about y=74) never lands, and the last few pixels miss
    # the hit target. A point about a fifth up from the bottom does.
    if y2 < 200 and y < 140:
        inset = max(8, (y2 - y1) // 5)
        y = y2 - inset
        if y <= y1:
            y = (y1 + y2) // 2
    print(x, y)
    break
' "$needle" <"$OUT/uidump.xml" || true
}

visible() {
  local needle="$1"
  hierarchy
  [[ -f "$OUT/uidump.xml" ]] || return 1
  grep -q "$needle" "$OUT/uidump.xml"
}

tap_needle() {
  local needle="$1"
  hierarchy
  local point
  point="$(find_tap "$needle")"
  if [[ -z "$point" ]]; then
    echo "not on screen: $needle" >&2
    return 1
  fi
  echo "tap $needle at $point"
  # shellcheck disable=SC2086
  adb shell input tap $point
}

# Tap Wait on OS dialogs and on Google Play services
# (com.google.android.gms and its processes): "Process system isn't
# responding", "Pixel Launcher isn't responding", "System UI isn't
# responding", and "Google Play services isn't responding". Any other
# isn't-responding dialog is this app's ANR: save a screenshot and fail.
dismiss_system_anr() {
  hierarchy
  [[ -f "$OUT/uidump.xml" ]] || return 0
  local os_dialog dialog pattern
  for os_dialog in \
    "Process system isn't responding" \
    "Pixel Launcher isn't responding" \
    "System UI isn't responding" \
    "Google Play services isn't responding"
  do
    if grep -q "$os_dialog" "$OUT/uidump.xml"; then
      echo "Dismissing $os_dialog"
      tap_needle "Wait" || true
      return 0
    fi
  done
  if grep -q "isn't responding" "$OUT/uidump.xml"; then
    pattern='[^"]*isn'"'"'t responding'
    dialog="$(grep -o "$pattern" "$OUT/uidump.xml" | head -n 1 || true)"
    if [[ "$dialog" == *com.google.android.gms* ]]; then
      echo "Dismissing $dialog"
      tap_needle "Wait" || true
      return 0
    fi
    if [[ -z "$dialog" ]]; then
      dialog="an isn't-responding dialog is on screen"
    fi
    echo "App ANR: ${dialog}. Failing the job." >&2
    screenshot app-anr
    exit 1
  fi
}

wait_for() {
  local needle="$1"
  local tries="${2:-20}"
  local i
  for i in $(seq 1 "$tries"); do
    if ! adb get-state 2>/dev/null | grep -q '^device$'; then
      echo "adb device is gone while waiting for: $needle" >&2
      return 1
    fi
    dismiss_system_anr
    if visible "$needle"; then
      echo "visible: $needle"
      return 0
    fi
    sleep 2
  done
  echo "timed out waiting for: $needle" >&2
  return 1
}

# Second process start after Accept. pm clear has not run, so Terms stay
# accepted. ENABLE_ADMIN_TOOLS is on for this release APK: Home used to
# construct AdminAuth in build and paint the no-app error. 0x10008000 is
# FLAG_ACTIVITY_NEW_TASK | FLAG_ACTIVITY_CLEAR_TASK (a fresh task, not a
# data clear).
assert_terms_kept_relaunch() {
  echo "===== second launch with terms kept ====="
  timeout 15s adb logcat -c || true
  timeout 15s adb shell am force-stop "$PKG" || true
  sleep 1
  timeout 30s adb shell am start -W -n "${PKG}/.MainActivity" -f 0x10008000 || true
  if ! wait_for "More" 15 && ! wait_for "Loading temples" 5; then
    echo "Second launch did not reach Home with Terms kept"
    screenshot relaunch
    return 1
  fi
  screenshot relaunch
  hierarchy
  local bad
  for bad in \
    "Something went wrong" \
    "No Firebase App" \
    "[core/no-app]" \
    "Before you begin" \
    "policy-accept-button"
  do
    if [[ -f "$OUT/uidump.xml" ]] && grep -F -q "$bad" "$OUT/uidump.xml"; then
      echo "Second launch showed: $bad"
      return 1
    fi
  done
  echo "second launch kept Terms and did not paint the error fallback"
  return 0
}

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
  dump_logcat
  exit 1
fi

adb shell input keyevent KEYCODE_WAKEUP || true
adb shell wm dismiss-keyguard || true
adb shell settings put global window_animation_scale 0 || true
adb shell settings put global transition_animation_scale 0 || true
adb shell settings put global animator_duration_scale 0 || true

if [[ ! -f "$APK" ]]; then
  echo "error: demo-seed apk not found: $APK" >&2
  exit 1
fi

echo "===== install release apk ====="
adb uninstall "$PKG" || true
adb install -r "$APK"
adb shell pm path "$PKG"

adb logcat -c || true
# The app bar is drawn under the status bar. A tap on the reported
# center of More is delivered to the bar, so the overflow never opens.
adb shell settings put global policy_control immersive.full='*' || true
echo "===== launch ====="
adb shell am start -W -n "${PKG}/.MainActivity" || true

status=0
if ! wait_for "Before you begin" 25; then
  echo "Terms gate did not appear"
  status=1
else
  screenshot gate
  if ! tap_needle "policy-accept-button"; then
    echo "Accept control was not tappable"
    status=1
  elif ! wait_for "More" 25 && ! wait_for "Temple Directory" 5; then
    echo "Home did not appear after Accept"
    status=1
  else
    screenshot home
    # Relaunch while acceptance is still stored. The offline section
    # below clears data and must stay after this check.
    if ! assert_terms_kept_relaunch; then
      status=1
    fi
    # Admin sign-in is in the Home overflow (tooltip More). Do not tap Seed.
    if visible "Seed sample temples"; then
      echo "Seed write button is on screen; refusing to tap it"
      status=1
    fi
    if ! tap_needle "More"; then
      echo "Admin overflow was not on Home"
      status=1
    else
      sleep 1
      hierarchy
      if [[ -f "$OUT/uidump.xml" ]] && ! grep -q "Admin sign-in" "$OUT/uidump.xml"; then
        # The item is a button just under the app bar, right-aligned.
        # Tap there once when the dump has not exposed the label yet.
        adb shell input tap 960 210 || true
        sleep 1
      fi
      if ! tap_needle "Admin sign-in" && ! tap_needle "Admin Panel"; then
        sleep 1
        if ! adb get-state 2>/dev/null | grep -q '^device$'; then
          echo "adb device is gone before Admin sign-in"
          status=1
        elif ! tap_needle "Admin sign-in"; then
          echo "Admin entry was not on Home"
          status=1
        fi
      fi
      if [[ "$status" -eq 0 ]] && ! wait_for "Admin sign-in required" 8; then
        echo "Admin panel did not open"
        status=1
      else
        screenshot admin
        if visible "Seed sample temples"; then
          echo "Seed write button opened; not tapping it"
          status=1
        fi
      fi
    fi
  fi
fi

screenshot final

# Second launch with the radios off. Bundled fonts must still paint the
# gate. pm clear drops any acceptance from the online pass. Do not tap Seed.
echo "===== offline relaunch ====="
# Bound these. A stuck logcat or am start used to hold the 18-minute
# shell timeout after Home was already on screen.
timeout 20s adb logcat -d -v time >"$OUT/logcat-online.txt" 2>/dev/null || true
timeout 15s adb shell svc wifi disable || true
timeout 15s adb shell svc data disable || true
timeout 20s adb shell pm clear "$PKG" || true
timeout 15s adb logcat -c || true
timeout 30s adb shell am start -W -n "${PKG}/.MainActivity" || true
if ! wait_for "Before you begin" 20; then
  echo "Terms gate did not appear with the network disabled"
  status=1
else
  screenshot offline
fi
adb shell svc wifi enable || true
adb shell svc data enable || true

dump_logcat
cp "$OUT/logcat.txt" "$OUT/logcat-offline.txt" 2>/dev/null || true
if [[ "$status" -ne 0 ]]; then
  echo "demo-seed launch failed; see $OUT/logcat.txt" >&2
fi
exit "$status"
