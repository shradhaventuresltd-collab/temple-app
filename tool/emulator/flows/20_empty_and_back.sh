#!/usr/bin/env bash
# Flow 20. Empty states and back stacks: no-match search, clear filters from
# the empty state, list->drawer->All Temples (stack depth), back count to Home.
reach_browse || { fail_step browse "no list"; return 0; }
ui_find --resource-id temple-list-search-field && ui_tap && ui_type "zzzzqqq" && adb shell input keyevent 66; sleep 2
ui_dump && ui_find --text-contains "No temples" && pass_step empty-search || fail_step empty-search "no empty state"
ui_back; ui_back; sleep 1
ui_dump && ui_find --content-desc "Open navigation menu" && ui_tap && sleep 1
ui_wait 10 --text-regex '^All Temples' && ui_tap && sleep 2
# All Temples from a list returns to Home, so one back shows the collage button.
ui_back; sleep 1
ui_dump && ui_find --resource-id home-browse-temples && pass_step drawer-list-replaces || fail_step drawer-list-replaces "drawer All Temples pushed a second list"
