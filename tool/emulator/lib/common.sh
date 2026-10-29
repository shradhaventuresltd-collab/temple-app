#!/usr/bin/env bash
# Shared adb helpers for emulator-app-test flows.
# Flows are sourced by run_one_flow.sh after this file.
# shellcheck disable=SC2034

if [[ -z "${EMULATOR_FLOW:-}" ]]; then
  echo "EMULATOR_FLOW is not set" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
UI_PY="${ROOT}/tool/emulator/lib/ui.py"
ARTIFACTS="${EMULATOR_ARTIFACTS:-${ROOT}/emulator-app-test-artifacts}"
FLOW="$EMULATOR_FLOW"
SHOT_DIR="${ARTIFACTS}/screenshots/${FLOW}"
REC_DIR="${ARTIFACTS}/recordings/${FLOW}"
LOG_DIR="${ARTIFACTS}/logcat"
DUMP_DIR="${ARTIFACTS}/dumps"
RESULTS="${ARTIFACTS}/results.txt"
DUMP="${DUMP_DIR}/${FLOW}.xml"
SHOT_N=0
PKG="${EMULATOR_PACKAGE:-}"

mkdir -p "$SHOT_DIR" "$REC_DIR" "$LOG_DIR" "$DUMP_DIR"

record_pass() {
  printf 'PASS %s: %s\n' "$FLOW" "$1" | tee -a "$RESULTS"
}

record_fail() {
  printf 'FAIL %s: %s: %s\n' "$FLOW" "$1" "$2" | tee -a "$RESULTS"
}

record_xfail() {
  printf 'XFAIL %s: %s: %s\n' "$FLOW" "$1" "$2" | tee -a "$RESULTS"
}

record_not_run() {
  printf 'NOT RUN %s: %s: %s\n' "$FLOW" "$1" "$2" | tee -a "$RESULTS"
}

step_shot() {
  local safe dest attempt
  SHOT_N=$((SHOT_N + 1))
  safe=$(printf '%s' "$1" | tr -c 'A-Za-z0-9_-' '_')
  dest="${SHOT_DIR}/$(printf '%02d_%s.png' "$SHOT_N" "$safe")"
  # screencap, not the screenrecord buffer. After a resize the first frame
  # can be black; wait until a capture has pixels, then keep that file.
  for attempt in 1 2 3 4 5; do
    if adb exec-out screencap -p > "$dest" && [[ -s "$dest" ]] \
      && python3 "$UI_PY" bright "$dest" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.6
  done
  adb exec-out screencap -p > "$dest" || true
}

pass_step() {
  record_pass "$1"
  step_shot "$1"
}

fail_step() {
  record_fail "$1" "$2"
  step_shot "$1"
  cp -f "$DUMP" "${DUMP_DIR}/${FLOW}_${1}.xml" 2>/dev/null || true
  # A sheet left open makes the next step fail on the wrong screen.
  dismiss_blockers || true
}

xfail_step() {
  record_xfail "$1" "$2"
  step_shot "$1"
  cp -f "$DUMP" "${DUMP_DIR}/${FLOW}_${1}.xml" 2>/dev/null || true
}

skip_step() {
  # NOT RUN is only for a step whose prerequisite already failed.
  # A skip with no FAIL in this flow is itself a failure.
  if ! grep -Eq "^FAIL ${FLOW}:" "$RESULTS" 2>/dev/null; then
    record_fail "$1" "no failed prerequisite: $2"
    step_shot "$1"
    cp -f "$DUMP" "${DUMP_DIR}/${FLOW}_${1}.xml" 2>/dev/null || true
    dismiss_blockers || true
    return
  fi
  record_not_run "$1" "$2"
  step_shot "$1"
}

# adb shell with a hard timeout. A frozen emulator otherwise blocks a
# scroll or wait loop on one swipe or dump forever.
adb_shell_capped() {
  local seconds="$1"
  shift
  local rc=0
  timeout "$seconds" adb shell "$@" || rc=$?
  if [[ "$rc" -eq 124 ]]; then
    echo "adb shell timed out after ${seconds}s: $*" >&2
    return 1
  fi
  return "$rc"
}

ui_screen_size() {
  local size_rc
  timeout 8 adb shell wm size | tr -d '\r' | awk '
    /Override size:/ { w=$3; next }
    /Physical size:/ { if (w == "") w=$3 }
    END {
      split(w, a, "x")
      if (a[1] != "" && a[2] != "") print a[1], a[2]
    }
  '
  # awk's status would hide a timed-out wm size. Keep timeout's code.
  size_rc=${PIPESTATUS[0]}
  if [[ "$size_rc" -eq 124 ]]; then
    echo "ui_screen_size: wm size timed out after 8s" >&2
  fi
  return "$size_rc"
}

ui_dump() {
  local attempt err noisy rc
  local saved=""
  local timed_out=0
  for attempt in 1 2 3 4 5; do
    # Drop the previous file so a failed dump cannot be reread as success.
    adb_shell_capped 8 rm -f /sdcard/uidump.xml >/dev/null 2>&1 || true
    err=""
    rc=0
    # uiautomator waits until the UI is idle. A spinner never idles, and
    # without this timeout one dump blocks the flow for the whole job.
    err="$(timeout 8 adb shell uiautomator dump /sdcard/uidump.xml 2>&1)" || rc=$?
    if [[ "$rc" -eq 124 ]]; then
      timed_out=$((timed_out + 1))
      if [[ "$timed_out" -le 1 ]]; then
        echo "ui_dump: uiautomator dump timed out after 8s; retrying once" >&2
        sleep 1
        continue
      fi
      echo "ui_dump: uiautomator dump timed out after 8s; UI did not go idle" >&2
      return 1
    fi
    noisy=0
    if printf '%s' "$err" | grep -Eq 'Bad file descriptor|ERROR:|could not get idle|null root node'; then
      noisy=1
    fi
    rm -f "$DUMP"
    if timeout 8 adb pull /sdcard/uidump.xml "$DUMP" >/dev/null 2>&1 && [[ -s "$DUMP" ]] && grep -q '<node ' "$DUMP"; then
      if [[ "$noisy" -eq 0 ]]; then
        rm -f "${DUMP}.partial"
        return 0
      fi
      cp -f "$DUMP" "${DUMP}.partial"
      saved=1
    fi
    sleep 1
  done
  if [[ "$saved" == 1 && -s "${DUMP}.partial" ]]; then
    cp -f "${DUMP}.partial" "$DUMP"
    rm -f "${DUMP}.partial"
    return 0
  fi
  rm -f "${DUMP}.partial"
  echo "ui_dump: no hierarchy after 5 attempts" >&2
  return 1
}

# ui_find forwards arguments to ui.py find. On success sets UI_CX UI_CY
# UI_X1 UI_Y1 UI_X2 UI_Y2 UI_TEXT from the node's bounds.
ui_find() {
  local line
  UI_CX=""
  UI_CY=""
  UI_X1=""
  UI_Y1=""
  UI_X2=""
  UI_Y2=""
  UI_TEXT=""
  line="$(python3 "$UI_PY" find "$DUMP" "$@")" || return 1
  # The last field is the visible text and may contain spaces.
  read -r UI_CX UI_CY UI_X1 UI_Y1 UI_X2 UI_Y2 UI_TEXT <<<"$line" || true
  [[ -n "$UI_CX" && -n "$UI_CY" ]]
}

# Per-case budget. STEP_DEADLINE is absolute SECONDS, 0 = none.
# Only the long option scan (select_labeled) shortens itself to it. Plain
# waits (ui_wait, ui_wait_scrolled, chip lookups) keep their own small
# timeouts: run 40698852836 made them return at once after the budget,
# so a bar that was on screen read as "filter bar not on screen" and 31
# probes failed as "case exceeded". Start the budget after the entry
# screen is reached; relaunch + directory load alone took ~55s there.
STEP_DEADLINE=0
CASE_MAX="${CASE_MAX:-90}"
case_start() { CASE_T0=$SECONDS; STEP_DEADLINE=$((SECONDS + CASE_MAX)); }
case_end() { STEP_DEADLINE=0; }
case_over() { (( SECONDS - ${CASE_T0:-$SECONDS} > CASE_MAX )); }
step_expired() { (( STEP_DEADLINE > 0 && SECONDS >= STEP_DEADLINE )); }

# Flow wall clock. run_one_flow.sh exports FLOW_START_EPOCH when the 1140s
# timeout starts, which is before install and before matrix_main. A string
# of slow failures can reach that kill before the results are written.
# flow_over is true when another full case would not finish before then.
# Without the wrapper clock, the start is now minus FLOW_START_MARGIN so a
# late caller does not see a fresh 1140s.
FLOW_BUDGET_S="${FLOW_BUDGET_S:-1140}"
FLOW_START_MARGIN="${FLOW_START_MARGIN:-120}"
flow_over() {
  local now start elapsed need
  now="$(date +%s)"
  if [[ -n "${FLOW_START_EPOCH:-}" ]]; then
    start=$FLOW_START_EPOCH
  else
    if [[ -z "${FLOW_FALLBACK_EPOCH:-}" ]]; then
      FLOW_FALLBACK_EPOCH=$(( now - FLOW_START_MARGIN ))
    fi
    start=$FLOW_FALLBACK_EPOCH
  fi
  elapsed=$(( now - start ))
  need=$(( ${CASE_MAX:-90} + 55 ))
  (( elapsed + need >= FLOW_BUDGET_S ))
}

# Mark a case and the probes probe_list would generate NOT RUN.
# Usage: skip_case_for_budget ID STEP [STEP...]
skip_case_for_budget() {
  local id="$1"; shift
  local steps=("$@") st p chip
  record_not_run "$id" "stopped before the ${FLOW_BUDGET_S}s flow budget"
  STATE_APPLIED=0
  for st in "${steps[@]}"; do
    [[ "$st" == state:select ]] && STATE_APPLIED=1
  done
  chip="${steps[-1]%%:*}"
  while IFS= read -r p; do
    [[ -n "$p" ]] || continue
    record_not_run "$id-then-$p" "stopped before the ${FLOW_BUDGET_S}s flow budget"
  done < <(probe_list "$chip")
}

run_case_or_stop() {
  if flow_over; then
    skip_case_for_budget "$@"
  else
    run_case "$@"
  fi
}

ui_wait() {
  local timeout="$1"
  shift
  local start="$SECONDS"
  while (( SECONDS - start < timeout )); do
    if ui_dump && ui_find "$@"; then
      return 0
    fi
    sleep 1
  done
  echo "ui_wait: timed out after ${timeout}s" >&2
  return 1
}

ui_tap() {
  adb_shell_capped 8 input tap "$UI_CX" "$UI_CY"
}

ui_back() {
  adb_shell_capped 8 input keyevent 4
}

# Package owning the focused window, or empty. mCurrentFocus first, then
# the resumed activity from dumpsys activity.
foreground_pkg() {
  local out pkg
  out="$(adb_shell_capped 6 dumpsys window 2>/dev/null | tr -d '\r' | grep -m1 'mCurrentFocus=' || true)"
  pkg="$(sed -n 's/.* \([A-Za-z0-9_.]*\)\/.*/\1/p' <<<"$out")"
  if [[ -z "$pkg" ]]; then
    out="$(adb_shell_capped 6 dumpsys activity activities 2>/dev/null | tr -d '\r' \
      | grep -m1 -E 'mResumedActivity|topResumedActivity|ResumedActivity:' || true)"
    pkg="$(sed -n 's/.* \([A-Za-z0-9_.]*\)\/.*/\1/p' <<<"$out")"
  fi
  printf '%s' "$pkg"
}

# Package/class line from `cmd package resolve-activity --brief`, or empty.
# A priority line is ignored when --brief is not honored.
_resolve_activity_pkg() {
  local line
  line="$(adb_shell_capped 6 "$@" 2>/dev/null | tr -d '\r' | grep -m1 '/' || true)"
  printf '%s' "${line%%/*}"
}

# Package that owns the default activity for an https VIEW, or empty.
https_view_handler() {
  _resolve_activity_pkg cmd package resolve-activity --brief \
    -a android.intent.action.VIEW -d https://example.com
}

# Package that owns the HOME activity (the launcher), or empty.
home_handler() {
  _resolve_activity_pkg cmd package resolve-activity --brief \
    -a android.intent.action.MAIN -c android.intent.category.HOME
}

# Classify a foreground package for the Maps-disabled Directions fallback.
# Prints browser, launcher, permission, or other.
# A browser is an allowlisted package (Chrome, Samsung Internet,
# org.mozilla.*, Edge, Brave) or the resolved https VIEW handler.
# The app under test is never a browser. A chooser (package "android" or
# com.android.intentresolver) is other, even when it resolved the VIEW.
# The launcher is the HOME handler, not a name containing "launcher".
# Either permission controller fails even when it is the handler.
# Usage: classify_fallback_pkg PKG [HTTPS_HANDLER] [HOME_HANDLER]
classify_fallback_pkg() {
  local pkg="$1" handler="${2:-}" home="${3:-}"
  case "$pkg" in
    com.google.android.permissioncontroller|com.android.permissioncontroller)
      echo permission
      return 0 ;;
    android|com.android.intentresolver)
      echo other
      return 0 ;;
  esac
  if [[ -n "$home" && -n "$pkg" && "$pkg" == "$home" ]]; then
    echo launcher
    return 0
  fi
  case "$pkg" in
    com.android.chrome|com.sec.android.app.sbrowser|com.microsoft.emmx|com.brave.browser|org.mozilla.*)
      echo browser
      return 0 ;;
  esac
  # A chooser that resolved the VIEW is not a browser.
  case "$handler" in
    android|com.android.intentresolver) handler="" ;;
  esac
  if [[ -n "$pkg" && -n "$handler" && "$pkg" == "$handler" && "$pkg" != "$PKG" ]]; then
    echo browser
    return 0
  fi
  echo other
}

# In-app no-maps result. The Get Directions button stays on screen when the
# tap did nothing, so that label is not a pass. Pass only when this package
# is the app and the "Couldn't open directions" message is showing (1/0).
# Prints pass or fail.
# Usage: no_maps_in_app_result FOREGROUND MESSAGE_VISIBLE
no_maps_in_app_result() {
  local fg="$1" message_visible="$2"
  if [[ "$fg" == "$PKG" && "$message_visible" == 1 ]]; then
    echo pass
  else
    echo fail
  fi
}

# Press BACK until $PKG owns the focused window. Bounded by press count and a
# total wall-clock cap, since Maps first-run pages (terms_killswitch_page,
# GrantPermissionsActivity) can absorb any fixed number of backs.
# Usage: back_until_app [max_presses=6] [total_cap_s=30]
back_until_app() {
  local max="${1:-6}" cap="${2:-30}" t0=$SECONDS n=0 fg
  BACK_PRESSES=0
  fg="$(foreground_pkg)"
  while [[ "$fg" != "$PKG" ]]; do
    if (( n >= max )); then
      echo "back_until_app: ${PKG} not in front after ${n} backs (front: ${fg:-unknown})" >&2
      return 1
    fi
    if (( SECONDS - t0 >= cap )); then
      echo "back_until_app: ${cap}s cap hit after ${n} backs (front: ${fg:-unknown})" >&2
      return 1
    fi
    ui_back || echo "back_until_app: back press ${n} timed out" >&2
    n=$((n + 1))
    BACK_PRESSES=$n
    sleep 1
    fg="$(foreground_pkg)"
    echo "back_until_app: press ${n} front=${fg:-unknown}" >&2
  done
  return 0
}

# Device-side logcat timestamp to pass to maps_start_count.
# adb shell joins its arguments with spaces and the device shell splits
# them again, so the format must reach the device as one quoted word.
# Unquoted, toybox date got "%H:%M:%S.000" as a date to set, printed
# nothing, and maps_start_count saw no mark (run 40698852836: count=0
# with a Maps START in logcat).
logcat_mark() {
  adb_shell_capped 6 "date '+%m-%d %H:%M:%S.000'" 2>/dev/null | tr -d '\r' || true
}

# Count ActivityTaskManager START lines for Google Maps since a logcat_mark.
maps_start_count() {
  local since="$1" n
  if [[ -z "$since" ]]; then
    echo 0
    return 1
  fi
  n="$(timeout 10 adb logcat -d -T "$since" -s ActivityTaskManager:I 2>/dev/null | tr -d '\r' \
    | grep -E 'START .*com\.google\.android\.apps\.maps' -c || true)"
  echo "${n:-0}"
}

ui_home_key() {
  adb_shell_capped 8 input keyevent 3
}

ui_fling() {
  local direction="$1"
  local width height
  read -r width height < <(ui_screen_size)
  if [[ -z "${width:-}" || -z "${height:-}" ]]; then
    return 1
  fi
  local x=$((width / 2))
  # Horizontal flings run at a third of the height (inside the detail
  # gallery) and stay 20% away from both edges so the system back gesture
  # cannot fire. "left" moves content to the next page.
  local y=$((height / 3))
  case "$direction" in
    up)
      adb_shell_capped 8 input swipe "$x" $((height * 3 / 4)) "$x" $((height / 3)) 280 ;;
    down)
      adb_shell_capped 8 input swipe "$x" $((height / 3)) "$x" $((height * 3 / 4)) 280 ;;
    left)
      adb_shell_capped 8 input swipe $((width * 4 / 5)) "$y" $((width / 5)) "$y" 200 ;;
    right)
      adb_shell_capped 8 input swipe $((width / 5)) "$y" $((width * 4 / 5)) "$y" 200 ;;
    *)
      echo "ui_fling: unknown direction '${direction}'" >&2
      return 2 ;;
  esac
}

# Dump and search, flinging up between tries. Coordinates stay derived from wm size.
ui_wait_scrolled() {
  local timeout="$1"
  shift
  local start="$SECONDS"
  local flings=0
  while (( SECONDS - start < timeout )); do
    if ui_dump && ui_find "$@"; then
      return 0
    fi
    if (( flings < 8 )); then
      ui_fling up || true
      flings=$((flings + 1))
    fi
    sleep 1
  done
  echo "ui_wait_scrolled: timed out after ${timeout}s" >&2
  return 1
}

ui_type() {
  local text="$1"
  local encoded
  encoded="$(python3 -c 'import sys; print(sys.argv[1].replace(" ", "%s"))' "$text")"
  adb_shell_capped 8 input text "$encoded"
}

# Visible field text with the search hint and clear tooltip removed.
ui_field_value() {
  python3 -c '
import sys
text = " ".join(sys.argv[1].split())
for extra in ("Name, city, state, deity, or address", "Clear search"):
    text = text.replace(extra, " ")
print(" ".join(text.split()))
' "$1"
}

# Delete only the characters currently in the field. Extra deletes on an
# empty Flutter field were leaving junk ("Krishna" became "Krishnayyyyy").
ui_clear_field() {
  local value="$1"
  local n=${#value}
  local i
  if [[ "$n" -eq 0 ]]; then
    return 0
  fi
  adb_shell_capped 8 input keyevent 123 >/dev/null 2>&1 || true
  for ((i = 0; i < n; i++)); do
    adb_shell_capped 8 input keyevent 67 >/dev/null 2>&1 || true
  done
}

# Clear the field, type, and require a dump of the field to equal the query.
# Retries once. On failure UI_FIELD_ACTUAL is the text that was read.
ui_replace_field_text() {
  local query="$1"
  local rid="${2:-temple-list-search-field}"
  local attempt value
  UI_FIELD_ACTUAL=""
  for attempt in 1 2; do
    value=""
    if ! ui_dump; then
      UI_FIELD_ACTUAL="unreadable"
      sleep 1
      continue
    fi
    if ui_find --resource-id "$rid"; then
      ui_tap
      sleep 0.4
      value="$(ui_field_value "$UI_TEXT")"
    elif ui_find --text-contains "Name, city, state"; then
      ui_tap
      sleep 0.4
      value="$(ui_field_value "$UI_TEXT")"
    else
      UI_FIELD_ACTUAL="field not found"
      sleep 0.5
      continue
    fi
    ui_clear_field "$value"
    ui_type "$query"
    sleep 0.8
    if ui_dump && ui_find --resource-id "$rid"; then
      UI_FIELD_ACTUAL="$(ui_field_value "$UI_TEXT")"
      if [[ "$UI_FIELD_ACTUAL" == "$query" ]]; then
        return 0
      fi
    else
      UI_FIELD_ACTUAL="${UI_FIELD_ACTUAL:-unreadable}"
    fi
  done
  echo "ui_replace_field_text: '${query}' was not in the field after 2 tries (got '${UI_FIELD_ACTUAL}')" >&2
  return 1
}

# Step inside the sheet list. A short slow drag, not a fling: the old 28%
# step in 180ms jumped past Kerala, Shiva, and Madurai between dumps.
# start_pct is where the finger goes down, as a percent of screen height.
ui_sheet_swipe() {
  local direction="${1:-up}"
  local start_pct="${2:-58}"
  local width height travel start_y end_y
  read -r width height < <(ui_screen_size) || return 1
  local x=$((width / 2))
  # A 72px step never reached Shiva, Madurai, or Vishnu before the
  # 120s cap. A quarter of the sheet crosses several rows per dump and
  # still stops inside the tap band on the next look.
  travel=$((height * 24 / 100))
  if (( travel < 160 )); then
    travel=160
  fi
  if (( travel > 320 )); then
    travel=320
  fi
  start_y=$((height * start_pct / 100))
  if [[ "$direction" == "down" ]]; then
    end_y=$((start_y + travel))
  else
    end_y=$((start_y - travel))
  fi
  if (( end_y < height * 30 / 100 )); then
    end_y=$((height * 30 / 100))
  fi
  if (( end_y > height * 88 / 100 )); then
    end_y=$((height * 88 / 100))
  fi
  if (( start_y < height * 30 / 100 )); then
    start_y=$((height * 30 / 100))
  fi
  if (( start_y > height * 88 / 100 )); then
    start_y=$((height * 88 / 100))
  fi
  adb_shell_capped 8 input swipe "$x" "$start_y" "$x" "$end_y" 900
}

# The drawer is narrower than the screen. A center fling misses its list.
scroll_drawer_until() {
  local i width height x
  read -r width height < <(ui_screen_size) || return 1
  x=$((width * 28 / 100))
  if (( x < 48 )); then
    x=48
  fi
  for i in $(seq 1 8); do
    if ui_dump && ui_find "$@"; then
      if (( UI_CY > 48 && UI_CY < height - 48 )); then
        return 0
      fi
    fi
    adb_shell_capped 8 input swipe "$x" $((height * 72 / 100)) "$x" $((height * 40 / 100)) 320 || {
      echo "scroll_drawer_until: swipe timed out" >&2
      return 1
    }
    sleep 0.35
  done
  echo "scroll_drawer_until: gave up after 8 swipes" >&2
  return 1
}

# Pull the drawer list back to its top. A failed All Temples search flings
# this list until Home is off screen; the next Home tap then times out.
scroll_drawer_top() {
  local i width height x
  read -r width height < <(ui_screen_size) || return 1
  x=$((width * 28 / 100))
  if (( x < 48 )); then
    x=48
  fi
  for i in 1 2 3 4 5 6; do
    adb_shell_capped 8 input swipe \
      "$x" $((height * 28 / 100)) \
      "$x" $((height * 78 / 100)) 200 || {
      echo "scroll_drawer_top: swipe timed out" >&2
      return 1
    }
    sleep 0.15
  done
}

launch_app() {
  adb shell am start -n "${PKG}/.MainActivity" >/dev/null 2>&1 || \
    adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true
  sleep 2
}

force_stop_app() {
  adb shell am force-stop "$PKG" || true
  sleep 1
}

resume_app() {
  launch_app
}

# The cached AVD can already contain this package signed by another runner.
# adb install -r then fails with INSTALL_FAILED_UPDATE_INCOMPATIBLE.
uninstall_app() {
  if [[ -z "${PKG:-}" ]]; then
    return 0
  fi
  adb uninstall "$PKG" >/dev/null 2>&1 || true
}

install_once() {
  adb install -r -d "$EMULATOR_APK" 2>&1
}

# Printed once per flow, after the APK is on the emulator. Lessons row 4
# asks for the installed versionCode, not the pubspec text.
log_installed_version() {
  local dump code name
  if [[ -z "${PKG:-}" ]]; then
    echo "installed versionCode=unknown (package unset)"
    printf 'VERSION %s versionCode=unknown versionName=unknown\n' "$FLOW" >> "$RESULTS"
    return 0
  fi
  dump="$(adb shell dumpsys package "$PKG" 2>/dev/null | tr -d '\r' || true)"
  code="$(printf '%s\n' "$dump" | sed -n 's/.*versionCode=\([0-9][0-9]*\).*/\1/p' | head -1)"
  name="$(printf '%s\n' "$dump" | sed -n 's/.*versionName=\([^ ]*\).*/\1/p' | head -1)"
  echo "installed ${PKG} versionName=${name:-unknown} versionCode=${code:-unknown}"
  printf 'VERSION %s versionCode=%s versionName=%s\n' "$FLOW" "${code:-unknown}" "${name:-unknown}" >> "$RESULTS"
}

install_apk() {
  if [[ -z "${EMULATOR_APK:-}" || ! -f "$EMULATOR_APK" ]]; then
    record_fail "install" "APK missing (${EMULATOR_APK:-unset})"
    return 1
  fi
  local log
  uninstall_app
  if ! log="$(install_once)"; then
    if [[ "$log" == *"INSTALL_FAILED_UPDATE_INCOMPATIBLE"* ]]; then
      uninstall_app
      if ! log="$(install_once)"; then
        record_fail "install" "adb install failed after uninstall retry: $(printf '%s' "$log" | tr '\n' ' ')"
        return 1
      fi
    else
      record_fail "install" "adb install failed: $(printf '%s' "$log" | tr '\n' ' ')"
      return 1
    fi
  fi
  if [[ "$log" != *"Success"* ]]; then
    record_fail "install" "adb install did not report Success: $(printf '%s' "$log" | tr '\n' ' ')"
    return 1
  fi
  return 0
}

resolve_package() {
  if [[ -n "$PKG" ]]; then
    return 0
  fi
  local sdk aapt line
  sdk="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-/usr/local/lib/android/sdk}}"
  aapt="$(find "$sdk/build-tools" -name aapt -type f 2>/dev/null | sort | tail -1 || true)"
  if [[ -z "$aapt" ]]; then
    aapt="$(command -v aapt || true)"
  fi
  if [[ -n "$aapt" ]]; then
    line="$("$aapt" dump badging "$EMULATOR_APK" 2>/dev/null | sed -n "s/^package: name='\([^']*\)'.*/\1/p" | head -1)"
  fi
  if [[ -z "${line:-}" ]]; then
    local analyzer
    analyzer="$(find "$sdk/cmdline-tools" "$sdk/tools" -name apkanalyzer -type f 2>/dev/null | sort | tail -1 || true)"
    if [[ -n "$analyzer" ]]; then
      line="$("$analyzer" manifest application-id "$EMULATOR_APK" 2>/dev/null | tr -d '\r' | head -1 || true)"
    fi
  fi
  if [[ -z "${line:-}" ]]; then
    record_fail "package-name" "aapt and apkanalyzer could not read a package name"
    return 1
  fi
  PKG="$line"
  export EMULATOR_PACKAGE="$PKG"
  printf '%s\n' "$PKG" > "${ARTIFACTS}/package_name.txt"
  echo "Package ${PKG}"
  return 0
}

clean_install() {
  adb uninstall "$PKG" >/dev/null 2>&1 || true
  install_apk
}

sheet_open() {
  ui_dump || return 1
  # Prefer the title so a dismiss swipe starts on the sheet, not the close icon.
  if ui_find --text-regex '^Filters$' || ui_find --content-desc-regex '^Filters$'; then
    return 0
  fi
  ui_find --content-desc "Close filters" && return 0
  ui_find --text-regex '^Show [0-9]+ temples?$'
}

# Close a sheet that would block the next step. Does not press back on Home.
dismiss_blockers() {
  ui_dump || return 0
  if ui_find --text-contains "Sort by distance"; then
    if ui_find --text-regex '^Not now$'; then
      ui_tap
      sleep 1
      return 0
    fi
    if ui_find --text-regex '^Continue$'; then
      ui_tap
      sleep 1
      return 0
    fi
  fi
  if ui_find --content-desc "Close filters"; then
    ui_tap
    sleep 1
    return 0
  fi
  if ui_find --text-regex '^Filters$' || ui_find --content-desc-regex '^Filters$' || ui_find --text-regex '^Show [0-9]+ temples?$'; then
    ui_back
    sleep 1
    return 0
  fi
  if ui_find --content-desc "Scrim"; then
    ui_back
    sleep 1
  fi
}

dismiss_location_consent() {
  local preference="${1:-Not now}"
  ui_dump || return 1
  ui_find --text-contains "Sort by distance" || return 1
  case "$preference" in
    Continue)
      if ui_find --text-regex '^Continue$'; then
        ui_tap
        sleep 1
        return 0
      fi
      ;;
    *)
      if ui_find --text-regex '^Not now$'; then
        ui_tap
        sleep 1
        return 0
      fi
      ;;
  esac
  return 1
}

push_emulator_geo() {
  local _i
  adb shell settings put secure location_mode 3 >/dev/null 2>&1 || true
  # adb emu geo fix is longitude, latitude, altitude, satellites (Madurai).
  # A fix with no satellites is dropped on the API 30 image, and Temples
  # near me stays on "Finding temples". The first fix after boot is often
  # ignored, so send it more than once.
  for _i in 1 2 3; do
    adb emu geo fix 78.1193 9.9195 0 8 >/dev/null 2>&1 || true
  done
}

# Drag from the sheet handle or title. A swipe that starts in the list scrolls
# the options instead of dismissing the sheet.
dismiss_sheet_from_handle() {
  local width="$1"
  local height="$2"
  local start_x=$((width / 2))
  local start_y=$((height * 24 / 100))
  local max_title=$((height * 36 / 100))
  if ui_find --text-regex '^Filters$' --max-top "$max_title" || ui_find --content-desc-regex '^Filters$' --max-top "$max_title"; then
    local node_h=$((UI_Y2 - UI_Y1))
    if (( node_h > 0 && node_h < height / 6 && UI_CY < max_title )); then
      start_x=$UI_CX
      start_y=$UI_CY
    fi
  fi
  if (( start_y > max_title )); then
    start_x=$((width / 2))
    start_y=$((height * 24 / 100))
  fi
  adb_shell_capped 8 input swipe "$start_x" "$start_y" "$start_x" $((height * 96 / 100)) 300
}

dismiss_sheet_swipe() {
  local width height
  # The sheet title can land a moment after the chip tap. Flows 06 and 17
  # otherwise report "sheet was not open" while Filters is still animating in.
  if ! sheet_open; then
    ui_wait 3 --text-regex '^Filters$' || true
  fi
  if ! sheet_open; then
    echo "sheet was not open"
    return 1
  fi
  read -r width height < <(ui_screen_size)
  local attempt _
  for attempt in 1 2; do
    dismiss_sheet_from_handle "$width" "$height" || true
    # Poll for closure instead of one fixed sleep.
    for _ in 1 2 3; do
      sleep 0.7
      sheet_open || return 0
    done
  done
  echo "sheet still open after swipe down from the handle"
  return 1
}

dismiss_sheet_outside() {
  local target_y
  if ! sheet_open; then
    ui_wait 3 --text-regex '^Filters$' || true
  fi
  if ! sheet_open; then
    echo "sheet was not open"
    return 1
  fi
  # Scrim is above the sheet title. Use a fraction of that title's top.
  target_y=$((UI_Y1 / 4))
  if (( target_y < 12 )); then
    target_y=12
  fi
  adb_shell_capped 8 input tap "$UI_CX" "$target_y" || {
    echo "dismiss_sheet_outside: tap timed out" >&2
    return 1
  }
  sleep 1
  if sheet_open; then
    echo "sheet still open after tapping above it at y=${target_y}"
    return 1
  fi
  return 0
}

chip_label() {
  # Strip a trailing count from an option chip ("Kerala  12" -> "Kerala").
  python3 -c 'import re,sys; print(re.sub(r"\s+\d+\s*$","",sys.argv[1]).strip())' "$1"
}

accept_policy_if_shown() {
  local start="$SECONDS"
  while (( SECONDS - start < 25 )); do
    ui_dump || true
    if ui_find --text-contains "Accept & continue"; then
      ui_tap
      sleep 2
      return 0
    fi
    if ui_find --text-contains "Temple Directory"; then
      return 0
    fi
    if ui_find --text-contains "Update required"; then
      return 0
    fi
    sleep 1
  done
  echo "accept_policy_if_shown: timed out after 25s" >&2
  return 1
}

wait_for_home() {
  ui_wait_scrolled 90 --text-contains "Temple Directory"
}

open_browse() {
  local start="$SECONDS"
  # OPEN_BROWSE_HOME_WAIT lets the self-test skip the home-button loop.
  local limit="${OPEN_BROWSE_HOME_WAIT:-40}"
  while (( SECONDS - start < limit )); do
    if ui_dump && ui_find --resource-id home-browse-temples; then
      ui_tap
      return 0
    fi
    if ui_dump && ui_find --text-regex '^Browse .*Temples?$'; then
      ui_tap
      return 0
    fi
    ui_fling up || true
    sleep 1
  done
  # Fall back to the drawer entry. The All Temples tile's content-desc is
  # "All Temples\n<count>", which flattens to "All Temples 992". A trailing
  # $ never matches that node. Home and Licences have no trailing count, so
  # their $ anchors stay. Option chips are one text ("Shiva  12"); pickers
  # allow that suffix. Trigger chips (State, All districts, Deity) and
  # "Show N temples" / "Browse N Temples" are a single line, so their $ stays.
  # A miss used to fling until Home left the tree. The next '^Home$' wait
  # then timed out and the && skipped both taps (flow 18's double-tap).
  if ui_dump && ui_find --content-desc "Open navigation menu"; then
    ui_tap
    sleep 1
    if scroll_drawer_until --text-regex '^All Temples'; then
      ui_tap
      return 0
    fi
    scroll_drawer_top || true
    if ui_dump && ui_find --text-regex '^All Temples'; then
      ui_tap
      return 0
    fi
    # Close at the top. The drawer's scroll offset survives a close, and a
    # later menu tap must open onto Home rather than close a scrolled drawer.
    ui_back || true
  fi
  echo "open_browse: timed out after ${limit}s" >&2
  return 1
}

# A cold boot can miss Firestore once (run 40698852836 flow 09: "failed to
# connect to firestore.googleapis.com/2607:..." then "Could not load
# temples"). The list offers "Try again" (e30d95d). Tap it once and give
# that load its 12s fetch timeout plus margin before calling it failed;
# the retry shows no spinner, so the old message stays up meanwhile.
# Flow 27 recover used to fail here 9s after its own retry tap.
BROWSE_RETRY_GRACE="${BROWSE_RETRY_GRACE:-25}"
wait_browse_ready() {
  local start="$SECONDS" retried_at=0
  while (( SECONDS - start < 120 )); do
    ui_dump || true
    if ui_find --text-contains "Could not load temples"; then
      if (( retried_at == 0 )) && ui_find --resource-id browse-load-failed-retry; then
        echo "wait_browse_ready: load failed; tapping Try again once" >&2
        if ui_tap; then
          retried_at=$SECONDS
        else
          echo "wait_browse_ready: Try again tap failed" >&2
        fi
        sleep 2
        continue
      fi
      if (( retried_at == 0 || SECONDS - retried_at >= BROWSE_RETRY_GRACE )); then
        echo "directory failed to load"
        return 1
      fi
      sleep 2
      continue
    fi
    if ui_find --resource-id filter-chip-state || ui_find --text-regex '^State$'; then
      if ! ui_find --text-contains "Loading temples"; then
        return 0
      fi
    fi
    sleep 2
  done
  echo "browse list did not finish loading"
  return 1
}

reach_browse() {
  launch_app
  if ! accept_policy_if_shown; then
    echo "policy gate or home did not appear"
    return 1
  fi
  if ui_dump && ui_find --text-contains "Update required"; then
    echo "force-update screen is blocking the directory"
    return 1
  fi
  if ! wait_for_home; then
    echo "home did not appear"
    return 1
  fi
  if ! open_browse; then
    echo "could not open the temple list"
    return 1
  fi
  wait_browse_ready
}

seed_prefs_file() {
  local file="$1"
  local step="$2"
  local err prefs
  # Package names are dotted identifiers. Reject anything else before it
  # is interpolated into a device shell command.
  if [[ -z "${PKG:-}" || ! "$PKG" =~ ^[A-Za-z0-9._]+$ ]]; then
    record_fail "$step" "package name is not set, so shared_prefs cannot be seeded"
    return 1
  fi
  prefs="/data/data/${PKG}/shared_prefs"
  # mkdir must receive the directory as its own argument. Wrapping it in
  # sh -c lets the device shell keep only the word mkdir, which then
  # prints "Needs 1 argument".
  if ! adb shell run-as "$PKG" mkdir -p "$prefs" >/tmp/runas.err 2>&1; then
    launch_app
    force_stop_app
    if ! adb shell run-as "$PKG" mkdir -p "$prefs" >/tmp/runas.err 2>&1; then
      err="$(tr '\n' ' ' < /tmp/runas.err 2>/dev/null || true)"
      record_fail "$step" "run-as failed (${err:-mkdir}); APK is not debuggable, so shared_prefs cannot be seeded"
      return 1
    fi
  fi
  if ! adb shell "run-as ${PKG} sh -c 'cat > ${prefs}/FlutterSharedPreferences.xml'" < "$file" 2>/tmp/runas.err; then
    err="$(tr '\n' ' ' < /tmp/runas.err 2>/dev/null || true)"
    record_fail "$step" "could not write FlutterSharedPreferences.xml (${err})"
    return 1
  fi
  return 0
}

write_policy_prefs() {
  local version="$1"
  local step="$2"
  local extra="${3:-}"
  local file
  file="$(mktemp)"
  cat > "$file" <<EOF
<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<map>
    <int name="flutter.tos_accepted_version" value="${version}" />
    <string name="flutter.tos_accepted_at">2026-10-01T00:00:00.000Z</string>
    ${extra}
</map>
EOF
  seed_prefs_file "$file" "$step"
  local rc=$?
  rm -f "$file"
  return "$rc"
}

network_off() {
  # svc wifi/data is the checklist. The emulator's route is often ethernet,
  # so that interface is taken down as well or the guest stays online.
  adb shell svc wifi disable >/dev/null 2>&1 || true
  adb shell svc data disable >/dev/null 2>&1 || true
  adb shell svc ethernet disable >/dev/null 2>&1 || true
  adb shell ip link set eth0 down >/dev/null 2>&1 || true
  adb shell ip link set wlan0 down >/dev/null 2>&1 || true
}

network_on() {
  adb shell ip link set eth0 up >/dev/null 2>&1 || true
  adb shell ip link set wlan0 up >/dev/null 2>&1 || true
  adb shell svc ethernet enable >/dev/null 2>&1 || true
  adb shell svc wifi enable >/dev/null 2>&1 || true
  adb shell svc data enable >/dev/null 2>&1 || true
}

screenrecord_start() {
  local stop="${ARTIFACTS}/recordings/${FLOW}.stop"
  local pidfile="${ARTIFACTS}/recordings/${FLOW}.pid"
  rm -f "$stop"
  (
    n=0
    while [[ ! -f "$stop" && "$n" -lt 8 ]]; do
      seg="$(printf 'seg%02d.mp4' "$n")"
      if ! timeout 190 adb shell screenrecord --bit-rate 2000000 --time-limit 180 "/sdcard/${FLOW}_${seg}"; then
        echo "screenrecord: segment ${n} failed or hit the 190s cap" >&2
        sleep 1
      fi
      n=$((n + 1))
    done
    if [[ ! -f "$stop" ]]; then
      echo "screenrecord: stopped after 8 segments" >&2
    fi
  ) &
  echo $! > "$pidfile"
}

screenrecord_stop() {
  local stop="${ARTIFACTS}/recordings/${FLOW}.stop"
  local pidfile="${ARTIFACTS}/recordings/${FLOW}.pid"
  local pulled="${ARTIFACTS}/recordings/${FLOW}.pulled"
  [[ -f "$pulled" ]] && return 0
  touch "$stop"
  adb shell 'pid=$(pidof screenrecord); if [ -n "$pid" ]; then kill -2 $pid; fi' >/dev/null 2>&1 || true
  if [[ -f "$pidfile" ]]; then
    wait "$(cat "$pidfile")" 2>/dev/null || true
  fi
  mkdir -p "$REC_DIR"
  local remote
  while read -r remote; do
    remote="${remote//$'\r'/}"
    [[ -z "$remote" || "$remote" == *"No such file"* ]] && continue
    adb pull "$remote" "${REC_DIR}/$(basename "$remote")" >/dev/null 2>&1 || true
  done < <(adb shell "ls /sdcard/${FLOW}_seg*.mp4" 2>/dev/null || true)
  : > "$pulled"
}

dump_logcat() {
  mkdir -p "$LOG_DIR"
  adb logcat -d > "${LOG_DIR}/${FLOW}.txt" 2>/dev/null || true
}

app_pid() {
  adb shell pidof "$PKG" 2>/dev/null | tr -d '\r' || true
}

# Filter-sheet helpers shared by flow 06 and flows 17 and 19.
# scroll_chip_bar_at, find_filter_chip, and re_escape support the ones
# the flow scripts call directly.

scroll_chip_bar_at() {
  local y="$1"
  local direction="$2"
  local width left right cy sig
  read -r width _ < <(ui_screen_size) || return 1
  left=$((width * 25 / 100))
  right=$((width * 80 / 100))
  # Swipe inside the scroller only. filter-clear is pinned at its right
  # end (#123) and the drawer is narrower than the screen. A swipe that
  # starts on either never scrolls the row, and in the drawer it closes
  # the drawer (run 40463875634).
  if [[ -s "$DUMP" ]] && read -r left right cy sig < <(python3 "$UI_PY" chip-bar "$DUMP"); then
    y="$cy"
  fi
  if [[ "$direction" == "right" ]]; then
    adb_shell_capped 8 input swipe "$left" "$y" "$right" "$y" 250
  else
    adb_shell_capped 8 input swipe "$right" "$y" "$left" "$y" 250
  fi
}

# Visible chip ids and positions, or empty when no chip row is on screen.
chip_bar_sig() {
  local _l _r _y sig=""
  read -r _l _r _y sig < <(python3 "$UI_PY" chip-bar "$DUMP") || true
  printf '%s\n' "$sig"
}

# Width and height of the last dump's root node (rotation-aware).
dump_screen_size() {
  [[ -s "$DUMP" ]] || return 1
  python3 - "$DUMP" <<'PY'
import re, sys
m = re.search(r'bounds="\[0,0\]\[(\d+),(\d+)\]"', open(sys.argv[1], encoding="utf-8", errors="replace").read())
if not m:
    sys.exit(1)
print(m.group(1), m.group(2))
PY
}

# The selected chip's text is the value ("Shiva"), and it may sit past the
# right edge. Match the idle label or the applied value, and scroll the bar.
find_filter_chip() {
  local rid="$1"
  local regex="$2"
  local desc="${3:-}"
  local i width height max_top y found
  read -r width height < <(ui_screen_size) || return 1
  # Landscape puts the chip row below 38% of the height, so a portrait band
  # misses Kerala after rotation and the shot still shows the old chip.
  max_top=$((height * 70 / 100))
  y=$((height * 22 / 100))
  for i in $(seq 1 8); do
    ui_dump || true
    # wm size stays portrait after rotation; the dump root is the real
    # screen. Run 40698852836 flow 19: in landscape (640x320) the title
    # "Kerala" at x=320 read as past a 320px-wide screen's edge.
    read -r width height < <(dump_screen_size) || read -r width height < <(ui_screen_size) || return 1
    max_top=$((height * 70 / 100))
    found=0
    if [[ -n "$rid" ]] && ui_find --resource-id "$rid" --max-top "$max_top"; then
      found=1
    elif [[ -n "$regex" ]] && ui_find --resource-id-regex '^filter-chip-' --text-regex "$regex" --max-top "$max_top"; then
      # The chip itself, not the app-bar title that repeats the filter.
      found=1
    elif [[ -n "$regex" ]] && ui_find --text-regex "$regex" --max-top "$max_top" --prefer upper; then
      found=1
    elif [[ -n "$desc" ]] && ui_find --content-desc "$desc" --max-top "$max_top"; then
      found=1
    fi
    if [[ "$found" -eq 1 ]]; then
      y=$UI_CY
      if (( UI_CX > 24 && UI_CX < width - 24 )); then
        return 0
      fi
      if (( UI_CX >= width - 24 )); then
        scroll_chip_bar_at "$y" left || true
      else
        scroll_chip_bar_at "$y" right || true
      fi
      sleep 0.4
      continue
    fi
    if ui_find --resource-id filter-chip-state --max-top "$max_top"; then
      y=$UI_CY
    fi
    if (( i <= 4 )); then
      scroll_chip_bar_at "$y" left || true
    else
      scroll_chip_bar_at "$y" right || true
    fi
    sleep 0.4
  done
  echo "find_filter_chip: not in view after 8 scrolls" >&2
  return 1
}

scroll_chips_until() {
  local i width height max_top before after
  read -r width height < <(ui_screen_size) || return 1
  max_top=$((height * 70 / 100))
  for i in 1 2 3 4; do
    ui_dump || return 1
    if ui_find "$@" --max-top "$max_top" && (( UI_CX > 24 && UI_CX < width - 24 )); then
      return 0
    fi
    before="$(chip_bar_sig)"
    if [[ -z "$before" ]]; then
      echo "scroll_chips_until: no chip bar on screen" >&2
      return 1
    fi
    scroll_chip_bar_at 0 left || return 1
    sleep 0.4
    ui_dump || return 1
    after="$(chip_bar_sig)"
    # Assert the swipe did something: the row must still be there, and
    # it must have moved. An unmoved row is at its end; stop now instead
    # of paying for more swipes.
    if [[ -z "$after" ]]; then
      echo "scroll_chips_until: chip bar vanished after the swipe" >&2
      return 1
    fi
    if ui_find "$@" --max-top "$max_top" && (( UI_CX > 24 && UI_CX < width - 24 )); then
      return 0
    fi
    if [[ "$after" == "$before" ]]; then
      echo "scroll_chips_until: chip bar did not move; target not in it" >&2
      return 1
    fi
  done
  echo "scroll_chips_until: not in view after 4 scrolls" >&2
  return 1
}

re_escape() {
  python3 -c 'import re,sys; print(re.escape(sys.argv[1]))' "$1"
}

# Option-list fingerprint. A raw dump checksum changes when a spinner or
# the status-bar clock changes, which never looks like the end of the list.
# The visible texts stay put when a swipe was a no-op.
dump_scroll_sig() {
  python3 - "$DUMP" <<'PY'
import hashlib, re, sys
raw = open(sys.argv[1], encoding="utf-8", errors="replace").read()
# Flutter puts option labels in content-desc, not text. Hashing text alone
# gave the same signature after every swipe (run 40463875634), so the
# picker decided the list had ended at the C districts.
texts = re.findall(r'\b(?:text|content-desc)="([^"]*)"', raw)
keep = [
    t for t in texts
    if t and "Loading" not in t and not re.fullmatch(r"\d{1,2}:\d{2}", t)
]
print(hashlib.sha256("\n".join(keep).encode()).hexdigest()[:16])
PY
}

# The district sheet opens on a spinner. Scrolling while that spinner is up
# makes every dump look new, so the picker never decides the list has ended.
wait_out_district_loader() {
  local start="$SECONDS"
  if ! ui_dump; then
    echo "select_labeled: hierarchy dump failed before looking for a label" >&2
    return 1
  fi
  if ! ui_find --resource-id filter-district-loading \
    && ! ui_find --text-contains "Loading districts"; then
    return 0
  fi
  while (( SECONDS - start < 15 )); do
    sleep 1
    if ! ui_dump; then
      echo "select_labeled: hierarchy dump failed while districts were loading" >&2
      return 1
    fi
    if ! ui_find --resource-id filter-district-loading \
      && ! ui_find --text-contains "Loading districts"; then
      return 0
    fi
  done
  echo "select_labeled: district list still loading after 15s" >&2
  return 1
}

# "^Shiva( +[0-9]+)?$" -> "Shiva". Empty when the pattern is not a label.
option_name_from_regex() {
  python3 -c '
import re, sys
raw = sys.argv[1]
match = re.match(r"\^\(?([A-Za-z][^($\\]*)", raw)
if not match:
    print("")
    raise SystemExit(0)
name = match.group(1)
name = re.sub(r"\([^)]*$", "", name).strip()
name = name.split("|")[0].strip()
print(name if name else "")
' "$1"
}

# Fling toward option NAME of section KIND (state, district, deity) by
# comparing it with the visible option ids, which are in sorted order.
# Returns 0 with UI_CX/UI_CY/UI_TEXT set when the option is in the tap
# band, 1 when the caller should fall back to the step scan.
# Usage: seek_option KIND NAME DEADLINE
seek_option() {
  local kind="$1" name="$2" deadline="$3"
  local i height verdict fast=1 prev="" current same=0
  local direction="" flips=0
  for i in $(seq 1 40); do
    (( SECONDS < deadline )) || return 1
    ui_dump || return 1
    read -r _ height < <(ui_screen_size) || return 1
    verdict="$(python3 "$UI_PY" option-seek "$DUMP" --kind "$kind" --name "$name" \
      --min-top $((height * 24 / 100)) --max-top $((height * 84 / 100)))" || return 1
    case "$verdict" in
      tap\ *)
        read -r _ UI_CX UI_CY UI_TEXT <<<"$verdict"
        return 0 ;;
      up|down)
        # One correction after an overshoot is normal. A second change of
        # direction is the list swinging; stop instead of paging back and forth.
        if [[ -n "$direction" && "$verdict" != "$direction" ]]; then
          flips=$((flips + 1))
          if (( flips >= 2 )); then
            echo "seek_option: ${kind} '${name}' changed direction twice" >&2
            return 1
          fi
        fi
        direction="$verdict"
        ;;
      *)
        echo "seek_option: ${kind} '${name}': ${verdict}" >&2
        return 1 ;;
    esac
    current="$(dump_scroll_sig)" || return 1
    if [[ "$current" == "$prev" ]]; then
      same=$((same + 1))
      (( same < 3 )) || { echo "seek_option: list stopped moving before '${name}'" >&2; return 1; }
    else
      same=0
    fi
    prev="$current"
    if [[ "$verdict" == down ]]; then
      # Overshot (or started below it): finish with slow, exact steps.
      fast=0
      ui_sheet_swipe down || return 1
    elif (( fast )); then
      local width
      read -r width _ < <(ui_screen_size) || return 1
      # A short, fast drag leaves momentum: many rows per dump.
      adb_shell_capped 8 input swipe $((width / 2)) $((height * 80 / 100)) \
        $((width / 2)) $((height * 32 / 100)) 120 || return 1
      sleep 0.8
      continue
    else
      ui_sheet_swipe up || return 1
    fi
    sleep 0.3
  done
  return 1
}

# Walk the option list until regex is inside the tap band, then tap it.
# Callers pass the section name (STATE, DISTRICT, DEITY). The list ends when
# a swipe leaves the option texts unchanged, not when the next header peeks in.
# One missed drag is not the end of the list: the finger may have landed on
# the apply button. Retry other finger heights, then stop. A second pass
# starts again from the top. The whole walk gives up after 120s.
select_labeled() {
  local regex="$1"
  local _section="${2:-}"
  : "${_section}"
  local pass i height min_top max_top prev="" current stuck
  local name_hint id_rx=""
  name_hint="$(option_name_from_regex "$regex")"
  if [[ -n "$name_hint" ]]; then
    id_rx="filter-option-.*-$(re_escape "$name_hint")$"
  fi
  local started=0
  local deadline=0
  if ! wait_out_district_loader; then
    return 1
  fi
  started=$SECONDS
  deadline=$((started + ${SELECT_MAX:-45}))
  if (( STEP_DEADLINE > 0 && STEP_DEADLINE < deadline )); then
    deadline=$STEP_DEADLINE
  fi
  local kind
  kind="$(printf '%s' "$_section" | tr '[:upper:]' '[:lower:]')"
  if [[ -n "$name_hint" && "$kind" =~ ^(state|district|deity)$ ]] \
    && seek_option "$kind" "$name_hint" "$deadline"; then
    SELECTED_LABEL="$(chip_label "$UI_TEXT")"
    ui_tap
    sleep 1
    return 0
  fi
  for pass in 1 2; do
    if (( SECONDS >= deadline )); then
      echo "select_labeled: gave up looking for '${regex}' after $((SECONDS - started))s" >&2
      return 1
    fi
    if [[ "$pass" -eq 2 ]]; then
      prev=""
      for i in $(seq 1 40); do
        if (( SECONDS >= deadline )); then
          echo "select_labeled: gave up looking for '${regex}' after $((SECONDS - started))s" >&2
          return 1
        fi
        ui_dump || {
          echo "select_labeled: hierarchy dump failed while looking for '${regex}'" >&2
          return 1
        }
        current="$(dump_scroll_sig)" || {
          echo "select_labeled: could not read the picker dump" >&2
          return 1
        }
        if [[ -n "$prev" && "$current" == "$prev" ]]; then
          break
        fi
        prev="$current"
        ui_sheet_swipe down || {
          echo "select_labeled: swipe failed while looking for '${regex}'" >&2
          return 1
        }
        sleep 0.25
      done
    fi
    prev=""
    stuck=0
    for i in $(seq 1 80); do
      if (( SECONDS >= deadline )); then
        echo "select_labeled: gave up looking for '${regex}' after $((SECONDS - started))s" >&2
        return 1
      fi
      ui_dump || {
        echo "select_labeled: hierarchy dump failed while looking for '${regex}'" >&2
        return 1
      }
      read -r _ height < <(ui_screen_size) || {
        echo "select_labeled: screen size unreadable while looking for '${regex}'" >&2
        return 1
      }
      min_top=$((height * 24 / 100))
      max_top=$((height * 84 / 100))
      if { [[ -n "$id_rx" ]] && ui_find --resource-id-regex "$id_rx" --min-top "$min_top" --max-top "$max_top" --prefer upper; } \
        || { ui_find --text-regex "$regex" --min-top "$min_top" --max-top "$max_top" --prefer upper \
        && [[ ! "$UI_TEXT" =~ ^Show[[:space:]]+[0-9]+[[:space:]]+temples?$ ]]; }; then
        SELECTED_LABEL="$(chip_label "$UI_TEXT")"
        ui_tap
        sleep 1
        return 0
      fi
      if ui_find --text-regex "$regex" --min-top "$max_top" --prefer upper \
        && [[ ! "$UI_TEXT" =~ ^Show[[:space:]]+[0-9]+[[:space:]]+temples?$ ]]; then
        ui_sheet_swipe up || {
          echo "select_labeled: swipe failed while looking for '${regex}'" >&2
          return 1
        }
        sleep 0.3
        continue
      fi
      if ui_find --text-regex "$regex" --max-top "$min_top" --prefer lower; then
        ui_sheet_swipe down || {
          echo "select_labeled: swipe failed while looking for '${regex}'" >&2
          return 1
        }
        sleep 0.3
        continue
      fi
      current="$(dump_scroll_sig)" || {
        echo "select_labeled: could not read the picker dump" >&2
        return 1
      }
      if [[ -n "$prev" && "$current" == "$prev" ]]; then
        stuck=$((stuck + 1))
        # A drag that misses the list leaves the texts unchanged before
        # anything has scrolled. After the list has moved, one unchanged
        # dump is also not the end: the finger can land on a chip and the
        # next swipe is a no-op, which used to stop at Ganesha and the
        # A-districts. Try other finger heights, then stop. Do not keep
        # going just because a spinner changed the raw dump.
        if [[ "$stuck" -le 4 ]]; then
          ui_sheet_swipe up $((46 + stuck * 8)) || {
            echo "select_labeled: swipe failed while looking for '${regex}'" >&2
            return 1
          }
          sleep 0.3
          continue
        fi
        break
      fi
      stuck=0
      prev="$current"
      ui_sheet_swipe up || {
        echo "select_labeled: swipe failed while looking for '${regex}'" >&2
        return 1
      }
      sleep 0.3
    done
  done
  echo "select_labeled: gave up looking for '${regex}' after $((SECONDS - started))s" >&2
  return 1
}

apply_sheet() {
  local height attempt
  read -r _ height < <(ui_screen_size) || return 1
  for attempt in 1 2; do
    # The result button is pinned to the bottom of the sheet. Prefer that
    # node so a higher label is not tapped and the sheet left open.
    if ! ui_wait 8 --text-regex '^Show [0-9]+ temples?$' --prefer lower; then
      echo "apply_sheet: Show N temples was not found" >&2
      return 1
    fi
    if (( UI_CY < height * 68 / 100 )); then
      echo "apply_sheet: Show N temples was not in the bottom band" >&2
      return 1
    fi
    ui_tap
    sleep 1
    if ! sheet_open; then
      return 0
    fi
  done
  echo "apply_sheet: sheet stayed open after 2 taps" >&2
  return 1
}

chip_exact() {
  local label="$1"
  find_filter_chip "" "^$(re_escape "$label")$"
}

recover_sheet() {
  if sheet_open; then
    ui_back
    sleep 1
  fi
}

clear_named() {
  local which="$1"
  if ui_dump && ui_find --content-desc "Clear ${which} filter"; then
    ui_tap
  elif ui_dump && ui_find --resource-id filter-clear; then
    ui_tap
  else
    echo "clear_named: no clear control for ${which}" >&2
    return 1
  fi
  # Assert the clear ran: the per-chip clear control must be gone.
  local _
  for _ in 1 2 3 4 5; do
    sleep 0.6
    ui_dump || continue
    ui_find --content-desc "Clear ${which} filter" || return 0
  done
  echo "clear_named: ${which} filter still applied after tapping clear" >&2
  return 1
}
