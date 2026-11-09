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
# All-India pick targets (flows 06, 22). Each is on the filter sheet's
# first screen at 320x640, so it fits the 20s picker give-up with no
# scroll: the first district of the bundled boundary asset in the app's
# sort, and the first single-word live deity label (same targets and
# replay evidence as PR #124). Shiva is picked only Tamil Nadu-scoped.
# shellcheck disable=SC2034
ALL_INDIA_DISTRICT_PICK='^24 Paraganas North( +[0-9]+)?$'
# Round 4.4: the deity pick is the sheet's first real option (@first, see
# first_real_option): the hard-coded '^Ahalya( +[0-9]+)?$' left the live
# list (run 41461260068: "81 Yoginis; Gauri-Shankar (central shrine)",
# "Adinatha — Jain", ...; shard 10 "deity 'Ahalya' is not in the list").
# shellcheck disable=SC2034
ALL_INDIA_DEITY_PICK='@first'
# Bounded picker walk in select_labeled, in seconds.
PICKER_GIVEUP_S="${EMULATOR_PICKER_GIVEUP_S:-20}"
# District and deity lists are 400-600 options; run 41373837994 gave up on
# Madurai (29) and Shiva (17) at 20-22s with the target one fling away.
# Round 4.3: the state picker gets it too. Run 41391038302 gave up on Tamil
# Nadu (27th of 36 states) at 20s: STATE is always "near" (slow drags, no
# flings), each look costs a drag plus 2-3 dumps of ~2.3s on a cold
# swiftshader AVD, so 20s held 3 looks (dryrun 04-pickers-before).
PICKER_LONG_GIVEUP_S="${EMULATOR_PICKER_LONG_GIVEUP_S:-45}"
# Scoped targets: Shiva and Madurai are picked only from a list already
# scoped to Tamil Nadu (state chip shows it): ~32 deities / ~38 districts.
# All-India lists (600 deities) get the head-of-list picks above.
TN_DEITY_PICK='^Shiva( +[0-9]+)?$'
TN_DISTRICT_PICK='^Madurai( +[0-9]+)?$'

# Per-step cap. Every record_* call starts a new step; ui_dump (called by
# every wait, scroll and find loop) refuses to run once the current step is
# older than STEP_BUDGET_S, so a stuck step fails on its own instead of
# eating the 600s flow budget (06, 17, 29, 30 in run 41373837994).
STEP_BUDGET_S="${EMULATOR_STEP_BUDGET_S:-150}"
STEP_STARTED=$SECONDS
STEP_TIMED_OUT=0
step_reset() { STEP_STARTED=$SECONDS; STEP_TIMED_OUT=0; }
step_budget_ok() {
  if (( SECONDS - STEP_STARTED > STEP_BUDGET_S )); then
    if (( ! STEP_TIMED_OUT )); then
      echo "step timeout: current step older than ${STEP_BUDGET_S}s (EMULATOR_STEP_BUDGET_S)" >&2
    fi
    STEP_TIMED_OUT=1
    return 1
  fi
  return 0
}

mkdir -p "$SHOT_DIR" "$REC_DIR" "$LOG_DIR" "$DUMP_DIR"

record_pass() {
  printf 'PASS %s: %s\n' "$FLOW" "$1" | tee -a "$RESULTS"
  step_reset
}

record_fail() {
  local why="$2"
  (( STEP_TIMED_OUT )) && why="${why} [step timeout ${STEP_BUDGET_S}s]"
  printf 'FAIL %s: %s: %s\n' "$FLOW" "$1" "$why" | tee -a "$RESULTS"
  step_reset
}

record_xfail() {
  printf 'XFAIL %s: %s: %s\n' "$FLOW" "$1" "$2" | tee -a "$RESULTS"
  step_reset
}

# An XFAIL step that passed: the known bug is fixed and the XFAIL mark must
# go. summarize.sh fails the job on any XPASS.
record_xpass() {
  printf 'XPASS %s: %s: %s\n' "$FLOW" "$1" "$2" | tee -a "$RESULTS"
  echo "::error::XPASS ${FLOW}: $1 passed but is marked XFAIL ($2); remove the XFAIL mark"
  step_reset
}

# NA: the step's precondition is proven absent on this device/data (e.g. a
# '1 / 1' gallery). Not a PASS; summarize lists it apart, and the strict
# release gate refuses it unless "<flow>:<step>" is in plan.sh
# DEFAULT_NA_STEPS.
record_na() {
  printf 'NA %s: %s: %s\n' "$FLOW" "$1" "$2" | tee -a "$RESULTS"
  step_reset
}
na_step() {
  record_na "$1" "$2"
  step_shot "$1"
  save_step_dump "$1"
}

record_not_run() {
  printf 'NOT RUN %s: %s: %s\n' "$FLOW" "$1" "$2" | tee -a "$RESULTS"
  step_reset
}

# Artifact file name for a step id. actions/upload-artifact rejects ':'
# (and " < > | * ? CR LF), and run 41391038302 lost all of shard 11 on
# "30s-filter-matrix-sequences_seq1-deity:select.xml". ':' becomes '_',
# and anything outside [A-Za-z0-9_.-] becomes '_' too.
artifact_safe_name() {
  printf '%s' "$1" | tr ':' '_' | tr -c 'A-Za-z0-9_.-' '_'
}

# Copy the current dump next to the step it explains.
save_step_dump() {
  cp -f "$DUMP" "${DUMP_DIR}/$(artifact_safe_name "${FLOW}_${1}").xml" 2>/dev/null || true
}

step_shot() {
  local safe dest attempt
  SHOT_N=$((SHOT_N + 1))
  safe=$(artifact_safe_name "$1")
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
  save_step_dump "$1"
  # A sheet left open makes the next step fail on the wrong screen.
  dismiss_blockers || true
}

xfail_step() {
  record_xfail "$1" "$2"
  step_shot "$1"
  save_step_dump "$1"
}

# Known-bug step: XFAIL while the bug is there, XPASS (a failure) once the
# check passes, so the mark is removed when the fix lands.
#   xfail_known STEP TICKET REASON COMMAND...
xfail_known() {
  local step="$1" ticket="$2" reason="$3"
  shift 3
  if "$@"; then
    record_xpass "$step" "${ticket}: ${reason}"
    step_shot "$step"
  else
    xfail_step "$step" "${ticket}: ${reason}"
  fi
}

skip_step() {
  # NOT RUN is only for a step whose prerequisite already failed.
  # A skip with no FAIL in this flow is itself a failure.
  if ! grep -Eq "^FAIL ${FLOW}:" "$RESULTS" 2>/dev/null; then
    record_fail "$1" "no failed prerequisite: $2"
    step_shot "$1"
    save_step_dump "$1"
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

# Width and height as the screen is now. wm size reports the natural
# (portrait) size; in landscape (SurfaceOrientation 1 or 3) the two are
# swapped. Run 41373837994 flow 19 computed portrait bands (320x640) on a
# 640x320 landscape screen.
ui_screen_size() {
  local size_rc size rot
  size="$(timeout 8 adb shell wm size | tr -d '\r' | awk '
    /Override size:/ { w=$3; next }
    /Physical size:/ { if (w == "") w=$3 }
    END {
      split(w, a, "x")
      if (a[1] != "" && a[2] != "") print a[1], a[2]
    }
  '; exit "${PIPESTATUS[0]}")"
  size_rc=$?
  if [[ "$size_rc" -eq 124 ]]; then
    echo "ui_screen_size: wm size timed out after 8s" >&2
    return "$size_rc"
  fi
  [[ -n "$size" ]] || return 1
  rot="$(timeout 8 adb shell dumpsys input 2>/dev/null | tr -d '\r' | sed -n 's/.*SurfaceOrientation: *\([0-9]\).*/\1/p' | head -1)"
  if [[ "$rot" == 1 || "$rot" == 3 ]]; then
    read -r w h <<<"$size"
    if (( w < h )); then size="$h $w"; fi
  fi
  echo "$size"
}

ui_dump() {
  local attempt err noisy rc
  step_budget_ok || return 1
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

# Back out until the app's detail screen is on top, at most $1 backs.
# Run 41314245431 (flow 25): Maps opened "Update Google Maps to continue",
# which takes its own backs, so a fixed two backs left Maps on screen.
# Sets BACKS_USED. Exit 0 when Get Directions in our package is visible.
# After a Get Directions tap with Maps disabled: a browser in front (the
# app's URL fallback) or an in-app message about Maps/directions.
maps_fallback_shown() {
  [[ -s "${DUMP:-}" ]] || return 1
  if grep -Eq 'package="(com\.android\.chrome|org\.chromium\.[a-z.]+|com\.android\.browser|org\.mozilla\.[a-z.]+)"' "$DUMP"; then
    return 0
  fi
  ui_find --text-regex '(?i)(maps|directions).*(not available|unavailable|could ?n.t|install|no app)'
}

back_until_detail() {
  local max="${1:-6}" pkg="${PKG:-${EMULATOR_PACKAGE:-}}"
  BACKS_USED=0
  while (( BACKS_USED < max )); do
    ui_back
    BACKS_USED=$((BACKS_USED + 1))
    sleep 1
    ui_dump || continue
    if ui_find --resource-id get-directions-button --package-contains "$pkg" ||
       ui_find --text-regex 'Get Directions' --package-contains "$pkg"; then
      return 0
    fi
  done
  return 1
}

# Logcat window for one step, without clearing the buffer (later checks
# still see earlier lines): write a unique marker line with log -t, then
# read only the lines after it. adb shell joins its arguments and the device
# shell re-splits them (run of cc3e912: date +'%m-%d %H:%M:%S.000' became two
# operands), so the device command goes as ONE string with the tag quoted.
# The marker line itself is printed first: its threadtime prefix is the
# device-local start time of the window.
# A missing marker is an error, not an empty window: without it the window
# is empty, no crash or Maps START can be seen, and the check would pass on
# nothing. logcat_window_read prints the window and exits 0 only when the
# TempleEmuMark line is in the log; otherwise it prints nothing, says so on
# stderr and exits 3. Callers must FAIL the step on a non-zero status.
logcat_window_start() {
  LOGCAT_MARK="temple-emu-window-${1:-step}-$$-${RANDOM}"
  if ! adb_shell_capped 8 "log -t TempleEmuMark '${LOGCAT_MARK}'" >/dev/null 2>&1; then
    echo "logcat_window_start: log -t TempleEmuMark failed" >&2
    return 1
  fi
}
logcat_window_read() {
  local out
  if [[ -z "${LOGCAT_MARK:-}" ]]; then
    echo "logcat_window_read: no window started (TempleEmuMark marker missing)" >&2
    return 3
  fi
  out="$(timeout 8 adb logcat -d -v threadtime </dev/null 2>/dev/null | tr -d '\r' |
    awk -v m="${LOGCAT_MARK}" '!f && index($0, m) { f = 1 } f')"
  if [[ -z "$out" ]]; then
    echo "logcat_window_read: TempleEmuMark marker '${LOGCAT_MARK}' not in logcat" >&2
    return 3
  fi
  printf '%s\n' "$out"
}

# Crash evidence for our package in logcat text on stdin: an AndroidRuntime
# FATAL EXCEPTION for PKG, an ANR in PKG, or "PKG has stopped".
app_crashed_in_log() {
  local pkg="${1:-$PKG}" p
  p="${pkg//./\\.}"
  grep -Eq "Process: ${p}, PID|ANR in ${p}( |\$)|${p}.* has stopped|Force finishing activity ${p}/"
}

# Chip bar on screen (state chip there, deity chip reachable) and ONLY the
# district chip missing. Anything else (no bar at all, e.g. the screen is
# Home, run 41314245431 30 drawer_bar-*-then-district) is not this case.
chip_bar_only_district_missing() {
  ui_dump || return 1
  ui_find --resource-id filter-chip-state || ui_find --content-desc "Choose a state" || return 1
  if python3 "$UI_PY" resource-ids "$DUMP" --prefix filter-chip- 2>/dev/null | grep -qx 'filter-chip-district' ||
     ui_find --content-desc "Choose a district"; then
    return 1
  fi
  ui_find --resource-id filter-chip-deity || ui_find --content-desc "Choose a deity" || ui_find --text-regex '^Deity$' ||
    scroll_chips_until --content-desc "Choose a deity" || return 1
}

# XPASS probe for the district XFAIL: the chip shows up after a short wait.
district_chip_reappears() {
  sleep 2
  ui_dump || return 1
  python3 "$UI_PY" resource-ids "$DUMP" --prefix filter-chip- 2>/dev/null | grep -qx 'filter-chip-district'
}

# Maps activity launches in logcat text on stdin (ActivityTaskManager START
# lines for com.google.android.apps.maps).
count_maps_starts() {
  grep -c 'ActivityTaskManager: START u0 .*cmp=com\.google\.android\.apps\.maps/' || true
}

# Page index on screen (N of detail-gallery-N) from the last dump.
gallery_page() {
  python3 - "$DUMP" <<'PY2'
import re, sys
s = open(sys.argv[1], encoding="utf-8", errors="replace").read()
pages = sorted(set(re.findall(r'resource-id="detail-gallery-(\d+)"', s)))
if len(pages) != 1:
    sys.exit(1)
print(pages[0])
PY2
}

# Gallery page count M from the "N / M" counter. Real dumps carry it in
# content-desc with text="" (run41373837994/detail_multi_1of5.xml,
# run41314245431/gallery_burst_5of5.xml), so match both attributes, the
# same way gallery_index_consistent does. Prints 0 when there is none.
gallery_count() {
  python3 - "$DUMP" <<'PY2'
import re, sys
s = open(sys.argv[1], encoding="utf-8", errors="replace").read()
m = re.search(r'(?:text|content-desc)="\d+ / (\d+)"', s)
print(m.group(1) if m else 0)
PY2
}

# Monotonic seconds (float) for timing a fling+dump window.
mono_now() {
  python3 -c 'import time; print(f"{time.monotonic():.2f}")'
}

# Gallery counter matches the page on screen: detail-gallery-N shows
# "N+1 / M". Run 41314245431 failed on '^1 / ' after a burst whose
# left/right flings were vertical (ui_fling) and auto-advance had moved
# on; the dump itself was consistent (detail-gallery-4, '5 / 5').
gallery_index_consistent() {
  python3 - "$DUMP" <<'PY2'
import re, sys
s = open(sys.argv[1], encoding="utf-8", errors="replace").read()
pages = [int(m) for m in re.findall(r'resource-id="detail-gallery-(\d+)"', s)]
counters = re.findall(r'(?:text|content-desc)="(\d+) / (\d+)"', s)
if len(set(pages)) != 1 or len(set(counters)) != 1:
    sys.exit(1)
k, m = (int(x) for x in counters[0])
sys.exit(0 if k == pages[0] + 1 and 1 <= k <= m else 1)
PY2
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
  # Round 4.4.1 nit: optional travel in % of the screen (default 24). A
  # short pull (the @first list-head search) keeps clear of the sheet's
  # own drag-to-dismiss when the list is already near its top.
  local travel_pct="${3:-}"
  local width height travel start_y end_y
  read -r width height < <(ui_screen_size) || return 1
  local x=$((width / 2))
  # A 72px step never reached Shiva, Madurai, or Vishnu before the
  # 120s cap. A quarter of the sheet crosses several rows per dump and
  # still stops inside the tap band on the next look.
  if [[ -n "$travel_pct" ]]; then
    travel=$((height * travel_pct / 100))
    (( travel < 48 )) && travel=48
  else
    travel=$((height * 24 / 100))
    if (( travel < 160 )); then
      travel=160
    fi
    if (( travel > 320 )); then
      travel=320
    fi
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
  # Start inside the option scroller (ui.py sheet-band, 16px in from its
  # edges). Above it is the sheet header: a drag there never scrolls and a
  # downward pull dismisses the sheet (ported from PR #124, run 41269171081).
  local band_top band_bot
  if [[ -s "${DUMP:-}" ]] && read -r band_top band_bot < <(python3 "$UI_PY" sheet-band "$DUMP" 2>/dev/null) \
    && [[ "$band_top" =~ ^[0-9]+$ && "$band_bot" =~ ^[0-9]+$ ]]; then
    (( start_y < band_top + 16 )) && start_y=$((band_top + 16))
    (( start_y > band_bot - 16 )) && start_y=$((band_bot - 16))
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

# Round 4.4.9c (Reviewer): each install is bounded (EMULATOR_INSTALL_S,
# 120s + 5s kill-after). It runs inside the flow's own cap (300-600s), so
# a hung install fails the flow ("adb install failed", rc 124) instead of
# eating the whole cap; worst case install + services wait 12s + retry
# install = 262s, still inside the 300s minimum cap.
install_once() {
  timeout --kill-after=5 "${EMULATOR_INSTALL_S:-120}" adb install -r -d "$EMULATOR_APK" 2>&1
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
  local log rc=0 retried=0
  uninstall_app
  log="$(install_once)" || rc=$?
  if (( rc != 0 )) && [[ "$log" == *"cmd: Can't find service: package"* ]]; then
    # Round 4.4.9 (run 41757362316): the package service was not up. Wait
    # for the services (bounded: EMULATOR_INSTALL_SERVICES_WAIT_S, 10s,
    # inside the flow's guard) and retry the install ONCE, only on this
    # exact error; any other install error is not retried here.
    echo "install: 'Can't find service: package'; waiting for services, then one retry" >&2
    timeout --kill-after=2 "${EMULATOR_INSTALL_SERVICES_WAIT_S:-10}" bash "${ROOT}/tool/emulator/services_ready.sh" "${EMULATOR_INSTALL_SERVICES_WAIT_S:-10}" >&2 || true
    rc=0; retried=1; log="$(install_once)" || rc=$?
  fi
  if (( rc != 0 )); then
    # Round 4.4.9d: the uninstall+reinstall branch only runs when the
    # package-service retry was not used, so at most 2 installs (2 x 125s)
    # + the 12s services wait = 262s per flow, inside the 300s minimum cap.
    if (( retried == 0 )) && [[ "$log" == *"INSTALL_FAILED_UPDATE_INCOMPATIBLE"* ]]; then
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

app_installed() {
  [[ -n "${PKG:-}" ]] || return 1
  adb_shell_capped 15 pm path "$PKG" 2>/dev/null | grep -q '^package:'
}

# Wipe this app's data between flows on a reused emulator. Same starting
# state as a fresh install (prefs, databases, caches, runtime grants).
clear_app_data() {
  local out
  out="$(adb_shell_capped 30 pm clear "$PKG" 2>&1 | tr -d '\r')" || true
  if [[ "$out" != *Success* ]]; then
    record_fail "pm-clear" "pm clear ${PKG} failed: ${out}"
    return 1
  fi
  return 0
}

# Undo device-wide state an earlier flow on this emulator may have left.
# Audit of tool/emulator/flows (PR #126 review):
#   network: wifi/data/ethernet + ip link (15, 24, 27)  -> network_on
#   airplane mode (no flow sets it; reset defensively)  -> cmd connectivity
#   wm size/density, font scale (28)                    -> reset
#   rotation (19, 23, 28)                               -> portrait, auto off
#   location mode (23), location grants (11, 23)        -> mode 3, revoke
#   Google Maps disabled (25, killed before re-enable)  -> pm enable
#   animations (runner disables them at boot)           -> scales back to 0
#   notification shade / dialogs                        -> collapse, HOME
# pm clear (clear_app_data) then wipes the app's prefs, databases, caches.
# Not reset: clipboard and locale. No flow sets them, and API 30 has no
# shell command to clear the clipboard. Each call is capped.
reset_device_state() {
  network_on || true
  adb_shell_capped 8 cmd connectivity airplane-mode disable >/dev/null 2>&1 || true
  adb_shell_capped 8 settings put global airplane_mode_on 0 >/dev/null 2>&1 || true
  adb_shell_capped 8 wm size reset >/dev/null 2>&1 || true
  adb_shell_capped 8 wm density reset >/dev/null 2>&1 || true
  adb_shell_capped 8 settings put system font_scale 1.0 >/dev/null 2>&1 || true
  adb_shell_capped 8 settings put system accelerometer_rotation 0 >/dev/null 2>&1 || true
  adb_shell_capped 8 settings put system user_rotation 0 >/dev/null 2>&1 || true
  adb_shell_capped 8 settings put secure location_mode 3 >/dev/null 2>&1 || true
  adb_shell_capped 8 pm enable com.google.android.apps.maps >/dev/null 2>&1 || true
  adb_shell_capped 8 settings put global window_animation_scale 0 >/dev/null 2>&1 || true
  adb_shell_capped 8 settings put global transition_animation_scale 0 >/dev/null 2>&1 || true
  adb_shell_capped 8 settings put global animator_duration_scale 0 >/dev/null 2>&1 || true
  adb_shell_capped 8 am force-stop "$PKG" >/dev/null 2>&1 || true
  adb_shell_capped 8 pm revoke "$PKG" android.permission.ACCESS_FINE_LOCATION >/dev/null 2>&1 || true
  adb_shell_capped 8 pm revoke "$PKG" android.permission.ACCESS_COARSE_LOCATION >/dev/null 2>&1 || true
  adb_shell_capped 8 cmd statusbar collapse >/dev/null 2>&1 || true
  adb_shell_capped 8 input keyevent KEYCODE_HOME >/dev/null 2>&1 || true
}

clean_install() {
  adb uninstall "$PKG" >/dev/null 2>&1 || true
  install_apk
}

FILTER_SHEET_TITLE_RX='^(Filters|State|District|Deity|City|Sort from state)$'
# Titles that are also idle chip labels. A content-desc of "State" is the
# chip, not proof the sheet is open (run 42675181050 bar dump).
FILTER_SHEET_TITLE_ID_RX='^filter-sheet-title-(state|district|deity|city|filters|sort-from-state)$'

sheet_open() {
  ui_dump || return 1
  # The title's own resource-id. Chips never use this id.
  if ui_find --resource-id-regex "$FILTER_SHEET_TITLE_ID_RX"; then
    return 0
  fi
  # Run 42675181050: the sheet was open, Close filters was on screen, and
  # the title text had been merged away.
  if ui_find --content-desc "Close filters"; then
    return 0
  fi
  # Older sheets titled "Filters" / "City" / "Sort from state" in
  # content-desc. State, District, and Deity are also the idle chip
  # labels, and ui_find --text-regex reads content-desc, so those three
  # words do not count as an open sheet.
  if ui_find --content-desc-regex '^(Filters|City|Sort from state)$'; then
    return 0
  fi
  ui_find --content-desc-regex '^Show [0-9]+ temples?$' \
    || ui_find --text-regex '^Show [0-9]+ temples?$'
}

# Wait until the filter sheet is up. [timeout] seconds is required.
# Succeeds on the title id, sheet_open, or the Close filters button.
wait_filter_sheet() {
  local timeout="${1:?wait_filter_sheet needs a timeout in seconds}"
  local start="$SECONDS"
  while (( SECONDS - start < timeout )); do
    if sheet_open || { ui_dump && ui_find --content-desc "Close filters"; }; then
      return 0
    fi
    sleep 1
  done
  echo "wait_filter_sheet: timed out after ${timeout}s" >&2
  return 1
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
  if ui_find --text-regex "$FILTER_SHEET_TITLE_RX" || ui_find --content-desc-regex "$FILTER_SHEET_TITLE_RX" || ui_find --text-regex '^Show [0-9]+ temples?$'; then
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
# The sheet closes on PointerMove travel from the header (_onPointerMove,
# 72px), never on the up event alone (test/sheet_header_pull_test.dart: a
# down/up with no move leaves it open). An 80ms swipe left the sheet
# unmoved in every header pull of PR #126's run 41306793034 (06, 17, 21,
# recordings show zero frames of travel) while 120ms+ swipes on the same
# devices worked. Pull slowly enough that moves are delivered on a busy
# emulator: SHEET_PULL_MS (default 300ms), then twice that on the retry.
dismiss_sheet_from_handle() {
  local width="$1"
  local height="$2"
  local pull_ms="${3:-${SHEET_PULL_MS:-300}}"
  local start_x=$((width / 2))
  local start_y=$((height * 24 / 100))
  local max_title=$((height * 36 / 100))
  if ui_find --text-regex "$FILTER_SHEET_TITLE_RX" --max-top "$max_title" || ui_find --content-desc-regex "$FILTER_SHEET_TITLE_RX" --max-top "$max_title"; then
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
  adb_shell_capped 8 input swipe "$start_x" "$start_y" "$start_x" $((height * 96 / 100)) "$pull_ms"
}

dismiss_sheet_swipe() {
  local width height
  # The sheet title can land a moment after the chip tap. Flows 06 and 17
  # otherwise report "sheet was not open" while Filters is still animating in.
  if ! sheet_open; then
    wait_filter_sheet 3 || true
  fi
  if ! sheet_open; then
    echo "sheet was not open"
    return 1
  fi
  read -r width height < <(ui_screen_size)
  dismiss_sheet_from_handle "$width" "$height"
  sleep 1
  if sheet_open; then
    dismiss_sheet_from_handle "$width" "$height" $(( ${SHEET_PULL_MS:-300} * 2 ))
    sleep 1
  fi
  if sheet_open; then
    echo "sheet still open after swipe down"
    return 1
  fi
  return 0
}

dismiss_sheet_outside() {
  local target_y
  if ! sheet_open; then
    wait_filter_sheet 3 || true
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

wait_browse_ready() {
  local start="$SECONDS"
  while (( SECONDS - start < 120 )); do
    ui_dump || true
    if ui_find --text-contains "Could not load temples"; then
      echo "directory failed to load"
      return 1
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

# network_validated: Android's ConnectivityService has validated a default
# network (NetworkCapabilities ... VALIDATED). Run 41391038302 flow 27:
# "validation passed" at 05:11:19.85 UTC, the app's retry socket at 05:11:24,
# and the harness read the old error page at 05:11:32.6 and gave up.
network_validated() {
  adb_shell_capped 10 dumpsys connectivity 2>/dev/null | tr -d '\r' \
    | grep -Eq 'Capabilities: [^]]*(^|[&: ])VALIDATED([&] |[&]|[ ]|$)'
}

# wait_network_validated [TIMEOUT_S]: poll network_validated every 2s.
wait_network_validated() {
  local timeout="${1:-60}" start="$SECONDS"
  while (( SECONDS - start < timeout )); do
    if network_validated; then
      echo "network validated after $((SECONDS - start))s"
      return 0
    fi
    sleep 2
  done
  echo "network not validated after ${timeout}s" >&2
  return 1
}

# recover_browse [GRACE_S] [RETAP_S]: after the network came back, tap
# "Try again" and give the reload GRACE_S (60) seconds, tapping it again
# every RETAP_S (15) seconds while "Could not load temples" is still shown.
# Unlike wait_browse_ready, the error page is not final until the grace ends.
# Sets RECOVER_BROWSE_MSG (call it directly, not in $(...), so the caller
# sees it).
recover_browse() {
  local grace="${1:-60}" retap="${2:-15}" start="$SECONDS" last_tap=-1000 taps=0
  while (( SECONDS - start < grace )); do
    ui_dump || { sleep 2; continue; }
    if ui_find --resource-id filter-chip-state || ui_find --text-regex '^State$'; then
      if ! ui_find --text-contains "Loading temples" && ! ui_find --text-contains "Could not load temples"; then
        RECOVER_BROWSE_MSG="browse recovered after $((SECONDS - start))s (${taps} Try again taps)"
        echo "$RECOVER_BROWSE_MSG"
        return 0
      fi
    fi
    if ui_find --text-contains "Could not load temples" || ui_find --text-regex '^(Retry|Try again)$'; then
      if (( SECONDS - last_tap >= retap )) && ui_find --text-regex '^(Retry|Try again)$'; then
        ui_tap
        taps=$((taps + 1))
        last_tap=$SECONDS
        echo "recover_browse: tapped Try again (${taps}) at +$((SECONDS - start))s"
      fi
    fi
    sleep 2
  done
  RECOVER_BROWSE_MSG="browse did not recover within ${grace}s (${taps} Try again taps)"
  echo "$RECOVER_BROWSE_MSG"
  return 1
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

# Swipe the filter chip bar inside its own scroll area (ui.py chip-bar:
# the HorizontalScrollView bounds, minus the pinned Clear button). "left"
# moves content left, revealing chips past the right edge. Falls back to
# 25%-80% of the width only when the last dump has no chip bar.
# Sets CHIP_BAR_L/R for callers that need the visible band.
scroll_chip_bar_at() {
  local y="$1"
  local direction="$2"
  local width l t r b x_from x_to
  read -r width _ < <(ui_screen_size) || return 1
  if [[ -s "${DUMP:-}" ]] && read -r l t r b < <(python3 "$UI_PY" chip-bar "$DUMP" 2>/dev/null); then
    y=$(((t + b) / 2))
    x_from=$((r - 12)); x_to=$((l + 12))
  else
    x_from=$((width * 80 / 100)); x_to=$((width * 25 / 100))
  fi
  if [[ "$direction" == "right" ]]; then
    adb_shell_capped 8 input swipe "$x_to" "$y" "$x_from" "$y" 300
  else
    adb_shell_capped 8 input swipe "$x_from" "$y" "$x_to" "$y" 300
  fi
}

# Visible band of the chip bar from the last dump: "LEFT RIGHT".
chip_bar_band() {
  local width l t r b
  if [[ -s "${DUMP:-}" ]] && read -r l t r b < <(python3 "$UI_PY" chip-bar "$DUMP" 2>/dev/null); then
    echo "$l $r"
    return 0
  fi
  read -r width _ < <(ui_screen_size) || return 1
  echo "24 $((width - 24))"
}

# The selected chip's text is the value ("Shiva"), and it may sit past the
# right edge. Match the idle label or the applied value, and scroll the bar.
# Section-scoped (round 4.3): every match is a chip-bar node. With RID
# (filter-chip-<kind>) only that chip counts; the label/regex/tooltip
# fallbacks are tried only on filter-chip-<kind> nodes. With no RID
# (chip_exact) they are tried only on filter-chip-* nodes. A bare
# --text-regex anywhere matched the app bar title ("Kerala") and option
# rows of an open sheet.
find_filter_chip() {
  local rid="$1"
  local regex="$2"
  local desc="${3:-}"
  local i width height max_top y found
  local scope_rx='^filter-chip-'
  [[ -n "$rid" ]] && scope_rx="^$(re_escape "$rid")\$"
  read -r width height < <(ui_screen_size) || return 1
  # Landscape puts the chip row below 38% of the height, so a portrait band
  # misses Kerala after rotation and the shot still shows the old chip.
  max_top=$((height * ${CHIP_MAX_TOP_PCT:-70} / 100))
  y=$((height * 22 / 100))
  for i in $(seq 1 8); do
    ui_dump || true
    found=0
    if [[ -n "$rid" ]] && ui_find --resource-id "$rid" --max-top "$max_top"; then
      found=1
    elif [[ -n "${CHIP_LABEL_RX:-}" ]] && ui_find --resource-id-regex "$scope_rx" --text-regex "$CHIP_LABEL_RX" --max-top "$max_top"; then
      found=1
    elif [[ -n "$regex" ]] && ui_find --resource-id-regex "$scope_rx" --text-regex "$regex" --max-top "$max_top" --prefer upper; then
      found=1
    elif [[ -n "$desc" ]] && ui_find --resource-id-regex "$scope_rx" --content-desc "$desc" --max-top "$max_top"; then
      found=1
    fi
    if [[ "$found" -eq 1 ]]; then
      y=$UI_CY
      local band_l band_r
      read -r band_l band_r < <(chip_bar_band) || { band_l=24; band_r=$((width - 24)); }
      # Fully tappable only when the chip centre is inside the bar, not
      # under the pinned Clear button.
      if (( UI_CX > band_l && UI_CX < band_r )); then
        return 0
      fi
      if (( UI_CX >= band_r )); then
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

# Both directions: the row keeps its scroll offset, so a chip can sit off
# the LEFT edge as well (run 41373837994: state chip after detail back in
# 22, re-tap of the state chip in 29). Scrolls 1-4 reveal the right side,
# 5-8 the left. CHIP_MAX_TOP_PCT (default 70) is the lowest top edge, in %
# of the screen height, a chip may have; the drawer's FILTERS row sits at
# 75% (y 478 of 640) and needs 95.
# "left"/"right" for scroll_chip_bar_at when the wanted filter-chip-<x> is
# not in the dump, from its place in the row order relative to the chips
# that are; empty when that cannot be told.
chip_scroll_dir() {
  local want="" a
  local -a args=("$@")
  for ((a = 0; a < ${#args[@]}; a++)); do
    if [[ "${args[$a]}" == --resource-id ]]; then want="${args[$((a + 1))]:-}"; fi
  done
  [[ "$want" == filter-chip-* && -s "${DUMP:-}" ]] || return 0
  python3 - "$DUMP" "$want" <<'PY'
import re, sys
order = ["filter-chip-state", "filter-chip-district", "filter-chip-city", "filter-chip-deity"]
want = sys.argv[2]
if want not in order:
    sys.exit(0)
ids = re.findall(r'resource-id="(filter-chip-[a-z]+)"', open(sys.argv[1], encoding="utf-8", errors="replace").read())
seen = [order.index(i) for i in ids if i in order]
if not seen:
    sys.exit(0)
print("right" if order.index(want) < min(seen) else "left")
PY
}

scroll_chips_until() {
  local i y width height max_top dir
  read -r width height < <(ui_screen_size) || return 1
  max_top=$((height * ${CHIP_MAX_TOP_PCT:-70} / 100))
  y=$((height * 22 / 100))
  for i in $(seq 1 8); do
    if ui_dump && ui_find "$@" --max-top "$max_top"; then
      y=$UI_CY
      if (( UI_CX > 24 && UI_CX < width - 24 )); then
        return 0
      fi
      if (( UI_CX >= width - 24 )); then dir=left; else dir=right; fi
    else
      if ui_find --resource-id filter-chip-state --max-top "$max_top" ||
         ui_find --resource-id-regex '^filter-chip-' --max-top "$max_top"; then
        y=$UI_CY
      fi
      # Target not in the dump: the row order is state, district, city,
      # deity. A target left of every visible chip is off the LEFT edge, so
      # scroll right first (22 used to swipe left 4 times before that).
      dir="$(chip_scroll_dir "$@")"
      if [[ -z "$dir" ]]; then
        if (( i <= 4 )); then dir=left; else dir=right; fi
      elif (( i > 4 )); then
        [[ "$dir" == left ]] && dir=right || dir=left
      fi
    fi
    scroll_chip_bar_at "$y" "$dir" || true
    sleep 0.4
  done
  echo "scroll_chips_until: not in view after 8 scrolls" >&2
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
# Flutter options carry their label in content-desc, not text (run
# 41373837994: 0 text= values in the deity and district sheets). A
# text-only signature was the same before and after every swipe, so
# seek_option saw "list stopped moving" after 3 looks while the list moved
# (17 Shiva x2, 29 Madurai). Labels and filter-option ids both count.
texts = re.findall(r'\b(?:text|content-desc)="([^"]*)"', raw)
texts += re.findall(r'resource-id="(filter-option-[^"]*)"', raw)
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

# The district sheet is open only when the Any-district row is in the
# hierarchy. The always-visible District chip, and the words "All districts"
# on that chip, are not that row.
district_sheet_lists_rows() {
  wait_out_district_loader || return 1
  ui_find --resource-id filter-option-district-any
}

# True when State, District, and Deity show their idle labels and no chip
# still offers Clear. A selected chip keeps a "Clear … filter" node.
filter_chips_idle() {
  local id want label
  ui_dump || return 1
  for id in filter-chip-state filter-chip-district filter-chip-deity; do
    case "$id" in
      filter-chip-state) want="State" ;;
      filter-chip-district) want="District" ;;
      filter-chip-deity) want="Deity" ;;
    esac
    ui_find --resource-id "$id" || return 1
    label="$(chip_label "$UI_TEXT")"
    [[ "$label" == "$want" ]] || return 1
  done
  if ui_find --content-desc "Clear state filter" \
    || ui_find --content-desc "Clear district filter" \
    || ui_find --content-desc "Clear deity filter"; then
    return 1
  fi
  return 0
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

# Seek, ported from PR #124 v4 (e55a51a): sorted-order jumps with a gallop,
# a walk back after an overshoot, and SEEK_BACK_STALL. #126's step scan
# alone cannot reach Tamil Nadu Shiva (12th of 32) inside 20s
# (dryrun-logs/fastemu/round2/shiva_tn_*).
# seek_settle [SIG]: SIG is the signature of a dump already taken after
# the last move (the slow drag's post-drag dump, or the dump after a far
# fling). It counts as settle dump 1, so a list that has stopped costs one
# more dump instead of two (round 4.3; the 4.1 slow-drag check had added a
# third dump per near look, dryrun 04-pickers-before/state-tamil-nadu.log).
seek_settle() {
  local n prev="${1:-}" cur
  for n in $(seq 1 "${SEEK_SETTLE_DUMPS:-6}"); do
    ui_dump || return 1
    cur="$(dump_scroll_sig)" || return 1
    [[ -n "$prev" && "$cur" == "$prev" ]] && return 0
    prev="$cur"
    sleep 0.4
  done
  echo "seek_option: list still moving after ${SEEK_SETTLE_DUMPS:-6} dumps" >&2
  return 1
}

# Scroll toward option NAME of section KIND (state, district, deity) by
# comparing it with the visible option ids, which are in sorted order, and
# with the visible sections (the sheet's order is: tapped section, then
# state, district, deity). Returns 0 with UI_CX/UI_CY/UI_TEXT set when the
# option is in the tap band; 2 when the dump proves it is not listed;
# 1 otherwise. Every decision is made on a settled dump: a dump taken while
# a fling still runs sent run 40916686359 past Shiva and out of STATE.
# Usage: seek_option KIND NAME DEADLINE [--prefix]
# Environment overrides are clamped: SEEK_FAR_FLINGS 1-4 (more flings per
# look only overshoot further), SEEK_MAX_MOVES 1-60 (the deadline bounds
# the walk anyway; a huge value would only hide a stuck loop).
seek_clamp() {
  local v="$1" lo="$2" hi="$3"
  [[ "$v" =~ ^[0-9]+$ ]] || v="$lo"
  (( v < lo )) && v="$lo"
  (( v > hi )) && v="$hi"
  echo "$v"
}

seek_option() {
  local kind="$1" name="$2" deadline="$3"
  local max_moves far_flings
  max_moves="$(seek_clamp "${SEEK_MAX_MOVES:-40}" 1 60)"
  far_flings="$(seek_clamp "${SEEK_FAR_FLINGS:-2}" 1 4)"
  local extra=()
  [[ "${4:-}" == --prefix ]] && extra=(--prefix)
  local i height width verdict dir reach prev="" current same=0
  local direction="" flips=0 order="" fling_pct=48 kinds settled=1 gallop=0
  read -r width height < <(ui_screen_size) || return 1
  # SEEK_FRESH_DUMP=1: the caller's last dump (wait_out_district_loader)
  # is the sheet as it is now; do not pay another 2.3s dump for it.
  if [[ "${SEEK_FRESH_DUMP:-}" != 1 || ! -s "$DUMP" ]]; then
    ui_dump || return 1
  fi
  # Every drag starts inside the option scroller (ui.py sheet-band). Above
  # it is the sheet header, where a drag never scrolls and a downward pull
  # dismisses. The fixed 32% fling start (y 204 of 640) was on the header,
  # so each downward fling after an overshoot did nothing and the walk
  # ended "list stopped moving" (run 41269171081: Madurai in 06 and 30b,
  # Shiva in 06 and 29j). 16px keeps the finger off the scroller's edges.
  local band_top band_bot
  if ! read -r band_top band_bot < <(python3 "$UI_PY" sheet-band "$DUMP") \
    || ! [[ "$band_top" =~ ^[0-9]+$ && "$band_bot" =~ ^[0-9]+$ ]]; then
    band_top=$((height * 39 / 100))
    band_bot=$((height * 89 / 100))
  fi
  band_top=$((band_top + 16))
  band_bot=$((band_bot - 16))
  # The first dump is the sheet as it opened: scrolled to the top, so the
  # first visible section is the head of the order.
  if kinds="$(python3 "$UI_PY" sheet-kinds "$DUMP")"; then
    # One kind means this is a separate State, District, or Deity sheet.
    # Do not append the other kinds: a name past the last visible row is
    # further down this sheet, not absent in a section that is not open.
    if [[ "$kinds" != *" "* ]]; then
      order="$kinds"
    else
      order="$(printf '%s state district deity' "$kinds" | tr ' ' '\n' | awk 'NF && !seen[$0]++' | paste -sd, -)"
    fi
  else
    echo "seek_option: no picker section on screen (is the sheet open?)" >&2
    return 1
  fi
  for i in $(seq 1 "$max_moves"); do
    if (( SECONDS >= deadline )); then
      echo "seek_option: ${kind} '${name}' not reached before the deadline (${i} looks, order ${order})" >&2
      return 1
    fi
    verdict="$(python3 "$UI_PY" option-seek "$DUMP" --kind "$kind" --name "$name" --order "$order" "${extra[@]}" \
      --min-top $((height * 24 / 100)) --max-top $((height * 84 / 100)))" || return 1
    read -r dir reach _ <<<"$verdict"
    [[ -n "${SEEK_TRACE:-}" ]] && echo "seek_option: t=$SECONDS look ${i}: ${verdict} settled=${settled} pct=${fling_pct} first=$(grep -o "filter-option-[a-z]*-[^\"]*" "$DUMP" | head -1)" >&2
    # A far run is flung without waiting for the list to stop (run
    # 40992967143: settling after every fling spent 45s to cross A-P).
    # Only "still far, same way" may act on a moving list; any other
    # verdict, above all a tap, is taken again on a settled dump.
    if (( ! settled )) && ! [[ "$dir" == "$direction" && "$reach" =~ ^(far|mid)$ && "$flips" -eq 0 ]]; then
      seek_settle "$(dump_scroll_sig)" || return 1
      settled=1
      continue
    fi
    case "$dir" in
      tap)
        read -r _ UI_CX UI_CY UI_TEXT <<<"$verdict"
        return 0 ;;
      up|down) ;;
      absent)
        echo "seek_option: ${kind} '${name}' is not in the list (neighbours bracket it)" >&2
        return 2 ;;
      *)
        echo "seek_option: ${kind} '${name}': ${verdict}" >&2
        return 1 ;;
    esac
    # Every change of direction is an overshoot. Fling weaker after each;
    # the list swinging forever is stopped by SEEK_MAX_FLIPS.
    if [[ -n "$direction" && "$dir" != "$direction" ]]; then
      flips=$((flips + 1))
      fling_pct=$((fling_pct / 2))
      if (( flips >= ${SEEK_MAX_FLIPS:-6} )); then
        echo "seek_option: ${kind} '${name}' changed direction ${flips} times" >&2
        return 1
      fi
    fi
    direction="$dir"
    # A downward fling while the Any row is on screen pulls the sheet shut
    # (run 42699042193, 30s2: Shiva seek, then no sheet). The name is not
    # above the head of the list.
    if [[ "$dir" == down ]] && ui_find --resource-id "filter-option-${kind}-any"; then
      echo "seek_option: ${kind} '${name}' is not above the list head" >&2
      return 2
    fi
    current="$(dump_scroll_sig)" || return 1
    if [[ "$current" == "$prev" ]]; then
      same=$((same + 1))
      # Only an upward walk can hit the real end of the list. Once the walk
      # has passed the target (dir down) the top is still ahead, so one or
      # two unmoved looks there are not the end. But a list that never
      # moves back (sheet stuck, swipes eaten) is: stop after
      # SEEK_BACK_STALL (default 4, ~12s) unchanged looks, return 3 so
      # select_labeled does not spend the rest of its give-up on a step
      # scan that would only swipe the same dead list.
      if (( same >= $(seek_clamp "${SEEK_BACK_STALL:-4}" 2 8) )) && [[ "$dir" == down ]]; then
        echo "seek_option: list stopped moving while walking back to ${kind} '${name}'" >&2
        return 3
      fi
      if (( same >= 3 )) && [[ "$dir" == up ]]; then
        # Three swipes that moved nothing: the end of the list, or swipes
        # that missed the scroller. The caller's bounded step scan decides.
        echo "seek_option: list stopped moving before ${kind} '${name}'" >&2
        return 1
      fi
    else
      same=0
    fi
    prev="$current"
    local pct=0
    case "$reach" in
      far) pct=$fling_pct ;;
      mid) pct=$((fling_pct / 3)) ;;
    esac
    # Gallop: before the first overshoot, start with one short fling and
    # grow it each look the target is still far the same way. A full
    # double fling from the head of a short section (Tamil Nadu's ~30
    # deities) crossed it and the next two sections; the walk back cost
    # more than the walk (replay test, 18s of a 20s PICKER_GIVEUP_S).
    local gallop_flings="" drag_before="" drag_after=""
    if [[ "$reach" =~ ^(far|mid)$ ]] && (( flips == 0 )) && [[ "${SEEK_GALLOP:-1}" == 1 ]]; then
      local g_pcts=()
      read -r -a g_pcts <<<"${SEEK_GALLOP_PCTS:-32 48}"
      if (( gallop < ${#g_pcts[@]} )); then
        pct=${g_pcts[$gallop]}
        # "mid" is the next initial or closer: half the step.
        [[ "$reach" == mid ]] && pct=$((pct / 2))
        gallop_flings=1
      fi
      gallop=$((gallop + 1))
    fi
    if (( pct >= 8 )); then
      # A short, fast drag leaves momentum: many rows per dump.
      local y_lo=$((height * 32 / 100)) y_hi n flings=1
      (( y_lo < band_top )) && y_lo=$band_top
      y_hi=$((y_lo + height * pct / 100))
      (( y_hi > height * 82 / 100 )) && y_hi=$((height * 82 / 100))
      (( y_hi > band_bot )) && y_hi=$band_bot
      # Run 40992967143: one 120ms fling per look moved the 600-option
      # DEITY section by about a letter, and each look costs ~5s (swipe +
      # settle dumps), so every Shiva/Vishnu pick ran out of its 45s at
      # P-R. Settling, not swiping, is the cost: until the first overshoot
      # (far: another section or 2+ initials away; mid: the next initial or
      # a far letter inside the name), send SEEK_FAR_FLINGS flings back to
      # back and do not wait for the list to stop (see settled above).
      if [[ "$reach" =~ ^(far|mid)$ ]] && (( flips == 0 )); then
        flings="${gallop_flings:-$far_flings}"
      fi
      for n in $(seq 1 "$flings"); do
        if [[ "$dir" == up ]]; then
          adb_shell_capped 8 input swipe $((width / 2)) "$y_hi" $((width / 2)) "$y_lo" "${SEEK_FLING_MS:-120}" || return 1
        else
          adb_shell_capped 8 input swipe $((width / 2)) "$y_lo" $((width / 2)) "$y_hi" "${SEEK_FLING_MS:-120}" || return 1
        fi
      done
      : "$n"
    else
      # Slow drag: no momentum, the list moves by the finger's travel.
      # Run 40992967143's endgame crept through the "Shiva (...)" rows at
      # ui_sheet_swipe's 24% a look. 84% -> 42% of the screen (y 537 -> 269
      # on 640) is 42%, still less than the 318px option scroller, so no
      # row can pass between two looks unseen.
      local s_lo=$((height * 42 / 100)) s_hi=$((height * 84 / 100))
      (( s_lo < band_top )) && s_lo=$band_top
      (( s_hi > band_bot )) && s_hi=$band_bot
      drag_before="$(dump_scroll_sig)" || return 1
      if [[ "$dir" == up ]]; then
        adb_shell_capped 8 input swipe $((width / 2)) "$s_hi" $((width / 2)) "$s_lo" "${SEEK_DRAG_MS:-900}" || return 1
      else
        adb_shell_capped 8 input swipe $((width / 2)) "$s_lo" $((width / 2)) "$s_hi" "${SEEK_DRAG_MS:-900}" || return 1
      fi
      # The slow drag has its own retry: when the list did not move, drag
      # again off the centre column (a chip under the finger can take the
      # touch as a tap-down) and slower, once per look.
      if ui_dump && drag_after="$(dump_scroll_sig)" && [[ "$drag_after" == "$drag_before" ]]; then
        echo "seek_option: slow drag did not move the ${kind} list; retrying at x=$((width / 4)) with ${SEEK_DRAG_RETRY_MS:-1500}ms" >&2
        if [[ "$dir" == up ]]; then
          adb_shell_capped 8 input swipe $((width / 4)) "$s_hi" $((width / 4)) "$s_lo" "${SEEK_DRAG_RETRY_MS:-1500}" || return 1
        else
          adb_shell_capped 8 input swipe $((width / 4)) "$s_lo" $((width / 4)) "$s_hi" "${SEEK_DRAG_RETRY_MS:-1500}" || return 1
        fi
        # The list moved after drag_after was taken: it cannot settle anything.
        drag_after=""
      fi
    fi
    if [[ "$reach" =~ ^(far|mid)$ ]] && (( flips == 0 )); then
      ui_dump || return 1
      settled=0
    else
      # A slow drag has no momentum: its post-drag dump is settle dump 1.
      seek_settle "$drag_after" || return 1
      settled=1
    fi
  done
  echo "seek_option: ${kind} '${name}' not reached in ${max_moves} moves" >&2
  return 1
}

# stable_option_tap REGEX OPT_RX: UI_CX/UI_CY/UI_TEXT are an option found
# on the current dump. Dump once more and tap only when the same option
# (OPT_RX-scoped, REGEX-matching label) is at the same place (within 4 px)
# in both dumps: a list still moving under the finger is never tapped.
# Sets SELECTED_LABEL. Returns 1 (no tap) when the second dump disagrees.
stable_option_tap() {
  local regex="$1" opt_rx="${2:-.}" x="$UI_CX" y="$UI_CY" text="$UI_TEXT"
  local sig1 sig2
  sig1="$(dump_scroll_sig)" || return 1
  ui_dump || return 1
  sig2="$(dump_scroll_sig)" || return 1
  if [[ "$sig1" != "$sig2" ]]; then
    [[ -n "${SEEK_TRACE:-}" ]] && echo "stable_option_tap: list moved between dumps; not tapping '${text}'" >&2
    return 1
  fi
  if ! ui_find --resource-id-regex "$opt_rx" --text-regex "$regex" --prefer upper \
    || (( UI_CY - y > 4 || y - UI_CY > 4 )); then
    UI_CX="$x"; UI_CY="$y"; UI_TEXT="$text"
    if ! ui_find --resource-id-regex "$opt_rx" --text-regex "$(re_escape "$(chip_label "$text")")" --prefer upper \
      || (( UI_CY - y > 4 || y - UI_CY > 4 )); then
      echo "stable_option_tap: '${text}' not at y=${y} on the second dump" >&2
      return 1
    fi
  fi
  SELECTED_LABEL="$(chip_label "$UI_TEXT")"
  ui_tap || { echo "stable_option_tap: tap on '${UI_TEXT}' failed" >&2; return 1; }
  sleep 1
  return 0
}

# state_chip_is LABEL: the state chip (filter-chip-state) shows LABEL.
# Sets STATE_CHIP_ACTUAL to what it shows.
state_chip_is() {
  local want="$1"
  STATE_CHIP_ACTUAL=""
  ui_dump || return 1
  find_filter_chip filter-chip-state "" "" >/dev/null 2>&1 || return 1
  STATE_CHIP_ACTUAL="$(chip_label "$UI_TEXT")"
  [[ "$STATE_CHIP_ACTUAL" == "$want" ]]
}

# Walk the option list until regex is inside the tap band, then tap it.
# Callers pass the section name (STATE, DISTRICT, DEITY). The list ends when
# a swipe leaves the option texts unchanged, not when the next header peeks in.
# One missed drag is not the end of the list: the finger may have landed on
# the apply button. Retry other finger heights, then stop. A second pass
# starts again from the top. The whole walk gives up after
# PICKER_GIVEUP_S (20s): a missing option fails fast instead of costing
# about 2 minutes per case (Confluence 12353537, option A).
# Round 4.3: the section is used. With STATE/DISTRICT/DEITY the step scan
# only matches filter-option-<kind>-* rows (run 41391038302: the DISTRICT
# scan tapped "Bihar N" in STATE), and every tap waits for two matching
# dumps (stable_option_tap).
# Filter bar on screen: any filter chip or the chip-row Clear. The state
# chip alone is not enough: the chip row scrolls horizontally
# (directory_filter_bar.dart _chipScroll) and run 41461260068's
# seq1-filter-kept dump had it scrolled off to the left, with
# filter-chip-district, filter-chip-deity "Shiva" and filter-clear on screen.
# Round 4.4.1 (Manu): this is only "the bar is there". It says nothing
# about a filter still being applied; use filter_kept for that.
filter_bar_present() {
  ui_find --resource-id-regex '^(filter-chip-(state|district|deity)|filter-clear)$'
}

# filter_kept [KIND=LABEL...]: a filter is still applied. The chip-row
# Clear (filter-clear) is only built while a filter is active
# (directory_filter_bar.dart: `final clear = _active ? ...`), so it is
# required; chips alone no longer pass (they are shown with no filter
# too). Each KIND=LABEL whose chip (filter-chip-KIND) is in the dump must
# show exactly LABEL; a chip scrolled off the row is not in the dump and is
# not judged. Sets FILTER_KEPT_WHY on failure.
filter_kept() {
  FILTER_KEPT_WHY=""
  if ! ui_find --resource-id filter-clear; then
    FILTER_KEPT_WHY="filter-clear missing (no filter applied)"
    return 1
  fi
  local kv kind want got judged=0 first_kind=""
  for kv in "$@"; do
    kind="${kv%%=*}" want="${kv#*=}"
    [[ -n "$first_kind" ]] || first_kind="$kind"
    if ui_find --resource-id "filter-chip-${kind}"; then
      got="$(chip_label "$UI_TEXT")"
      if [[ "$got" != "$want" ]]; then
        FILTER_KEPT_WHY="${kind} chip shows '${got}', want '${want}'"
        return 1
      fi
      judged=$((judged + 1))
    else
      echo "filter_kept: ${kind} chip not in the dump (scrolled off); not judged" >&2
    fi
  done
  # Round 4.4.2 (Reviewer/Manu nit): filter-clear alone is not enough when
  # every expected chip is off the row. Scroll the chip row to the first
  # expected chip and judge it.
  if (( $# > 0 && judged == 0 )); then
    want=""
    for kv in "$@"; do [[ "${kv%%=*}" == "$first_kind" ]] && want="${kv#*=}" && break; done
    if ! scroll_chips_until --resource-id "filter-chip-${first_kind}"; then
      FILTER_KEPT_WHY="no expected chip (${first_kind}) on the row after scrolling"
      return 1
    fi
    got="$(chip_label "$UI_TEXT")"
    if [[ "$got" != "$want" ]]; then
      FILTER_KEPT_WHY="${first_kind} chip shows '${got}', want '${want}'"
      return 1
    fi
  fi
  return 0
}

# First real option of the open sheet for KIND (state|district|deity): the
# first filter-option-KIND-* row in document order that is not -any, by its
# exact label (content-desc without the trailing count). Prints the label,
# then its resource-id on a second line.
first_real_option() {
  python3 - "$DUMP" "$1" <<'PY'
import re, sys
s = open(sys.argv[1], encoding="utf-8", errors="replace").read()
kind = sys.argv[2]
prefixes = (f"filter-option-{kind}-",)
if kind == "deity":
    # KAN-198 Most listed rows sit above A-Z and use this id.
    prefixes = (f"filter-deity-top-", f"filter-option-{kind}-")
for node in re.finditer(r"<node [^>]*>", s):
    n = node.group(0)
    rid = re.search(r'resource-id="([^"]*)"', n)
    if not rid:
        continue
    short = rid.group(1)
    matched = False
    for prefix in prefixes:
        if short.startswith(prefix) and not short.endswith("-any"):
            matched = True
            break
    if not matched:
        continue
    desc = re.search(r'content-desc="([^"]*)"', n)
    text = re.search(r' text="([^"]*)"', n)
    label = (desc.group(1) if desc and desc.group(1) else (text.group(1) if text else ""))
    label = " ".join(label.replace("&#10;", " ").split())
    label = re.sub(r"\s+[0-9]+$", "", label)
    if label:
        print(label)
        print(short)
        raise SystemExit(0)
raise SystemExit(1)
PY
}

# Type NAME into filter-sheet-search and tap filter-option-KIND-NAME.
# 0 tapped, 1 no search field (caller scrolls), 2 field used but no row.
sheet_search_pick() {
  local kind="$1" name="$2" regex="$3"
  local id="filter-option-${kind}-${name}" i
  ui_dump || return 1
  if ! ui_find --resource-id filter-sheet-search; then
    return 1
  fi
  ui_tap || return 1
  sleep 0.3
  ui_type "$name" || return 1
  sleep 0.8
  ui_dump || return 1
  local alt
  for alt in "$id" "filter-${kind}-top-${name}"; do
    if ui_find --resource-id "$alt"; then
      if stable_option_tap "$regex" "^$(re_escape "$alt")\$"; then
        return 0
      fi
    fi
  done
  for ((i = 0; i < ${#name}; i++)); do
    adb_shell_capped 8 input keyevent 67 >/dev/null 2>&1 || true
  done
  return 2
}

select_labeled() {
  local regex="$1"
  local _section="${2:-}"
  # Round 4.4: '@first' = the first real option on the opened sheet.
  # Round 4.4.1 (Manu): tap the dumped row itself, no re-seek. The sheet
  # must be at the head of the list (the -any row on screen); if it is
  # not, pull the list down until it is (at most FIRST_TOP_SWIPES).
  if [[ "$regex" == @first ]]; then
    local _k _first _rid _n=0 _h _max
    _k="$(printf '%s' "$_section" | tr '[:upper:]' '[:lower:]')"
    ui_dump || { echo "select_labeled: dump failed on the ${_k} sheet" >&2; return 1; }
    while ! ui_find --resource-id "filter-option-${_k}-any"; do
      if (( _n >= ${FIRST_TOP_SWIPES:-6} )); then
        echo "select_labeled: ${_k} list head (-any) not reached after ${_n} swipes" >&2
        return 1
      fi
      _n=$((_n + 1))
      echo "select_labeled: ${_k} sheet not at the list head; scrolling to the top (${_n})" >&2
      ui_sheet_swipe down 58 "${FIRST_TOP_SWIPE_PCT:-12}" || { echo "select_labeled: swipe failed" >&2; return 1; }
      sleep 0.3
      ui_dump || { echo "select_labeled: dump failed on the ${_k} sheet" >&2; return 1; }
    done
    if ! { read -r _first; read -r _rid; } < <(first_real_option "$_k"); then
      echo "select_labeled: no real ${_k} option on the open sheet" >&2
      return 1
    fi
    echo "select_labeled: first real ${_k} option '${_first}' (tap in place)" >&2
    read -r _ _h < <(ui_screen_size) || return 1
    _max=$((_h * 84 / 100))
    if ! ui_find --resource-id "$_rid" --max-top "$_max"; then
      echo "select_labeled: '${_first}' row is not in the tap band" >&2
      return 1
    fi
    stable_option_tap "^$(re_escape "$_first")( +[0-9]+)?\$" "^$(re_escape "$_rid")\$" || {
      echo "select_labeled: '${_first}' did not hold still for two dumps" >&2
      return 1
    }
    return 0
  fi
  local pass i height min_top max_top prev="" current stuck
  local opt_rx='.'
  case "$_section" in
    STATE|DISTRICT|DEITY) opt_rx="^filter-option-$(printf '%s' "$_section" | tr '[:upper:]' '[:lower:]')-" ;;
  esac
  local name_hint id_rx=""
  name_hint="$(option_name_from_regex "$regex")"
  if [[ -n "$name_hint" ]]; then
    id_rx="filter-option-.*-$(re_escape "$name_hint")$"
    [[ "$opt_rx" != . ]] && id_rx="${opt_rx}$(re_escape "$name_hint")$"
  fi
  local started=0
  local deadline=0
  if ! wait_out_district_loader; then
    return 1
  fi
  local kind
  kind="$(printf '%s' "$_section" | tr '[:upper:]' '[:lower:]')"
  started=$SECONDS
  deadline=$((started + PICKER_GIVEUP_S))
  if [[ "$kind" =~ ^(state|district|deity)$ ]] && (( PICKER_LONG_GIVEUP_S > PICKER_GIVEUP_S )); then
    deadline=$((started + PICKER_LONG_GIVEUP_S))
  fi
  if [[ -n "$name_hint" && "$kind" =~ ^(state|district|deity)$ ]]; then
    # The sheet search jumps to the row. Scrolling a state list one
    # "near" drag at a time is what pushed 29a to 575s and 29d to 566s.
    if sheet_search_pick "$kind" "$name_hint" "$regex"; then
      return 0
    fi
    local seek_rc=0
    # '^Vishnu' (no $) takes the first Vishnu... option; '^Shiva( +N)?$' only Shiva.
    local prefix_flag=""
    [[ "$regex" == *'$' ]] || prefix_flag=--prefix
    # Keep the last 15s for the bounded step scan below when the seek stalls.
    local seek_deadline=$((deadline - 15))
    (( seek_deadline > started + 15 )) || seek_deadline=$deadline
    SEEK_FRESH_DUMP=1 seek_option "$kind" "$name_hint" "$seek_deadline" ${prefix_flag:+"$prefix_flag"} || seek_rc=$?
    # "list stopped moving" (rc 1) on a slow (cold-booted, swiftshader)
    # emulator: 120ms flings were not taken as drags. One more walk with
    # slower flings while the deadline allows (run 41373837994: 17, 29).
    if (( seek_rc == 1 )) && (( SECONDS + 8 < seek_deadline )); then
      echo "select_labeled: retrying the ${kind} walk with ${SEEK_RETRY_FLING_MS:-300}ms flings" >&2
      seek_rc=0
      SEEK_FLING_MS="${SEEK_RETRY_FLING_MS:-300}" seek_option "$kind" "$name_hint" "$seek_deadline" ${prefix_flag:+"$prefix_flag"} || seek_rc=$?
    fi
    if (( seek_rc == 0 )); then
      if [[ ! "$UI_TEXT" =~ $regex ]]; then
        echo "select_labeled: option '${UI_TEXT}' does not match '${regex}'" >&2
        return 1
      fi
      if ! stable_option_tap "$regex" "$opt_rx"; then
        echo "select_labeled: '${UI_TEXT}' did not hold still for two dumps" >&2
        return 1
      fi
      return 0
    fi
    if (( seek_rc == 2 )); then
      echo "select_labeled: '${regex}' is not offered in the ${kind} list" >&2
      return 1
    fi
    if (( seek_rc == 3 )); then
      echo "select_labeled: gave up on '${regex}': the ${kind} list stopped moving" >&2
      return 1
    fi
    if ! python3 "$UI_PY" sheet-band "$DUMP" >/dev/null 2>&1; then
      echo "select_labeled: the filter sheet is not on screen while looking for '${regex}'" >&2
      return 1
    fi
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
        || { ui_find --resource-id-regex "$opt_rx" --text-regex "$regex" --min-top "$min_top" --max-top "$max_top" --prefer upper \
        && [[ ! "$UI_TEXT" =~ ^Show[[:space:]]+[0-9]+[[:space:]]+temples?$ ]]; }; then
        if stable_option_tap "$regex" "$opt_rx"; then
          return 0
        fi
        # Moved between the two dumps: look again on the next dump.
        continue
      fi
      if ui_find --resource-id-regex "$opt_rx" --text-regex "$regex" --min-top "$max_top" --prefer upper \
        && [[ ! "$UI_TEXT" =~ ^Show[[:space:]]+[0-9]+[[:space:]]+temples?$ ]]; then
        ui_sheet_swipe up || {
          echo "select_labeled: swipe failed while looking for '${regex}'" >&2
          return 1
        }
        sleep 0.3
        continue
      fi
      if ui_find --resource-id-regex "$opt_rx" --text-regex "$regex" --max-top "$min_top" --prefer lower; then
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
        # A sheet that closed under the walk leaves nothing to scan; more
        # swipes would only drag the list behind it until the give-up.
        if ! python3 "$UI_PY" sheet-band "$DUMP" >/dev/null 2>&1; then
          echo "select_labeled: the filter sheet is not on screen while looking for '${regex}'" >&2
          return 1
        fi
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

# KAN-198: District with no state opens the State sheet ("Choose a state
# first"). Apply Tamil Nadu so the District sheet that follows is scoped.
finish_choose_state_first() {
  ui_dump || return 1
  if ! ui_find --resource-id filter-choose-state-first; then
    return 0
  fi
  select_labeled '^Tamil Nadu( +[0-9]+)?$' STATE || return 1
  apply_sheet || return 1
  # The District sheet opens next and covers the chip bar. Remember Tamil
  # Nadu so later picks stay scoped to it (flow 29's APPLIED map).
  CHOOSE_STATE_APPLIED="Tamil Nadu"
  if declare -p APPLIED >/dev/null 2>&1; then
    APPLIED[state]="Tamil Nadu"
    unset 'APPLIED[district]'
  fi
}

apply_sheet() {
  local height attempt title_id
  read -r _ height < <(ui_screen_size) || return 1
  title_id=""
  ui_dump || true
  if ui_find --resource-id filter-sheet-title-state; then
    title_id=state
  elif ui_find --resource-id filter-sheet-title-district; then
    title_id=district
  elif ui_find --resource-id filter-sheet-title-deity; then
    title_id=deity
  fi
  for attempt in 1 2; do
    # Choose-a-state-first opens the District sheet itself. A second tap
    # on Show would apply Any district and close it (run 42689905451).
    if [[ "$title_id" == state ]] && ui_dump && ui_find --resource-id filter-sheet-title-district; then
      return 0
    fi
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
    if [[ "$title_id" == state ]] && ui_dump && ui_find --resource-id filter-sheet-title-district; then
      return 0
    fi
    if ! sheet_open; then
      return 0
    fi
  done
  echo "apply_sheet: sheet stayed open after 2 taps" >&2
  return 1
}

chip_exact() {
  local label="$1"
  # A filter-chip-* node with that label first. The bare text regex also
  # matches the app bar title ("Kerala", "Shiva · Tamil Nadu"), which sits
  # above the chip bar (run 41373837994 flow 19 in landscape: the title at
  # x=320 was taken for the chip and scrolled for 8 tries).
  CHIP_LABEL_RX="^$(re_escape "$label")$" find_filter_chip "" "^$(re_escape "$label")$"
}

# scoped_pick KIND: the pick regex for KIND given the chip bar on screen.
# Shiva / Madurai only when the state chip already shows Tamil Nadu (a
# ~32-option list); otherwise the head-of-list all-India picks, so no walk
# crosses the 600-deity list (run 41391038302: every all-India Shiva walk
# gave up at "Ra..Ri" after 45s). State is always Tamil Nadu.
scoped_pick() {
  local kind="$1" tn=0 st=""
  # Round 4.4.9h (run 41872598981, 30s5 district:clear): the chip row
  # scrolls sideways, so an applied chip can be off screen (the deity chip
  # was not in the dump and the clear went back to the all-India head
  # district, which the faceted sheet does not offer). What the flow applied
  # (APPLIED, flow 29) counts first; the chip bar is the fallback.
  local a_state="" a_deity="" a_district=""
  if declare -p APPLIED >/dev/null 2>&1; then
    a_state="${APPLIED[state]:-}"; a_deity="${APPLIED[deity]:-}"; a_district="${APPLIED[district]:-}"
  fi
  ui_dump || true
  if [[ -n "$a_state" ]]; then
    st="$a_state"
  elif [[ -n "${CHOOSE_STATE_APPLIED:-}" ]]; then
    st="$CHOOSE_STATE_APPLIED"
  elif ui_find --resource-id filter-chip-state; then
    st="${UI_TEXT:-}"
  fi
  [[ "$(printf '%s' "$st" | tr -s '[:space:]' ' ')" == *"Tamil Nadu"* ]] && tn=1
  # Round 4.4.9e (run 41781519101): the sheet's counts are faceted
  # (directory_filters.dart census) and a zero-count option is hidden, so
  # with another filter applied a hard-coded all-India head pick may not be
  # offered at all; the pick is then the first real option on the sheet.
  local deity_on=0 dl
  [[ -n "$a_deity" ]] && deity_on=1
  if (( ! deity_on )) && ui_find --resource-id filter-chip-deity; then
    dl="$(printf '%s' "${UI_TEXT:-}" | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//')"
    [[ -n "$dl" && "$dl" != Deity ]] && deity_on=1
  fi
  case "$kind" in
    # Only on what the flow applied (APPLIED, flow 29): flows without it
    # (17) keep the ee7ffbde picks from the visible chips.
    state) if [[ -n "$a_deity" || -n "$a_district" ]]; then echo '@first'; else echo '^Tamil Nadu( +[0-9]+)?$'; fi ;;
    # A district facet hides Shiva (Madurai's four temples are not the
    # all-Tamil-Nadu deity list). Searching Shiva there opened the keyboard
    # and the next fling dismissed the sheet (run 42699042193, 30s2).
    deity) if [[ -n "$a_district" ]]; then echo '@first'; elif (( tn )); then echo "$TN_DEITY_PICK"; else echo "$ALL_INDIA_DEITY_PICK"; fi ;;
    # Round 4.4.9i (Reviewer): any other applied filter (a non-Tamil Nadu
    # state, which the state @first pick can now choose, or a deity) can
    # hide the all-India head district; it is used only with none applied.
    # Shiva in Tamil Nadu does not offer Madurai (run 42699042193, 30s5).
    district) if (( deity_on )); then echo '@first'; elif (( tn )); then echo "$TN_DISTRICT_PICK"; elif [[ -n "$a_state" ]]; then echo '@first'; else echo "$ALL_INDIA_DISTRICT_PICK"; fi ;;
    *) return 1 ;;
  esac
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
    sleep 1
    if [[ "$which" == state ]]; then CHOOSE_STATE_APPLIED=""; fi
    return 0
  fi
  if ui_dump && ui_find --text-regex '^Clear$' --prefer upper; then
    ui_tap
    sleep 1
    if [[ "$which" == state ]]; then CHOOSE_STATE_APPLIED=""; fi
    return 0
  fi
  return 1
}
