#!/usr/bin/env bash
# Release-mode tester checks on the API 34 google_atd emulator.
# Read-only against prod Firestore. No DEMO_BUILD and no ENABLE_ADMIN_TOOLS.
# In-app frames arrive on TCP 18765 when the test logs PNGREADY.
# SHOTFALLBACK is an adb screencap of the current activity when the
# Flutter plugin capture throws. SHOTADB is only the maps handoff, after
# dumpsys window leaves the app. This script does not run adb root.
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
shotwait = {}
pixels = {}
hashes = {}
mosaic = {}
uia = {}
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
    if "SHOTWAIT " in line:
        rest = line.split("SHOTWAIT ", 1)[1]
        parts = rest.split(" ", 2)
        if len(parts) >= 2:
            shotwait[parts[0]] = (parts[1], parts[2] if len(parts) > 2 else "")
    if "PIXELS " in line:
        rest = line.split("PIXELS ", 1)[1]
        parts = rest.split()
        if parts:
            info = {}
            for item in parts[1:]:
                if "=" in item:
                    key, value = item.split("=", 1)
                    info[key] = value
            pixels[parts[0]] = info
    if "HASH " in line:
        rest = line.split("HASH ", 1)[1]
        parts = rest.split()
        if len(parts) >= 2:
            info = {"md5": parts[1]}
            for item in parts[2:]:
                if "=" in item:
                    key, value = item.split("=", 1)
                    info[key] = value
            hashes[parts[0]] = info
    if "MOSAIC " in line:
        rest = line.split("MOSAIC ", 1)[1]
        name, _, defect = rest.partition(" ")
        mosaic[name] = defect or rest
    if "UIA " in line:
        rest = line.split("UIA ", 1)[1]
        name, _, state = rest.partition(" ")
        uia[name] = state or rest

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

launch_shots = ["02-relaunch-1", "02-relaunch-2", "02-relaunch-3", "02-cold-start"]

def shot_problems(names, require_home=False):
    problems = []
    for name in names:
        status, detail = shotwait.get(name, ("MISSING", "no SHOTWAIT"))
        if status != "PASS":
            problems.append(f"{name} SHOTWAIT {status} {detail}".strip())
        info = pixels.get(name)
        if info is None:
            problems.append(f"{name} screenshot missing")
        else:
            if info.get("frame") == "black":
                problems.append(f"{name} frame black")
            elif require_home and info.get("body") != "home":
                problems.append(f"{name} body={info.get('body', 'missing')} not the Browse home")
        if name not in hashes or hashes[name].get("md5") in ("", "missing"):
            problems.append(f"{name} hash missing")
    return problems

def gate(check_id, names, extra=None, require_home=False):
    status, note = results.get(check_id, ("FAIL", "did not run"))
    problems = []
    if status != "PASS":
        problems.append(note)
    problems.extend(shot_problems(names, require_home=require_home))
    if extra:
        problems.extend(extra)
    if problems:
        results[check_id] = ("FAIL", "; ".join(problems))

gate(1, ["01-accept-after"], require_home=True)

launch_extra = []
stable_home = []
seen_hash = {}
for name in launch_shots:
    digest = hashes.get(name, {}).get("md5", "")
    if digest and digest != "missing":
        seen_hash.setdefault(digest, []).append(name)
for names in seen_hash.values():
    if len(names) < 2:
        continue
    label = "=".join(names)
    home = all(
        pixels.get(name, {}).get("frame") == "content"
        and pixels.get(name, {}).get("body") == "home"
        for name in names
    )
    if home:
        stable_home.append(label)
    else:
        launch_extra.append("byte-identical " + label)
gate(2, launch_shots, extra=launch_extra, require_home=True)
if stable_home:
    status, note = results.get(2, ("FAIL", "did not run"))
    results[2] = (status, note + "; stable pixels " + ", ".join(stable_home))

mosaic_extra = []
for name, defect in mosaic.items():
    if "icon-only=" in defect and "icon-only=0" not in defect:
        mosaic_extra.append(f"{name} {defect}")
    elif defect.startswith("blank") or " blank" in f" {defect}":
        mosaic_extra.append(f"{name} {defect}")
for name in launch_shots + ["03-home-mosaic"]:
    info = pixels.get(name, {})
    if info.get("tile") == "blank":
        mosaic_extra.append(
            f"{name} tile blank std={info.get('tile_std', '?')}"
        )
gate(3, ["03-home-mosaic"], extra=mosaic_extra, require_home=True)
gate(4, ["04-long-name"])
gate(
    5,
    [
        "05-search-minakshi",
        "05-search-tirupathi",
        "05-search-tiruchendur",
        "05-search-sivan",
        "05-search-ee",
        "05-search-th",
        "05-search-it",
    ],
)
gate(6, ["06-airplane"])
gate(7, ["07-janaki-caption"])
gate(8, ["08-get-directions", "08-maps-intent"])
gate(9, launch_shots, require_home=True)
gate(10, ["10-anjengo", "10-akshardham"])
gate(11, ["11-resume"])
gate(12, ["12-kill-switch"])

status13, note13 = results.get(13, ("FAIL", "did not run"))
sw13, detail13 = shotwait.get("13-force-update", ("MISSING", "no SHOTWAIT"))
frame13 = pixels.get("13-force-update", {}).get("frame", "missing")
uia13 = uia.get("13-force-update", "")
uia_found = "FOUND" in uia13
if sw13 != "PASS":
    results[13] = (
        "FAIL",
        f"Update required was not visible before capture ({sw13} {detail13}); {note13}",
    )
elif frame13 == "content" and status13 == "PASS":
    results[13] = ("PASS", f"{note13}; framebuffer=content")
elif frame13 == "content":
    results[13] = ("FAIL", f"{note13}; framebuffer=content")
elif frame13 == "black" and uia_found:
    results[13] = (
        "FAIL",
        "capture timing: Update required is in the widget tree and uiautomator, "
        f"but the framebuffer is black; {note13}",
    )
elif frame13 == "black":
    results[13] = (
        "FAIL",
        "surface not presented: Update required was in the widget tree, "
        "the framebuffer is black, and uiautomator did not see the text; "
        f"{note13}",
    )
else:
    results[13] = ("FAIL", f"frame={frame13}; uia={uia13 or 'missing'}; {note13}")

titles = {
    1: "Accept & continue works with a single tap",
    2: "Force-stop relaunch 3 times plus a cold start shows Browse N Temples",
    3: "Every mosaic tile is a loaded photo or Photo pending, never a grey placeholder",
    4: "A long temple name wraps to 2 lines",
    5: "Search reports top 3; Tirupathi and Sivan ranking is a finding, not a failure",
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
    "A PASS requires the expected text to be visible before the screenshot. Logs alone do not pass.",
    "In-app screenshots are Flutter takeScreenshot frames. The maps intent is an adb screencap.",
    "Check 2 expects Browse 984 Temples and no Firebase or [core/no-app] error.",
    "Check 3 expects every mosaic tile to be a loaded network photo or Photo pending, never a grey placeholder.",
    "Check 5 records the top 3 for each query. Tirupathi and Sivan ranking mismatches are findings, not failures.",
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
if hashes or pixels:
    lines.append("## Screenshots")
    lines.append("")
    names = sorted(set(hashes) | set(pixels) | set(shotwait))
    for name in names:
        info = pixels.get(name, {})
        sw = shotwait.get(name, ("", ""))[0] or "missing"
        digest = hashes.get(name, {}).get("md5", "missing")
        identical = hashes.get(name, {}).get("identical", "?")
        lines.append(
            f"- {name}.png SHOTWAIT {sw} frame={info.get('frame', '?')} "
            f"body={info.get('body', '?')} tile={info.get('tile', '?')} "
            f"tile_std={info.get('tile_std', '?')} hash={digest} identical={identical}"
        )
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
if ! adb forward tcp:18765 tcp:18765; then
  echo "adb forward tcp:18765 failed" >&2
  exit 1
fi
adb forward --list

echo "===== screenshot watcher ====="
PREV_HASH_FILE=/tmp/tester-checks-prev-hash
rm -f "$PREV_HASH_FILE"
record_saved() {
  local name="$1"
  local retries="$2"
  local dest="$OUT/${name}.png"
  if [[ ! -s "$dest" ]]; then
    printf 'HASH %s missing bytes=0 identical=no retries=%s\n' "$name" "$retries" | tee -a "$OUT/events.log"
    return
  fi
  local prev="" hash bytes identical=no pixels
  prev="$(cat "$PREV_HASH_FILE" 2>/dev/null || true)"
  hash="$(md5sum "$dest" | awk '{print $1}')"
  bytes="$(wc -c < "$dest" | tr -d ' ')"
  if [[ -n "$prev" && "$hash" == "$prev" ]]; then
    identical=yes
  fi
  printf '%s\n' "$hash" > "$PREV_HASH_FILE"
  printf 'HASH %s %s bytes=%s identical=%s retries=%s\n' \
    "$name" "$hash" "$bytes" "$identical" "$retries" | tee -a "$OUT/events.log"
  pixels="$(python3 "$ROOT/scripts/ci/classify_tester_png.py" "$dest" "$name" || true)"
  if [[ -n "$pixels" ]]; then
    printf '%s\n' "$pixels" | tee -a "$OUT/events.log"
  fi
  echo "saved $name ($bytes bytes) identical=$identical retries=$retries"
}
fetch_png() {
  local name="$1"
  local length="$2"
  local retries="$3"
  local dest="$OUT/${name}.png"
  if [[ ! "$name" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "skip png name $name"
    return
  fi
  rm -f "$dest"
  if ! python3 - "$dest" "$length" <<'PY'
import os, socket, sys, time
dest, length = sys.argv[1], int(sys.argv[2])
if length <= 0 or length > 12_000_000:
    raise SystemExit(f"bad png length {length}")
sock = None
last = None
for _ in range(50):
    try:
        sock = socket.create_connection(("127.0.0.1", 18765), timeout=2)
        break
    except OSError as error:
        last = error
        time.sleep(0.1)
if sock is None:
    raise SystemExit(f"connect failed: {last}")
sock.settimeout(20)
data = bytearray()
while len(data) < length:
    chunk = sock.recv(min(65536, length - len(data)))
    if not chunk:
        break
    data.extend(chunk)
sock.close()
if len(data) != length:
    raise SystemExit(f"short read {len(data)}/{length}")
part = dest + ".part"
with open(part, "wb") as handle:
    handle.write(data)
os.replace(part, dest)
print(f"received {len(data)} bytes")
PY
  then
    echo "png fetch failed for $name"
    printf 'HASH %s missing bytes=0 identical=no retries=%s\n' "$name" "$retries" | tee -a "$OUT/events.log"
    return
  fi
  if [[ "$name" == "13-force-update" ]]; then
    local uia="MISSING"
    if adb shell uiautomator dump /sdcard/tester-ui.xml >/tmp/tester-uia-dump.txt 2>&1; then
      if adb exec-out cat /sdcard/tester-ui.xml | tr -d '\r' | grep -q 'Update required'; then
        uia="FOUND"
      fi
    fi
    printf 'UIA 13-force-update %s\n' "$uia" | tee -a "$OUT/events.log"
  fi
  record_saved "$name" "$retries"
}
screencap_with_one_retry() {
  local name="$1"
  local dest="$OUT/${name}.png"
  rm -f "$dest"
  local prev="" hash="" pixels="" retries=0
  prev="$(cat "$PREV_HASH_FILE" 2>/dev/null || true)"
  adb exec-out screencap -p > "$dest" || rm -f "$dest"
  if [[ -s "$dest" ]]; then
    hash="$(md5sum "$dest" | awk '{print $1}')"
    pixels="$(python3 "$ROOT/scripts/ci/classify_tester_png.py" "$dest" "$name" || true)"
  fi
  if [[ ! -s "$dest" || "$pixels" == *"frame=black"* || ( -n "$prev" && "$hash" == "$prev" ) ]]; then
    retries=1
    echo "recapture $name once (black or same hash)"
    sleep 0.4
    adb exec-out screencap -p > "$dest" || rm -f "$dest"
  fi
  if [[ "$name" == "13-force-update" ]]; then
    local uia="MISSING"
    if adb shell uiautomator dump /sdcard/tester-ui.xml >/tmp/tester-uia-dump.txt 2>&1; then
      if adb exec-out cat /sdcard/tester-ui.xml | tr -d '\r' | grep -q 'Update required'; then
        uia="FOUND"
      fi
    fi
    printf 'UIA 13-force-update %s\n' "$uia" | tee -a "$OUT/events.log"
  fi
  record_saved "$name" "$retries"
}
capture_adb() {
  local name="$1"
  if [[ ! "$name" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "skip adb shot name $name"
    return
  fi
  local focus="" i
  for i in 1 2 3 4 5 6 7 8; do
    focus="$(adb shell dumpsys window 2>/dev/null | tr -d '\r' | grep -m1 'mCurrentFocus=' || true)"
    echo "focus $name $focus"
    if [[ -n "$focus" && "$focus" != *'com.shradhaventures.temple/'* ]]; then
      break
    fi
    sleep 0.35
  done
  screencap_with_one_retry "$name"
}
capture_fallback() {
  local name="$1"
  if [[ ! "$name" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "skip fallback shot name $name"
    return
  fi
  echo "adb fallback for $name"
  screencap_with_one_retry "$name"
}
stdbuf -oL adb logcat -v brief | stdbuf -oL grep --line-buffered 'TESTER_CHECKS' | while IFS= read -r line; do
  line="${line//$'\r'/}"
  printf '%s\n' "$line" >> "$OUT/events.log"
  case "$line" in
    *"PNGREADY "*)
      rest="${line##*PNGREADY }"
      read -r name length retries <<<"$rest"
      retries="${retries:-0}"
      fetch_png "$name" "$length" "$retries"
      ;;
    *"SHOTFALLBACK "*)
      name="${line##*SHOTFALLBACK }"
      name="${name%% *}"
      capture_fallback "$name"
      ;;
    *"SHOTADB "*)
      name="${line##*SHOTADB }"
      name="${name%% *}"
      capture_adb "$name"
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

run_phase accept 80
run_phase relaunch-1 65
run_phase relaunch-2 65
run_phase relaunch-3 65
run_phase cold 160
run_phase resume 80
run_phase detail 100
run_phase kill-switch 45
run_phase force-update 70

echo "===== airplane ====="
# pm clear is the no-cache cold start. It is not adb root. The logcat
# watcher stays up so the airplane screenshot is not dropped.
adb shell cmd connectivity airplane-mode enable || true
adb shell settings put global airplane_mode_on 1 || true
adb shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true || true
adb shell svc wifi disable || true
adb shell svc data disable || true
adb shell pm clear "$PKG" || true
run_phase airplane 60

kill "$WATCH_PID" || true
echo "===== screenshots ====="
find "$OUT" -maxdepth 1 -type f -printf '%f %s\n' | sort
if [[ "$instrument_failed" -ne 0 ]]; then
  echo "instrumentation failed; see harness notes and crash logs" >&2
  exit 1
fi
