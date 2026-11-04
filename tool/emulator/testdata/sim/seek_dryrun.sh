#!/usr/bin/env bash
# Seek dry-run on the sheet simulator (no device), with SEEK_TRACE=1.
#   seek_dryrun.sh SECTION REGEX ORDER SCOPE [OUTDIR]
# e.g. seek_dryrun.sh DEITY '^Shiva( +[0-9]+)?$' deity,state,district,deity all
# Simulated clock: every uiautomator dump costs SIM_DUMP_S (2.3s, the
# cold-booted swiftshader AVD in run 41391038302), every swipe its
# duration + 0.4s adb overhead, every sleep its argument. SECONDS follows
# the simulated clock, so PICKER_*_GIVEUP_S and seek deadlines apply.
# Prints the SEEK_TRACE lines, then a cost breakdown by dump caller.
set -uo pipefail
section="$1" regex="$2" order="$3" scope="$4" out="${5:-$(mktemp -d)}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../../../.." && pwd)"
mkdir -p "$out"
(
  export EMULATOR_FLOW=99-seek-dryrun EMULATOR_ARTIFACTS="$out/art" EMULATOR_PACKAGE=com.example SEEK_TRACE=1
  # shellcheck disable=SC1091
  source "$root/tool/emulator/lib/common.sh"
  sim="$out/sheet.json"; clock="$out/clock"; log="$out/calls.log"
  echo 0 > "$clock"; : > "$log"
  python3 "$here/sheet_sim.py" init "$sim" "$(printf '%s' "$order" | sed 's/,deity$//; s/^\(.*\)$/\1/' | awk -F, '{ o=""; for (i=1;i<=NF;i++) if (!seen[$i]++) o=o (o?",":"") $i; print o }')" "$scope"
  adv() { local t; t="$(python3 -c "print(round($(cat "$clock") + $1, 2))")"; echo "$t" > "$clock"; SECONDS="${t%.*}"; }
  ui_screen_size() { echo "320 640"; }
  sleep() { adv "$1"; }
  step_shot() { :; }
  ui_dump() {
    step_budget_ok || return 1
    adv "${SIM_DUMP_S:-2.3}"
    echo "DUMP ${FUNCNAME[1]}:${BASH_LINENO[0]} t=$(cat "$clock")" >> "$log"
    python3 "$here/sheet_sim.py" dump "$sim" > "$DUMP"
  }
  adb_shell_capped() {
    shift
    if [[ "$1 $2" == "input swipe" ]]; then
      adv "$(python3 -c "print($7/1000 + 0.4)")"
      echo "SWIPE $3 $4 $5 $6 $7 ${FUNCNAME[1]} t=$(cat "$clock")" >> "$log"
      python3 "$here/sheet_sim.py" swipe "$sim" "$3" "$4" "$5" "$6" "$7"
    fi
  }
  ui_tap() { echo "TAP ${UI_TEXT} -> $(python3 "$here/sheet_sim.py" tap "$sim" "$UI_CX" "$UI_CY") t=$(cat "$clock")" >> "$log"; }
  STEP_BUDGET_S=100000
  rc=0; select_labeled "$regex" "$section" || rc=$?
  echo "RESULT rc=${rc} t=$(cat "$clock")s label='${SELECTED_LABEL:-}'"
  echo "dumps total: $(grep -c '^DUMP' "$log")"
  grep '^DUMP' "$log" | awk '{ split($2, a, ":"); c[a[1]]++ } END { for (k in c) printf "  dumps from %-22s %d (%.1fs)\n", k, c[k], c[k]*2.3 }' | sort
  echo "swipes: $(grep -c '^SWIPE' "$log")"
  grep '^TAP' "$log" || true
) 2>&1 | tee "$out/trace.log"
