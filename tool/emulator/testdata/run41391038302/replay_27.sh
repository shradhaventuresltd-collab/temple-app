#!/usr/bin/env bash
# Replays flow 27's recover timeline from run 41391038302 (shard 8 logcat):
# network_on at t=0, ConnectivityService validates at t=VAL_S (3.85s in
# the run), and a Try again tapped once the network is validated loads the
# list LOAD_S later (in the run the retry socket opened ~4s after
# validation and was still in flight when the harness gave up at +16.6s).
# A network flap during a load kills it (ENETUNREACH) -> error page.
#   replay_27.sh FLOW_SCRIPT   (prints the results lines and an event log)
# Simulated clock: sleep N advances it, every dump costs 2s.
set -uo pipefail
flow="${1:?flow script}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../../../.." && pwd)"
VAL_S="${VAL_S:-4}" LOAD_S="${LOAD_S:-12}"
rp="$(mktemp -d)"
(
  export EMULATOR_FLOW=27-offline-cold-start EMULATOR_ARTIFACTS="$rp/art" EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source "$root/tool/emulator/lib/common.sh"
  T=0; NET=off; NET_ON_AT=-1; LOAD_DONE_AT=-1; LOADED=0; SHEET=0
  ev() { echo "t=${T} $*" >> "$rp/events"; }
  adv() { T=$((T + $1)); SECONDS=$T; if (( LOAD_DONE_AT >= 0 && T >= LOAD_DONE_AT )); then LOADED=1; LOAD_DONE_AT=-1; ev "list loaded"; fi; }
  sleep() { adv "${1%.*}"; [[ "${1%.*}" == 0 ]] && adv 1; return 0; }
  clean_install() { :; }; launch_app() { :; }; accept_policy_if_shown() { :; }; wait_for_home() { :; }
  open_browse() { :; }; step_shot() { :; }; dismiss_blockers() { :; }; recover_sheet() { SHEET=0; }
  network_off() { NET=off; if (( LOAD_DONE_AT >= 0 )); then LOAD_DONE_AT=-1; ev "flap killed the in-flight load"; fi; [[ $LOADED == 1 ]] || true; }
  network_on() { NET=on; NET_ON_AT=$T; ev "network on"; }
  validated() { [[ "$NET" == on ]] && (( T - NET_ON_AT >= VAL_S )); }
  adb_shell_capped() { shift; if [[ "$1" == dumpsys ]]; then
      if validated; then echo "  nc{[ Transports: ETHERNET Capabilities: INTERNET&NOT_RESTRICTED&TRUSTED&NOT_VPN&VALIDATED ]}"; else echo "  nc{[ Transports: ETHERNET Capabilities: INTERNET&NOT_RESTRICTED ]}"; fi; fi; }
  ui_dump() { adv 2; if (( LOADED )); then cp "$root/tool/emulator/testdata/run41306793034/browse_no_sheet.xml" "$DUMP"; else cp "$here/offline_could_not_load.xml" "$DUMP"; fi; }
  ui_tap() {
    if [[ "$UI_TEXT" == *"Try again"* || "$UI_TEXT" == Retry ]]; then
      if validated && (( LOAD_DONE_AT < 0 && ! LOADED )); then LOAD_DONE_AT=$((T + LOAD_S)); ev "Try again: retry started, loads at t=${LOAD_DONE_AT}"
      elif ! validated; then ev "Try again before validation: retry fails fast"
      else ev "Try again: joins the in-flight load"; fi
    elif (( LOADED )); then SHEET=1; ev "tapped chip: sheet open"; fi
  }
  sheet_open() { (( SHEET )); }
  # The part of the flow under test starts after the offline steps.
  # shellcheck disable=SC1090
  source <(sed -n '/^network_on/,$p' "$flow")
  echo "--- results"; cat "$RESULTS"
  echo "--- events"; cat "$rp/events"
) 2>&1
