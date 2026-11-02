#!/usr/bin/env bash
# Replays flow 24's swipe-pages check on a 5-photo gallery that
# auto-advances every 5s and wraps ((_currentPage + 1) % length,
# temple_detail_screen.dart:200). A fling pages forward and clamps at the
# last page (PageView). Simulated clock: a dump costs DUMP_S (2.3s on the
# cold AVD), a fling 1.0s (200ms swipe + adb; six flings + 0.3s sleeps = 7.8s, "about 8 s" in the triage), sleep N its argument.
#   replay_24.sh FLOW_SCRIPT [START_PAGE] [PHASE_S]
set -uo pipefail
flow="${1:?flow script}" start="${2:-1}" phase="${3:-0}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; root="$(cd "$here/../../../.." && pwd)"
(
  export EMULATOR_FLOW=24-gallery-autoadvance-viewer EMULATOR_ARTIFACTS="$(mktemp -d)" EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source "$root/tool/emulator/lib/common.sh"
  N=5; PAGE="$start"; T="$phase"; NEXT_AUTO=5
  adv() { T="$(python3 -c "print(round($T + $1, 2))")"; while python3 -c "import sys; sys.exit(0 if $T >= $NEXT_AUTO else 1)"; do PAGE=$(((PAGE + 1) % N)); echo "t=${NEXT_AUTO} auto-advance -> page ${PAGE}" >&2; NEXT_AUTO=$((NEXT_AUTO + 5)); done; }
  sleep() { adv "$1"; }; step_shot() { :; }; dismiss_blockers() { :; }
  ui_screen_size() { echo "320 640"; }
  adb_shell_capped() { shift; if [[ "$1 $2" == "input swipe" ]]; then adv "${FLING_S:-1.0}"; (( PAGE < N - 1 )) && PAGE=$((PAGE + 1)); echo "t=${T} fling -> page ${PAGE}" >&2; fi; }
  ui_dump() { adv "${DUMP_S:-2.3}"; printf '<hierarchy><node text="%s / %s" resource-id="" content-desc="" bounds="[0,0][1,1]" /><node text="" resource-id="detail-gallery-%s" content-desc="" bounds="[0,100][320,300]" /></hierarchy>' "$((PAGE + 1))" "$N" "$PAGE" > "$DUMP"; echo "t=${T} dump: page ${PAGE}" >&2; }
  # shellcheck disable=SC1090
  source <(awk '/^ui_dump; page_before=/ { p = 1 } p { print } p && /^fi$/ { exit }' "$flow")
  echo "--- results"; cat "$RESULTS"
) 2>&1
