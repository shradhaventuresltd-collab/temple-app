#!/usr/bin/env bash
# Flow 7. Report whether the district chip is on the browse bar.
# Either result is a pass. Failing to reach the list is not.
if ! err="$(reach_browse)"; then
  fail_step browse "${err:-could not open the temple list}"
  return 0
fi
pass_step browse

visible=0
if ui_dump && ui_find --resource-id filter-chip-district; then
  visible=1
elif ui_find --text-regex '^All districts$'; then
  visible=1
fi

if [[ "$visible" -eq 1 ]]; then
  pass_step chip-visible
  ui_tap
  if ui_wait 25 --text-regex '^DISTRICT$'; then
    pass_step sheet-lists-districts
  else
    pass_step sheet-without-district-names
  fi
  ui_back || true
else
  pass_step chip-not-visible
fi
