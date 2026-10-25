#!/usr/bin/env bash
# Flow 20. Empty states and back stacks: no-match search, then
# list->drawer->All Temples (stack depth), one back to Home.
# Two backs after the query leave the launcher (screenshot 02_). The IME
# consumes the first, and the second finishes the activity. Hide the
# keyboard only while it is up, and stay on the list to open the drawer.
reach_browse || { fail_step browse "no list"; return 0; }
if ! ui_find --resource-id temple-list-search-field; then
  fail_step empty-search "search field was not on the list"
  return 0
fi
ui_tap
ui_type "zzzzqqq"
adb shell input keyevent 66
sleep 2
if ui_dump && ui_find --text-contains "No temples"; then
  pass_step empty-search
else
  fail_step empty-search "no empty state"
fi
if adb shell dumpsys input_method | grep -Eq 'mInputShown=true|mImeWindowVis=[1-9]'; then
  ui_back
  sleep 1
fi
if ! ui_dump || ! ui_find --content-desc "Open navigation menu"; then
  fail_step drawer-list-replaces "list was not on screen after search"
  return 0
fi
ui_tap
sleep 1
if ! scroll_drawer_until --text-regex '^All Temples'; then
  fail_step drawer-list-replaces "All Temples was not in the drawer"
  return 0
fi
ui_tap
sleep 2
# All Temples from a list returns to Home, so one back shows the collage button.
ui_back
sleep 1
if ui_dump && ui_find --resource-id home-browse-temples; then
  pass_step drawer-list-replaces
else
  fail_step drawer-list-replaces "drawer All Temples pushed a second list"
fi
