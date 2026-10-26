#!/usr/bin/env bash
# Flow 28 (bughunter). Accept the policy at the default size via reach_browse,
# then shrink to 720x1280 (about 320dp) with font scale 1.3. If that resize
# brings the policy gate back, accept it again. A gate with no accept control
# fails the step. Reopen the list if needed, open the filter sheet, rotate to
# landscape, and require the Apply button on screen. Fail when logcat contains
# "RenderFlex overflowed". Screenshots use screencap and wait out a black
# frame after the resize. Reset size, density, and font scale at the end.
reach_browse || { fail_step browse "no list"; }
adb shell wm size 720x1280; adb shell wm density 360; adb shell settings put system font_scale 1.3
sleep 2
# The resize can bring the policy gate back. Reuse the shared accept path.
# A gate with no accept control fails the step instead of continuing.
ui_dump || true
if ui_find --resource-id policy-accept-button || ui_find --text-contains "Accept & continue"; then
  accept_policy_if_shown || fail_step policy "policy was not accepted after resize"
elif ui_find --text-contains "Temple Directory India" \
  && ! ui_find --resource-id home-browse-temples \
  && ! ui_find --resource-id filter-chip-state; then
  fail_step policy "no accept button after resize"
fi
if ! ui_dump || ! ui_find --resource-id filter-chip-state; then
  open_browse || true
  wait_browse_ready || fail_step browse "list did not return after resize"
fi
step_shot small-list
ui_dump && ui_find --resource-id filter-chip-state && ui_tap; sleep 1; step_shot small-sheet
adb shell settings put system accelerometer_rotation 0; adb shell settings put system user_rotation 1; sleep 3
step_shot land-sheet; ui_dump; ui_find --text-regex '^Show [0-9]+ temples?$' && pass_step land-apply-visible || fail_step land-apply-visible "Apply button off-screen in landscape sheet"
ui_back; adb shell settings put system user_rotation 0; sleep 2
adb logcat -d | grep -i "overflowed by" && fail_step overflow "RenderFlex overflow logged" || pass_step overflow
adb shell wm size reset; adb shell wm density reset; adb shell settings put system font_scale 1.0
