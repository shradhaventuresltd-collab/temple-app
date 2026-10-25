#!/usr/bin/env bash
# Flow 26 (bughunter). Drawer stacking: list -> drawer All Temples repeated
# pushes duplicate lists (back count grows); double-tap drawer items; back from
# Home with drawer open closes drawer not app; drawer search submit twice.
reach_browse || { fail_step browse "no list"; return 0; }
for i in 1 2 3; do
  ui_dump && ui_find --content-desc "Open navigation menu" && ui_tap; sleep 1
  ui_wait_scrolled 10 --text-regex '^All Temples' && { adb shell input tap "$UI_CX" "$UI_CY"; adb shell input tap "$UI_CX" "$UI_CY"; }; sleep 2
done
n=0; while (( n < 8 )); do ui_dump; ui_find --resource-id home-browse-temples && break; ui_back; sleep 1; n=$((n+1)); done
(( n <= 2 )) && pass_step back-depth || fail_step back-depth "needed $n backs to reach Home (duplicate list routes)"
ui_dump && ui_find --content-desc "Open navigation menu" && ui_tap; sleep 1; ui_back; sleep 1
wait_for_home && pass_step back-closes-drawer || fail_step back-closes-drawer "back with drawer open left Home"
ui_back; sleep 2; adb shell dumpsys window | grep -q "mCurrentFocus.*$PKG" && xfail_step back-exits "no exit confirm" || pass_step back-exits
