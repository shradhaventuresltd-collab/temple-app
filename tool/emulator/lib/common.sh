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

step_shot() {
  local safe
  SHOT_N=$((SHOT_N + 1))
  safe=$(printf '%s' "$1" | tr -c 'A-Za-z0-9_-' '_')
  adb exec-out screencap -p > "${SHOT_DIR}/$(printf '%02d_%s.png' "$SHOT_N" "$safe")" || true
}

pass_step() {
  record_pass "$1"
  step_shot "$1"
}

fail_step() {
  record_fail "$1" "$2"
  step_shot "$1"
  cp -f "$DUMP" "${DUMP_DIR}/${FLOW}_${1}.xml" 2>/dev/null || true
}

ui_screen_size() {
  adb shell wm size | tr -d '\r' | awk '
    /Override size:/ { w=$3; next }
    /Physical size:/ { if (w == "") w=$3 }
    END {
      split(w, a, "x")
      if (a[1] != "" && a[2] != "") print a[1], a[2]
    }
  '
}

ui_dump() {
  local attempt
  for attempt in 1 2 3 4; do
    if adb shell uiautomator dump /sdcard/uidump.xml >/tmp/uidump.err 2>&1; then
      if adb pull /sdcard/uidump.xml "$DUMP" >/dev/null 2>&1 && [[ -s "$DUMP" ]]; then
        return 0
      fi
    fi
    sleep 1
  done
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
  return 1
}

ui_tap() {
  adb shell input tap "$UI_CX" "$UI_CY"
}

ui_back() {
  adb shell input keyevent 4
}

ui_home_key() {
  adb shell input keyevent 3
}

ui_fling() {
  local direction="$1"
  local width height
  read -r width height < <(ui_screen_size)
  if [[ -z "${width:-}" || -z "${height:-}" ]]; then
    return 1
  fi
  local x=$((width / 2))
  if [[ "$direction" == "up" ]]; then
    adb shell input swipe "$x" $((height * 3 / 4)) "$x" $((height / 3)) 280
  else
    adb shell input swipe "$x" $((height / 3)) "$x" $((height * 3 / 4)) 280
  fi
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
  return 1
}

ui_type() {
  local text="$1"
  local encoded
  encoded="$(python3 -c 'import sys; print(sys.argv[1].replace(" ", "%s"))' "$text")"
  adb shell input text "$encoded"
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

install_apk() {
  if [[ -z "${EMULATOR_APK:-}" || ! -f "$EMULATOR_APK" ]]; then
    record_fail "install" "APK missing (${EMULATOR_APK:-unset})"
    return 1
  fi
  local log
  if ! log="$(adb install -r -d "$EMULATOR_APK" 2>&1)"; then
    record_fail "install" "adb install failed: ${log}"
    return 1
  fi
  if [[ "$log" != *"Success"* ]]; then
    record_fail "install" "adb install did not report Success: ${log}"
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
  ui_find --text-regex '^Filters$' && return 0
  ui_find --text-regex '^Show [0-9]+ temples?$'
}

dismiss_sheet_swipe() {
  local width height
  if ! sheet_open; then
    echo "sheet was not open"
    return 1
  fi
  read -r width height < <(ui_screen_size)
  # Fling from the Filters title (inside the sheet) toward the bottom edge.
  adb shell input swipe "$UI_CX" "$UI_Y1" "$UI_CX" $((height * 92 / 100)) 90
  sleep 1
  if sheet_open; then
    adb shell input swipe "$UI_CX" "$UI_Y1" "$UI_CX" $((height * 96 / 100)) 40
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
    echo "sheet was not open"
    return 1
  fi
  # Scrim is above the sheet title. Use a fraction of that title's top.
  target_y=$((UI_Y1 / 4))
  if (( target_y < 12 )); then
    target_y=12
  fi
  adb shell input tap "$UI_CX" "$target_y"
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
  return 1
}

wait_for_home() {
  ui_wait_scrolled 90 --text-contains "Temple Directory"
}

open_browse() {
  local start="$SECONDS"
  while (( SECONDS - start < 40 )); do
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
  # Fall back to the drawer entry.
  if ui_dump && ui_find --content-desc "Open navigation menu"; then
    ui_tap
    sleep 1
    if ui_wait_scrolled 15 --text-regex '^All Temples$'; then
      ui_tap
      return 0
    fi
  fi
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
  adb shell run-as "$PKG" mkdir -p shared_prefs >/tmp/runas.err 2>&1 || {
    record_fail "$step" "run-as failed ($(tr '\n' ' ' < /tmp/runas.err)); APK is not debuggable, so shared_prefs cannot be seeded"
    return 1
  }
  if ! adb shell run-as "$PKG" sh -c 'cat > shared_prefs/FlutterSharedPreferences.xml' < "$file" 2>/tmp/runas.err; then
    record_fail "$step" "could not write FlutterSharedPreferences.xml ($(tr '\n' ' ' < /tmp/runas.err))"
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
      if ! adb shell screenrecord --bit-rate 2000000 --time-limit 180 "/sdcard/${FLOW}_${seg}"; then
        sleep 1
      fi
      n=$((n + 1))
    done
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
