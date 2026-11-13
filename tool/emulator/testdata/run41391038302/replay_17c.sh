#!/usr/bin/env bash
# Replays flow 17's empty-clear step on drawer_search (run 41391038302 17c):
# the search field already holds "temple". The app (with the
# temple_search.dart:640-641 reverse-prefix bug) still lists 50 temples for
# "templezzzqqq" and shows Clear filters only when nothing matches, i.e.
# for "zzzqqq". input text appends; keyevent 67 deletes one character.
#   replay_17c.sh FLOW_SCRIPT
set -uo pipefail
flow="${1:?flow script}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; root="$(cd "$here/../../../.." && pwd)"
(
  EMULATOR_ARTIFACTS="$(mktemp -d)"
  export EMULATOR_FLOW=17c-entry-matrix-drawer-search EMULATOR_ARTIFACTS EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source "$root/tool/emulator/lib/common.sh"
  FIELD="temple"; CLEARED=0
  sleep() { :; }; step_shot() { :; }; dismiss_blockers() { :; }
  adb_shell_capped() { shift
    case "$1 $2" in
      "input text") FIELD+="${3//%s/ }"; echo "typed '${3}' -> field '${FIELD}'" >&2 ;;
      "input keyevent") [[ "$3" == 67 ]] && FIELD="${FIELD%?}"; [[ "$3" == 66 ]] && echo "enter: query '${FIELD}'" >&2 ;;
    esac; }
  ui_dump() {
    { echo '<hierarchy>'
      echo "<node text=\"${FIELD}\" resource-id=\"temple-list-search-field\" content-desc=\"\" bounds=\"[16,100][304,140]\" />"
      if (( CLEARED )); then echo '<node text="State" resource-id="filter-chip-state" content-desc="State" bounds="[14,181][97,216]" />'
      elif [[ "$FIELD" == zzzqqq ]]; then echo '<node text="" resource-id="filter-empty-clear" content-desc="Clear filters" bounds="[96,300][224,340]" />'
      else echo '<node text="" resource-id="" content-desc="50 temples" bounds="[16,230][200,250]" />'; fi
      echo '</hierarchy>'; } > "$DUMP"; }
  ui_tap() { [[ "${UI_TEXT:-}" == *"Clear filters"* ]] && { CLEARED=1; FIELD=""; }; return 0; }
  # Read by the sourced flow snippet (17_entry_matrix.sh empty-clear block),
  # so exported rather than unused locals.
  export entry=drawer_search kerala_applied=1
  # shellcheck disable=SC1090
  source <(awk '/^  if ui_dump && ui_find --resource-id temple-list-search-field; then$/ { p = 1 } p { print } p && /^  fi$/ { exit }' "$flow")
  echo "--- results"; cat "$RESULTS"
) 2>&1
