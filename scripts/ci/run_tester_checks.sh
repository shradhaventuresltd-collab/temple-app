#!/usr/bin/env bash
# Release-mode tester checks on the API 34 google_atd emulator.
# Read-only against prod Firestore. No DEMO_BUILD and no ENABLE_ADMIN_TOOLS.
# Screenshots are host screencaps taken when the integration test logs SHOT.
set -uo pipefail

PKG=com.shradhaventures.temple
ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
OUT="$ROOT/tester-checks-screenshots"
APK="${TESTER_CHECKS_APK:-$ROOT/build/app/outputs/flutter-apk/app-release.apk}"
TEST_APK="${TESTER_CHECKS_TEST_APK:-$ROOT/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk}"
mkdir -p "$OUT"
: > "$OUT/events.log"

write_summary() {
  python3 - "$OUT/events.log" "$OUT/summary.md" <<'PY'
import os, pathlib, sys
events = pathlib.Path(sys.argv[1]).read_text(errors="replace").splitlines()
out = pathlib.Path(sys.argv[2])

results = {}
launches = []
updates = []
logcats = []
searches = []
harness = []
phases = []
for raw in events:
    line = raw.replace("\r", "").strip()
    if "RESULT " in line:
        rest = line.split("RESULT ", 1)[1]
        parts = rest.split(" ", 2)
        if len(parts) >= 2 and parts[0].isdigit():
            note = parts[2] if len(parts) > 2 else ""
            results[int(parts[0])] = (parts[1], note)
    if "LAUNCH " in line:
        launches.append(line.split("LAUNCH ", 1)[1])
    if "UPDATE " in line:
        updates.append(line.split("UPDATE ", 1)[1])
    if "LOGCAT " in line:
        logcats.append(line.split("LOGCAT ", 1)[1])
    if "SEARCH " in line:
        searches.append(line.split("SEARCH ", 1)[1])
    if "HARNESS " in line:
        harness.append(line.split("HARNESS ", 1)[1])
    if "PHASE " in line:
        phases.append(line.split("PHASE ", 1)[1])

wanted = ("relaunch-1", "relaunch-2", "relaunch-3", "cold")
by_phase = {}
for row in launches:
    phase = row.split(" ", 1)[0]
    by_phase[phase] = row
log_bad = []
seen_log = set()
for row in logcats:
    if row in seen_log:
        continue
    seen_log.add(row)
    if "FIREBASE_ERROR" in row and any(name in row for name in wanted):
        log_bad.append(row)
searches = list(dict.fromkeys(searches))
phases = list(dict.fromkeys(phases))
harness = list(dict.fromkeys(harness))
launch_pass = all(
    by_phase.get(name, "").startswith(f"{name} PASS") for name in wanted
)
if launch_pass and not log_bad:
    results[2] = ("PASS", "; ".join(by_phase[name] for name in wanted))
else:
    notes = [by_phase.get(name, f"{name} did not run") for name in wanted]
    if log_bad:
        notes.extend(log_bad)
    results[2] = ("FAIL", "; ".join(notes))

by_update = {}
for row in updates:
    phase = row.split(" ", 1)[0]
    by_update[phase] = row
update_pass = all(
    by_update.get(name, "").startswith(f"{name} PASS") for name in wanted
)
if update_pass:
    results[9] = ("PASS", "; ".join(by_update[name] for name in wanted))
else:
    results[9] = (
        "FAIL",
        "; ".join(by_update.get(name, f"{name} did not run") for name in wanted),
    )

titles = {
    1: "Accept & continue works with a single tap",
    2: "Force-stop relaunch 3 times plus a cold start shows Browse N Temples",
    3: "Home mosaic shows Photo pending tiles, not grey ones",
    4: "A long temple name wraps to 2 lines",
    5: "Search finds Minakshi, Tirupathi, Tiruchendur, and Sivan, and records ee/th/it",
    6: "Airplane-mode cold start does not show maintenance",
    7: "Janaki Temple Sitamarhi caption says Punaura Dham",
    8: "Get Directions is visible and launches a maps intent",
    9: "Default Remote Config shows no force-update or soft-update prompt",
    10: "No picsum placeholder; Anjengo and Akshardham are a real photo or Photo pending",
    11: "Background then resume keeps the list",
    12: "Test-only kill switch shows the maintenance screen",
    13: "Test-only force-update blocks launch",
}

lines = [
    "# Tester checks",
    "",
    "Release APK, prod Firestore, no writes, no DEMO_BUILD, no ENABLE_ADMIN_TOOLS.",
    "Check 2 expects Browse 984 Temples and no Firebase or [core/no-app] error.",
    "Check 7 runs because #77 is in main 63da3fc.",
    "Check 9 expects no force-update screen and no soft-update nudge on the three relaunches and the cold start.",
    "Check 10 expects no picsum.photos URL and no other placeholder image. Anjengo and Akshardham may be Photo pending.",
    "Check 11 backgrounds the list and resumes. The list must stay populated.",
    "Checks 12 and 13 inject AppConfig in the tester process only. Prod Remote Config is not written.",
    "",
]
profile = os.environ.get("TESTER_CHECKS_PROFILE", "").strip()
wm = os.environ.get("TESTER_CHECKS_WM_SIZE", "").strip()
if profile or wm:
    detail = profile or "default"
    if wm:
        detail += f", wm size {wm}"
    lines.append(f"Emulator profile: {detail}")
    lines.append("")
if phases:
    lines.append("Phases seen: " + ", ".join(phases))
    lines.append("")
lines.append("| Check | Result | Notes |")
lines.append("| --- | --- | --- |")
for i in range(1, 14):
    status, note = results.get(i, ("FAIL", "did not run"))
    if status not in ("PASS", "FAIL", "N/A", "UNTESTED"):
        status = "FAIL"
    note = note.replace("|", "/")
    lines.append(f"| {i}. {titles[i]} | {status} | {note} |")
lines.append("")
if searches:
    lines.append("## Search log")
    lines.append("")
    for row in searches:
        lines.append(f"- {row}")
    lines.append("")
if harness:
    lines.append("## Harness")
    lines.append("")
    for row in harness:
        lines.append(f"- {row}")
    lines.append("")
out.write_text("\n".join(lines) + "\n")
print(out.read_text())
PY
}

trap 'write_summary || true' EXIT

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

adb shell input keyevent KEYCODE_WAKEUP || true
adb shell wm dismiss-keyguard || true
if [[ -n "${TESTER_CHECKS_WM_SIZE:-}" ]]; then
  adb shell wm size "$TESTER_CHECKS_WM_SIZE"
  adb shell wm density "${TESTER_CHECKS_WM_DENSITY:-480}"
  echo "wm size $(adb shell wm size | tr -d '\r') density $(adb shell wm density | tr -d '\r')"
fi
adb shell settings put global window_animation_scale 0 || true
adb shell settings put global transition_animation_scale 0 || true
adb shell settings put global animator_duration_scale 0 || true
adb logcat -G 16M || true

if [[ ! -f "$APK" ]]; then
  echo "error: release apk missing at $APK" >&2
  exit 1
fi
if [[ ! -f "$TEST_APK" ]]; then
  echo "error: androidTest apk missing at $TEST_APK" >&2
  exit 1
fi

echo "===== install release apk ====="
adb uninstall "$PKG" || true
adb install -r "$APK"
adb install -r "$TEST_APK"
adb shell pm path "$PKG"
bash "$ROOT/scripts/ci/install_https_handoff.sh"

echo "===== screenshot watcher ====="
stdbuf -oL adb logcat -v brief | stdbuf -oL grep --line-buffered 'TESTER_CHECKS' | while IFS= read -r line; do
  line="${line//$'\r'/}"
  printf '%s\n' "$line" >> "$OUT/events.log"
  case "$line" in
    *"SHOT "*)
      name="${line##*SHOT }"
      name="${name%% *}"
      if [[ ! "$name" =~ ^[A-Za-z0-9._-]+$ ]]; then
        echo "skip shot name $name"
        continue
      fi
      if adb exec-out screencap -p > "$OUT/${name}.png"; then
        echo "captured $name ($(wc -c < "$OUT/${name}.png") bytes)"
      else
        echo "screencap failed for $name"
      fi
      ;;
  esac
done &
WATCH_PID=$!

firebase_log() {
  local phase="$1"
  if adb logcat -d -v brief | grep -E 'core/no-app|No Firebase App' | grep -v TESTER_CHECKS | grep -q .; then
    printf 'LOGCAT %s FIREBASE_ERROR\n' "$phase" >> "$OUT/events.log"
    echo "logcat firebase error during $phase"
  else
    printf 'LOGCAT %s CLEAN\n' "$phase" >> "$OUT/events.log"
    echo "logcat clean during $phase"
  fi
}

instrument_failed=0

# FlutterTestRunner waits on the integration channel after the Dart test
# returns. DONE is the end of the phase. Force-stop then, and do not treat
# that exit as a crash.
phase_finished() {
  local phase="$1"
  local waited="$2"
  if [[ -f "$OUT/events.log" ]] && grep -q "TESTER_CHECKS DONE ${phase}" "$OUT/events.log"; then
    return 0
  fi
  # The watcher usually lands the line first. Dumping logcat every second
  # stalls the host, so only fall back every few seconds.
  if (( waited % 3 == 2 )) && adb logcat -d -v brief 2>/dev/null | grep -q "TESTER_CHECKS DONE ${phase}"; then
    return 0
  fi
  return 1
}

run_phase() {
  local phase="$1"
  local seconds="$2"
  echo "===== phase $phase (${seconds}s) ====="
  adb shell am force-stop "$PKG" || true
  adb shell am force-stop com.shradhaventures.handoff || true
  adb logcat -c || true
  local instrument_log="/tmp/tester-instrument-${phase}.txt"
  : > "$instrument_log"
  set +e
  timeout --kill-after=20s "${seconds}" adb shell am instrument -w \
    -e phase "$phase" \
    "${PKG}.test/${PKG}.TesterChecksRunner" >"$instrument_log" 2>&1 &
  local inst_pid=$!
  local done=0
  local waited=0
  while kill -0 "$inst_pid" 2>/dev/null; do
    if phase_finished "$phase" "$waited"; then
      done=1
      sleep 1
      adb shell am force-stop "$PKG" || true
      sleep 2
      if kill -0 "$inst_pid" 2>/dev/null; then
        kill "$inst_pid" 2>/dev/null || true
      fi
      break
    fi
    if (( waited >= seconds )); then
      break
    fi
    sleep 1
    waited=$((waited + 1))
  done
  wait "$inst_pid"
  local rc=$?
  set -e
  local out
  out="$(cat "$instrument_log")"
  printf '%s\n' "$out"
  echo "instrument $phase exit $rc done=$done"
  if grep -q 'Permission Denial' <<<"$out"; then
    instrument_failed=1
    printf 'HARNESS %s signature mismatch\n' "$phase" >> "$OUT/events.log"
  fi
  if grep -q 'Process crashed' <<<"$out"; then
    if [[ "$done" -eq 1 ]]; then
      echo "stopped $phase after DONE"
    else
      instrument_failed=1
      printf 'HARNESS %s process crashed\n' "$phase" >> "$OUT/events.log"
      {
        echo "===== crash buffer $phase ====="
        adb logcat -b crash -d -v time || true
        echo "===== logcat tail $phase ====="
        adb logcat -d -v time -t 400 || true
      } > "$OUT/crash-$phase.log" || true
    fi
  fi
  firebase_log "$phase"
  # Keep the lines if the watcher was slow. Release logs use the flutter tag.
  adb logcat -d -v brief | grep 'TESTER_CHECKS' >> "$OUT/events.log" || true
}

run_phase accept 70
run_phase relaunch-1 50
run_phase relaunch-2 50
run_phase relaunch-3 50
run_phase cold 220
run_phase kill-switch 50
run_phase force-update 50

echo "===== airplane ====="
adb shell cmd connectivity airplane-mode enable || true
adb shell settings put global airplane_mode_on 1 || true
adb shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true || true
adb shell svc wifi disable || true
adb shell svc data disable || true
adb root || true
adb wait-for-device
adb shell iptables -I OUTPUT -j DROP || true
adb shell pm clear "$PKG" || true
# adb root restarts adbd and drops the logcat stream.
kill "$WATCH_PID" || true
stdbuf -oL adb logcat -v brief | stdbuf -oL grep --line-buffered 'TESTER_CHECKS' | while IFS= read -r line; do
  line="${line//$'\r'/}"
  printf '%s\n' "$line" >> "$OUT/events.log"
  case "$line" in
    *"SHOT "*)
      name="${line##*SHOT }"
      name="${name%% *}"
      if [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]]; then
        adb exec-out screencap -p > "$OUT/${name}.png" || true
        echo "captured $name"
      fi
      ;;
  esac
done &
WATCH_PID=$!
run_phase airplane 60

kill "$WATCH_PID" || true
echo "===== screenshots ====="
find "$OUT" -maxdepth 1 -type f -printf '%f %s\n' | sort
if [[ "$instrument_failed" -ne 0 ]]; then
  echo "instrumentation failed; see harness notes and crash logs" >&2
  exit 1
fi
