#!/usr/bin/env bash
# Flow 5. Krishna and the Guruvayoorappan alias both reach Guruvayur.
if ! err="$(reach_browse)"; then
  fail_step browse "${err:-could not open the temple list}"
  return 0
fi
pass_step browse

focus_search() {
  if ui_wait 15 --resource-id temple-list-search-field; then
    ui_tap
    return 0
  fi
  if ui_wait 8 --text-contains "Name, city, state"; then
    ui_tap
    return 0
  fi
  return 1
}

if ! focus_search; then
  fail_step search-field "search field was not shown"
  return 0
fi
pass_step search-field

if ! ui_replace_field_text "Krishna"; then
  fail_step krishna "search field text was '${UI_FIELD_ACTUAL:-unreadable}', expected Krishna"
elif ui_wait_scrolled 25 --resource-id temple-browse-card --text-contains "Guruvayur"; then
  pass_step krishna
else
  fail_step krishna "Guruvayur was not listed for Krishna"
fi

if ! ui_replace_field_text "Guruvayoorappan"; then
  fail_step guruvayoorappan "search field text was '${UI_FIELD_ACTUAL:-unreadable}', expected Guruvayoorappan"
elif ui_wait_scrolled 25 --resource-id temple-browse-card --text-contains "Guruvayur"; then
  pass_step guruvayoorappan
else
  fail_step guruvayoorappan "Guruvayur was not listed for Guruvayoorappan"
fi
