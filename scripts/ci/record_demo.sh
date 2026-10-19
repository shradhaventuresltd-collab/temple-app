#!/usr/bin/env bash
# One-off demo recording on the API 34 google_apis emulator.
# Read-only against the directory: no seed, no admin, no Firebase writes.
# The warm-up launch absorbs the Play services restart that follows boot.
# App data is cleared after that so the recorded take still shows
# Accept & continue. Recording uses screenrecord in segments of 170s.
set -uo pipefail

PKG=com.shradhaventures.temple
ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
OUT="$ROOT/demo-recording"
UI_PY="$ROOT/scripts/ci/demo_ui.py"
STAMP_PY="$ROOT/scripts/ci/demo_timestamps.py"
APK="${DEMO_APK:-$ROOT/build/app/outputs/flutter-apk/app-release.apk}"
TIMING="$OUT/timing.log"
STOP="$OUT/stop-record"
UI_XML="$OUT/ui.xml"
REC_PID=""
FAILED=0

mkdir -p "$OUT/segments" "$OUT/frames"
: > "$TIMING"
rm -f "$STOP"

log() {
  printf '%s %s\n' "$(date -u +%H:%M:%S)" "$*"
}

now_ms() {
  python3 -c 'import time; print(int(time.time() * 1000))'
}

mark_step() {
  local name="$1"
  echo "$(now_ms) STEP $name" >> "$TIMING"
  log "STEP $name"
}

shot() {
  local name="$1"
  adb exec-out screencap -p > "$OUT/frames/live-${name}.png" || true
}

dump_ui() {
  local attempt
  for attempt in 1 2 3; do
    if adb shell uiautomator dump /sdcard/uidump.xml >/dev/null 2>"$OUT/uidump.err"; then
      if adb pull /sdcard/uidump.xml "$UI_XML" >/dev/null 2>&1 && [[ -s "$UI_XML" ]]; then
        return 0
      fi
    fi
    sleep 1
  done
  return 1
}

ui_has() {
  dump_ui || return 1
  python3 "$UI_PY" has "$UI_XML" "$1"
}

tap_needle() {
  local needle="$1"
  local xy x y
  dump_ui || return 1
  xy="$(python3 "$UI_PY" find "$UI_XML" "$needle")" || return 1
  read -r x y <<<"$xy"
  log "tap '$needle' at $x $y"
  adb shell input tap "$x" "$y"
}

dismiss_anr() {
  dump_ui || return 0
  if ! grep -q "isn't responding" "$UI_XML"; then
    return 0
  fi
  log "ANR dialog is up; tapping Wait"
  python3 "$UI_PY" find "$UI_XML" "Wait" | {
    read -r x y || return 0
    adb shell input tap "$x" "$y" || true
  }
  sleep 1
}

wait_for() {
  local needle="$1"
  local seconds="$2"
  local deadline=$((SECONDS + seconds))
  local xy x y
  while (( SECONDS < deadline )); do
    if dump_ui; then
      if grep -q "isn't responding" "$UI_XML"; then
        log "ANR dialog is up; tapping Wait"
        xy="$(python3 "$UI_PY" find "$UI_XML" "Wait" || true)"
        if [[ -n "$xy" ]]; then
          read -r x y <<<"$xy"
          adb shell input tap "$x" "$y" || true
        fi
      elif python3 "$UI_PY" has "$UI_XML" "$needle"; then
        return 0
      fi
    fi
    sleep 1
  done
  log "timed out waiting for '$needle'"
  cp -f "$UI_XML" "$OUT/timeout-${needle//[^A-Za-z0-9_-]/_}.xml" 2>/dev/null || true
  shot "timeout-${needle//[^A-Za-z0-9_-]/_}" || true
  return 1
}

pause_on_screen() {
  sleep 2.7
}

wake() {
  adb shell input keyevent KEYCODE_WAKEUP || true
  adb shell wm dismiss-keyguard || true
  adb shell input keyevent 82 || true
}

skip_setup_wizard() {
  adb shell settings put global device_provisioned 1 || true
  adb shell settings put secure user_setup_complete 1 || true
  adb shell pm disable-user --user 0 com.google.android.setupwizard >/dev/null 2>&1 || true
  adb shell am start -a android.intent.action.MAIN -c android.intent.category.HOME >/dev/null 2>&1 || true
}

go_home() {
  adb shell input keyevent KEYCODE_HOME || true
  sleep 1
}

open_drawer_until_icon() {
  local attempt
  go_home
  if ui_has "Temple Directory"; then
    return 0
  fi
  for attempt in 1 2 3 4 5 6; do
    # Launcher3 / Pixel: swipe up from the workspace to the app list.
    adb shell input swipe 540 1900 540 700 280 || true
    sleep 1
    dismiss_anr || true
    if ui_has "Temple Directory"; then
      return 0
    fi
    if ui_has "Apps"; then
      tap_needle "Apps" || true
      sleep 1
      if ui_has "Temple Directory"; then
        return 0
      fi
    fi
    adb shell input swipe 540 1700 540 900 500 || true
    sleep 1
    if ui_has "Temple Directory"; then
      return 0
    fi
  done
  return 1
}

record_loop() {
  local n=1
  local start end
  while [[ ! -f "$STOP" && "$n" -le 4 ]]; do
    echo "$(now_ms) SEG_START $n" >> "$TIMING"
    start="$(date +%s)"
    set +e
    adb shell screenrecord --size 1080x2400 --bit-rate 8000000 --time-limit 170 \
      "/sdcard/demo-${n}.mp4" >"$OUT/screenrecord-${n}.log" 2>&1
    set -e
    end="$(date +%s)"
    echo "$(now_ms) SEG_END $n" >> "$TIMING"
    if (( end - start < 3 )) && grep -qiE 'invalid|error|failed|multiple of' "$OUT/screenrecord-${n}.log"; then
      log "screenrecord rejected the segment"
      cat "$OUT/screenrecord-${n}.log" >&2 || true
      echo fatal > "$OUT/screenrecord-fatal"
      break
    fi
    n=$((n + 1))
  done
}

stop_recording() {
  touch "$STOP"
  adb shell 'pid=$(pidof screenrecord || true); if [ -n "$pid" ]; then kill -INT $pid || true; fi' || true
  if [[ -n "$REC_PID" ]]; then
    wait "$REC_PID" || true
  fi
  sleep 1
}

pull_segments() {
  local remote base
  adb shell ls /sdcard/demo-*.mp4 >"$OUT/remote-segments.txt" 2>/dev/null || true
  while read -r remote; do
    remote="${remote//$'\r'/}"
    [[ -z "$remote" ]] && continue
    base="$(basename "$remote")"
    adb pull "$remote" "$OUT/segments/$base" >/dev/null 2>&1 || true
  done <"$OUT/remote-segments.txt"
}

finish_video() {
  local list="$OUT/segments/concat.txt"
  local seg duration
  : > "$list"
  shopt -s nullglob
  for seg in "$OUT/segments"/demo-*.mp4; do
    duration="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$seg" 2>/dev/null || true)"
    duration="${duration//$'\r'/}"
    if [[ -z "$duration" ]]; then
      log "skipping unplayable $seg"
      continue
    fi
    printf "file '%s'\n" "$seg" >> "$list"
  done
  shopt -u nullglob
  if [[ ! -s "$list" ]]; then
    log "no playable segments to concat"
    return 0
  fi
  if ! ffmpeg -y -f concat -safe 0 -i "$list" -c copy "$OUT/demo.mp4" >"$OUT/ffmpeg-concat.log" 2>&1; then
    log "ffmpeg concat failed"
    cat "$OUT/ffmpeg-concat.log" >&2 || true
    return 0
  fi
  python3 "$STAMP_PY" \
    --timing "$TIMING" \
    --segments-dir "$OUT/segments" \
    --output "$OUT/timestamps.md" \
    --video "$OUT/demo.mp4" \
    --frames-dir "$OUT/frames" || true
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" && -f "$OUT/timestamps.md" ]]; then
    cat "$OUT/timestamps.md" >> "$GITHUB_STEP_SUMMARY" || true
  fi
}

cleanup() {
  local status=$?
  set +e
  stop_recording
  pull_segments
  adb logcat -d -t 400 >"$OUT/logcat.txt" 2>/dev/null || true
  finish_video
  if [[ "$FAILED" -ne 0 && "$status" -eq 0 ]]; then
    status=1
  fi
  exit "$status"
}
# timeout(1) signals the process group. Catch it so the EXIT trap can
# still pull the segments and write demo.mp4.
trap 'exit 143' TERM INT
trap cleanup EXIT

require() {
  local needle="$1"
  local seconds="$2"
  if ! wait_for "$needle" "$seconds"; then
    FAILED=1
    return 1
  fi
}

log "waiting for the emulator"
adb wait-for-device
boot_deadline=$((SECONDS + 180))
until [[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; do
  if (( SECONDS > boot_deadline )); then
    log "sys.boot_completed did not become 1"
    FAILED=1
    exit 1
  fi
  sleep 2
done
log "sys.boot_completed=1"
wake
skip_setup_wizard
adb shell settings put global stay_on_while_plugged_in 7 || true
adb shell settings put global window_animation_scale 0 || true
adb shell settings put global transition_animation_scale 0 || true
adb shell settings put global animator_duration_scale 0 || true
adb shell settings put secure spell_checker_enabled 0 || true

if [[ ! -f "$APK" ]]; then
  log "APK missing at $APK"
  FAILED=1
  exit 1
fi

sdk="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
aapt="$(find "$sdk/build-tools" -type f -name aapt 2>/dev/null | sort | tail -n 1 || true)"
if [[ -n "$aapt" ]]; then
  badging="$("$aapt" dump badging "$APK" | head -n 1)"
  log "badging: $badging"
  if [[ "$badging" != *"name='${PKG}'"* ]]; then
    log "release APK package is not ${PKG}"
    FAILED=1
    exit 1
  fi
fi

log "installing $APK"
if ! adb install -r -d "$APK" >"$OUT/install.log" 2>&1; then
  cat "$OUT/install.log" >&2 || true
  FAILED=1
  exit 1
fi
if ! adb shell pm path "$PKG" | grep -q '^package:'; then
  log "package $PKG is not installed"
  FAILED=1
  exit 1
fi
log "installed $PKG"
adb shell wm size
adb shell wm density
# Pin the recorded frame. Pixel 6 is already this size; a no-op when it matches.
adb shell wm size 1080x2400 || true
adb shell wm density 420 || true

# Warm-up. Play services restarts shortly after first boot and can kill
# the process. Launch, wait until the gate is actually on screen, then
# hold it long enough for that restart to finish. Do not accept here.
log "warm-up launch"
adb shell am force-stop "$PKG" || true
adb shell am start -W -n "${PKG}/.MainActivity" >"$OUT/warmup-start.log" 2>&1 || true
if ! wait_for "Accept & continue" 90; then
  log "warm-up did not reach the gate; launching once more"
  adb shell am start -W -n "${PKG}/.MainActivity" >>"$OUT/warmup-start.log" 2>&1 || true
  require "Accept & continue" 60 || exit 1
fi
stable=0
for _ in 1 2 3 4 5 6; do
  sleep 5
  dismiss_anr || true
  pid="$(adb shell pidof "$PKG" 2>/dev/null | tr -d '\r' || true)"
  log "warm-up pid=${pid:-dead}"
  if [[ -n "$pid" ]] && ui_has "Accept & continue"; then
    stable=$((stable + 1))
  else
    stable=0
    adb shell am start -n "${PKG}/.MainActivity" >/dev/null 2>&1 || true
  fi
  if (( stable >= 3 )); then
    break
  fi
done
log "warm-up settled (stable=${stable})"

# Clear the acceptance written by nothing yet, and any cache the warm-up
# read, so the recorded launch is a cold first run. pm clear also
# force-stops the process.
adb shell pm clear "$PKG" >"$OUT/pm-clear.log" 2>&1 || true
go_home
# Dismiss a first-boot launcher coach mark before the take.
if ui_has "Got it"; then
  tap_needle "Got it" || true
  sleep 1
fi

log "starting screenrecord"
record_loop &
REC_PID=$!
sleep 2
if [[ -f "$OUT/screenrecord-fatal" ]]; then
  log "screenrecord failed to start"
  FAILED=1
  exit 1
fi

# (1) Launcher, the icon, Accept & continue.
mark_step launcher
if ! open_drawer_until_icon; then
  shot "launcher-miss"
  log "app icon was not on the launcher"
  FAILED=1
  exit 1
fi
shot "01-launcher"
pause_on_screen
if ! tap_needle "Temple Directory"; then
  FAILED=1
  exit 1
fi
require "Accept & continue" 60 || exit 1
mark_step accept
shot "01-accept"
pause_on_screen
tap_needle "Accept & continue" || { FAILED=1; exit 1; }

# (2) Home with the directory count.
home_deadline=$((SECONDS + 75))
home_retried=0
while (( SECONDS < home_deadline )); do
  dismiss_anr || true
  if ui_has "Update required" || ui_has "We'll be back soon"; then
    log "startup is blocked by update or maintenance"
    shot "02-blocked"
    FAILED=1
    exit 1
  fi
  if ui_has "temples across India"; then
    break
  fi
  if (( home_retried == 0 )) && ui_has "Could not load" && ui_has "Retry"; then
    tap_needle "Retry" || true
    home_retried=1
  fi
  sleep 2
done
if ! ui_has "temples across India"; then
  log "home did not show the temple count"
  FAILED=1
  exit 1
fi
if ui_has "Not now"; then
  tap_needle "Not now" || true
  sleep 1
fi
mark_step home
shot "02-home"
pause_on_screen

# (3) Kerala filter, then a slow scroll of that list.
if ! tap_needle "home-browse-temples" && ! tap_needle "Browse"; then
  adb shell input swipe 540 1600 540 800 500 || true
  sleep 0.6
  tap_needle "home-browse-temples" || tap_needle "Browse" || { FAILED=1; exit 1; }
fi
require "State" 30 || exit 1
pause_on_screen
tap_needle "State" || tap_needle "filter-chip-state" || { FAILED=1; exit 1; }
require "Filters" 20 || exit 1
for _ in 1 2 3 4; do
  if ui_has "Kerala"; then
    break
  fi
  adb shell input swipe 540 1600 540 900 600 || true
  sleep 0.6
done
require "Kerala" 10 || exit 1
tap_needle "Kerala" || { FAILED=1; exit 1; }
sleep 0.6
if ! tap_needle "Show"; then
  FAILED=1
  exit 1
fi
require "Kerala" 20 || exit 1
mark_step kerala
shot "03-kerala"
pause_on_screen
# Short travel, long duration: a slow scroll rather than a flick.
for _ in 1 2 3 4; do
  adb shell input swipe 540 1750 540 1250 1400 || true
  sleep 0.8
done
shot "03-kerala-scrolled"
pause_on_screen

# (4) Guruvayur: gallery, details, credit, Get Directions, then back.
found_guru=0
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16; do
  if ui_has "Guruvayur"; then
    found_guru=1
    break
  fi
  adb shell input swipe 540 1750 540 1150 700 || true
  sleep 0.5
done
if (( found_guru == 0 )); then
  log "Guruvayur was not on the scrolled Kerala list; using search"
  tap_needle "temple-list-search-field" || tap_needle "Name, city" || true
  sleep 0.4
  adb shell input text 'Guruvayur' || true
  sleep 1.2
  found_guru=1
fi
mark_step guruvayur
if ! tap_needle "Guruvayur"; then
  FAILED=1
  exit 1
fi
# The directions button is below the gallery. The title is enough to know
# the detail page opened; the later scroll brings the button up.
require "Guruvayur" 25 || exit 1
shot "04-guruvayur"
pause_on_screen
# Gallery sits in the top half of the 2400px display.
adb shell input swipe 900 700 180 700 450 || true
sleep 0.8
adb shell input swipe 900 700 180 700 450 || true
shot "04-gallery"
pause_on_screen
# Details and the credit line live under the gallery.
adb shell input swipe 540 1700 540 900 900 || true
sleep 0.6
mark_step credits
shot "04-credits"
pause_on_screen
for _ in 1 2 3 4 5 6; do
  if ui_has "Get Directions"; then
    break
  fi
  adb shell input swipe 540 1700 540 1000 800 || true
  sleep 0.4
done
mark_step directions
if tap_needle "Get Directions"; then
  sleep 1.2
  shot "04-directions"
  pause_on_screen
  # Chooser, browser, or the in-app snackbar. Come back to the detail page.
  for _ in 1 2 3; do
    focus="$(adb shell dumpsys window 2>/dev/null | grep -m1 mCurrentFocus | tr -d '\r' || true)"
    log "focus after directions: ${focus:-unknown}"
    if [[ "$focus" == *"$PKG"* ]]; then
      break
    fi
    adb shell input keyevent KEYCODE_BACK || true
    sleep 1
  done
  focus="$(adb shell dumpsys window 2>/dev/null | grep -m1 mCurrentFocus | tr -d '\r' || true)"
  if [[ "$focus" != *"$PKG"* ]]; then
    adb shell am start -n "${PKG}/.MainActivity" >/dev/null 2>&1 || true
    sleep 1
  fi
else
  log "Get Directions was not on screen"
  shot "04-directions-miss"
fi
pause_on_screen

# (5) Another Kerala temple that has photos.
adb shell input keyevent KEYCODE_BACK || true
sleep 1
if ! ui_has "State" && ! ui_has "Kerala"; then
  adb shell input keyevent KEYCODE_BACK || true
  sleep 1
fi
if ui_has "Clear search"; then
  tap_needle "Clear search" || true
  sleep 0.5
fi
second=""
for name in Padmanabhaswamy Vaikom Ettumanoor Thirunelli Chengannur; do
  for _ in 1 2 3 4 5 6; do
    if ui_has "$name"; then
      second="$name"
      break
    fi
    adb shell input swipe 540 1750 540 1150 650 || true
    sleep 0.4
  done
  if [[ -n "$second" ]]; then
    break
  fi
done
if [[ -z "$second" ]]; then
  log "scrolling did not reach another photo temple; searching Vaikom"
  tap_needle "temple-list-search-field" || tap_needle "Name, city" || true
  sleep 0.3
  adb shell input text 'Vaikom' || true
  sleep 1.2
  if ui_has "Vaikom"; then
    second="Vaikom"
  fi
fi
mark_step second-temple
if [[ -n "$second" ]]; then
  log "opening $second"
  tap_needle "$second" || true
else
  log "named Kerala temples were not visible; tapping another browse card"
  tap_needle "temple-browse-card" || true
fi
sleep 2
shot "05-second"
pause_on_screen
adb shell input swipe 900 700 180 700 450 || true
sleep 0.6
shot "05-second-gallery"
pause_on_screen
adb shell input keyevent KEYCODE_BACK || true
sleep 1

# (6) Typo search. Clear the state chip first so the result is the search.
if ui_has "Clear"; then
  tap_needle "Clear" || true
  sleep 0.6
fi
if ui_has "Clear search"; then
  tap_needle "Clear search" || true
  sleep 0.4
fi
mark_step search
if ! tap_needle "temple-list-search-field"; then
  tap_needle "Name, city" || { FAILED=1; exit 1; }
fi
sleep 0.4
# Leftover text from the Guruvayur or Vaikom fallback would append.
adb shell input keyevent KEYCODE_MOVE_END || true
adb shell 'for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24; do input keyevent 67; done' || true
adb shell input text 'guruvayoor' || true
sleep 1.5
# Drag dismisses the keyboard without Back, which would pop the list.
adb shell input swipe 540 1600 540 1200 400 || true
sleep 0.8
shot "06-search"
pause_on_screen

# (7) Offline, only when the shell allows the radio change.
mark_step offline
offline_ok=0
try_offline() {
  local label="$1"
  shift
  local out rc
  set +e
  out="$("$@" 2>&1)"
  rc=$?
  set -e
  printf '%s\n' "$out" >>"$OUT/offline.log"
  if (( rc != 0 )) || printf '%s' "$out" | grep -qiE 'denied|SecurityException|not found|error'; then
    log "offline command refused ($label)"
    return 1
  fi
  return 0
}
if try_offline airplane adb shell cmd connectivity airplane-mode enable \
  || try_offline settings adb shell settings put global airplane_mode_on 1 \
  || try_offline wifi adb shell svc wifi disable; then
  adb shell svc data disable >>"$OUT/offline.log" 2>&1 || true
  if wait_for "offline" 12; then
    offline_ok=1
    shot "07-offline"
    pause_on_screen
  else
    log "radios changed but the offline banner did not appear; skipping"
    echo "$(now_ms) STEP offline-skipped" >> "$TIMING"
  fi
else
  log "offline broadcast denied; skipping"
  echo "$(now_ms) STEP offline-skipped" >> "$TIMING"
  shot "07-offline-skipped"
fi
if (( offline_ok == 1 )); then
  log "offline banner shown"
fi

log "demo flow finished"
exit 0
