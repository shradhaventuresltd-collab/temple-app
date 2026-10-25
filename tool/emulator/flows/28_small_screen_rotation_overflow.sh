#!/usr/bin/env bash
# Flow 28 (bughunter). 320dp-ish screen + font scale 1.3 + landscape on Home,
# list with 3 chips selected, open filter sheet, detail, force-update and policy
# gate. Look for Flutter "RenderFlex overflowed" in logcat and yellow/black stripes.
# Accept the policy at the default size first. Resizing before that leaves the
# gate on screen and nothing else in the flow runs.
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
