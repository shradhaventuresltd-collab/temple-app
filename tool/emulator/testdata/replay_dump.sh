#!/usr/bin/env bash
# Replay select_labeled against one real (or frame-transcribed) uiautomator
# dump of the filter sheet, no device. The "device" shows that dump on every
# ui_dump; swipes do not move it; a tap reports the label under the point.
#   replay_dump.sh DUMP KIND REGEX [--drop NAME]
# Prints: rc=N tapped=LABEL device_s=N err=...
# Run from the repo root; REPO_ROOT picks another checkout (old code).
set -uo pipefail
dump="$1" kind="$2" regex="$3"
drop=""
[[ "${4:-}" == --drop ]] && drop="$5"
root="${REPO_ROOT:-$(pwd)}"
d="$(mktemp -d)"
trap 'rm -rf "$d"' EXIT
python3 - "$dump" "$d/screen.xml" "$drop" <<'PY'
import sys, xml.etree.ElementTree as ET
src, out, drop = sys.argv[1:4]
tree = ET.parse(src)
if drop:
    for parent in list(tree.getroot().iter()):
        for child in list(parent):
            if child.attrib.get("resource-id", "").endswith("-" + drop):
                parent.remove(child)
tree.write(out, encoding="UTF-8", xml_declaration=True)
PY
(
  export EMULATOR_FLOW=replay EMULATOR_ARTIFACTS="$d/art" EMULATOR_PACKAGE=com.shradhaventures.temple
  # shellcheck disable=SC1091
  source "$root/tool/emulator/lib/common.sh"
  STEP_DEADLINE=0
  # shellcheck disable=SC2329
  ui_screen_size() { echo "320 640"; }
  # shellcheck disable=SC2329
  ui_dump() { SECONDS=$((SECONDS + 1)); cp "$d/screen.xml" "$DUMP"; }
  # shellcheck disable=SC2329
  adb_shell_capped() { SECONDS=$((SECONDS + 1)); return 0; }
  # shellcheck disable=SC2329
  ui_tap() {
    python3 - "$d/screen.xml" "$UI_CX" "$UI_CY" > "$d/tapped" <<'PY'
import re, sys, xml.etree.ElementTree as ET
x, y = int(sys.argv[2]), int(sys.argv[3])
for n in ET.parse(sys.argv[1]).getroot().iter():
    m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", n.attrib.get("bounds", ""))
    if m and n.attrib.get("resource-id", "").startswith("filter-option-"):
        x1, y1, x2, y2 = map(int, m.groups())
        if x1 <= x < x2 and y1 <= y < y2:
            print(n.attrib.get("content-desc", ""))
PY
  }
  # shellcheck disable=SC2329
  wait_out_district_loader() { return 0; }
  # shellcheck disable=SC2329
  sleep() { :; }
  rc=0 t0=$SECONDS
  select_labeled "$regex" "$(printf '%s' "$kind" | tr '[:lower:]' '[:upper:]')" 2> "$d/err" || rc=$?
  printf 'rc=%s tapped=%s device_s=%s err=%s\n' "$rc" "$(cat "$d/tapped" 2>/dev/null)" "$((SECONDS - t0))" "$(tr '\n' ' ' < "$d/err")"
)
