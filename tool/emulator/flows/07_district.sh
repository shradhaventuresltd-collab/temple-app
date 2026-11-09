#!/usr/bin/env bash
# Flow 7. The district chip is always on the browse bar. Opening it with
# no state shows Choose a state first; applying Tamil Nadu then opens the
# district sheet. A missing chip fails. The sheet passes only when the
# Any-district row is on screen. The chip's own "District" label is not
# enough, and failing to reach the list fails the flow.
if ! err="$(reach_browse)"; then
  fail_step browse "${err:-could not open the temple list}"
  return 0
fi
pass_step browse

visible=0
if ui_dump && ui_find --resource-id filter-chip-district; then
  visible=1
elif ui_find --text-regex '^(District|All districts)$'; then
  visible=1
fi

if [[ "$visible" -eq 1 ]]; then
  pass_step chip-visible
  ui_tap
  if ! ui_wait 20 --text-regex "$FILTER_SHEET_TITLE_RX"; then
    fail_step sheet-open "sheet title was not State, District, or Deity"
    return 0
  fi
  if ui_find --resource-id filter-choose-state-first; then
    finish_choose_state_first || {
      fail_step sheet-lists-districts "Choose a state first did not apply Tamil Nadu"
      return 0
    }
  fi
  if district_sheet_lists_rows; then
    pass_step sheet-lists-districts
  else
    fail_step sheet-lists-districts "district sheet did not list districts"
  fi
  ui_back || true
else
  fail_step chip-not-visible "district chip was not on the browse bar"
fi
