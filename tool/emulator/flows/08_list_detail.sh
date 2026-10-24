#!/usr/bin/env bash
# Flow 8. Temple list opens a detail page and back returns to the list.
if ! err="$(reach_browse)"; then
  fail_step browse "${err:-could not open the temple list}"
  return 0
fi
pass_step browse

if ui_wait 15 --resource-id temple-list-search-field || ui_wait 8 --text-contains "Name, city, state"; then
  pass_step search-field
else
  fail_step search-field "search field was not on the list"
fi

if ui_dump && { ui_find --resource-id filter-chip-state || ui_find --text-regex '^State$'; }; then
  pass_step filter-bar
else
  fail_step filter-bar "state filter chip was not on the list"
fi

if ! ui_wait_scrolled 25 --resource-id temple-browse-card --text-contains "Meenakshi Amman Temple"; then
  if ! ui_wait_scrolled 15 --resource-id temple-browse-card --text-contains "Temple"; then
    fail_step open-detail "no temple card was shown"
    return 0
  fi
fi
local_name="$UI_TEXT"
ui_tap
pass_step open-card

if ui_wait_scrolled 20 --text-contains "Listed focus"; then
  pass_step listed-focus
else
  fail_step listed-focus "Listed focus was not on the detail page"
fi

if ui_wait_scrolled 20 --text-contains "How to Reach"; then
  pass_step how-to-reach
else
  fail_step how-to-reach "How to Reach was not on the detail page"
fi

ui_back
sleep 2
if ui_wait 15 --text-regex '^State$' || ui_wait 8 --resource-id filter-chip-state; then
  pass_step back-to-list
else
  fail_step back-to-list "filter bar was not shown after back from ${local_name}"
fi
