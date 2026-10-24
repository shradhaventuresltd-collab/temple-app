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

clear_and_type() {
  local query="$1"
  adb shell input keyevent 123
  local i
  for i in $(seq 1 40); do
    adb shell input keyevent 67
  done
  ui_type "$query"
}

if ! focus_search; then
  fail_step search-field "search field was not shown"
  return 0
fi
pass_step search-field

clear_and_type "Krishna"
if ui_wait_scrolled 25 --text-contains "Guruvayur"; then
  pass_step krishna
else
  fail_step krishna "Guruvayur was not listed for Krishna"
fi

if ! focus_search; then
  fail_step guruvayoorappan "search field went missing"
  return 0
fi
clear_and_type "Guruvayoorappan"
if ui_wait_scrolled 25 --text-contains "Guruvayur"; then
  pass_step guruvayoorappan
else
  fail_step guruvayoorappan "Guruvayur was not listed for Guruvayoorappan"
fi
