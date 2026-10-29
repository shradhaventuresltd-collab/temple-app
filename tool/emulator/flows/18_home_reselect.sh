#!/usr/bin/env bash
# Flow 18. "Home" while already on Home, and returning Home from deep stacks.
# Expect the photo collage (top of Home) to be visible afterwards.
collage_top_visible() {
  ui_dump || return 1
  ui_find --content-desc "Discover" && (( UI_Y1 < 500 ))
}
launch_app; accept_policy_if_shown || { fail_step home "home did not appear"; return 0; }
wait_for_home || { fail_step home "home did not appear"; return 0; }
pass_step home
# Run 40698852836: four flings right after Home appeared left Discover at
# y=357; the collage photos were still arriving. Fling until it moves.
scrolled=0
for i in 1 2 3 4 5 6 7 8; do
  ui_fling up; sleep 0.5
  if ! collage_top_visible; then scrolled=1; break; fi
  sleep 1
done
[[ "$scrolled" -eq 1 ]] && pass_step scrolled || fail_step scrolled "could not scroll Home down after 8 flings"
# A: drawer Home tile while on Home
ui_dump && ui_find --content-desc "Open navigation menu" && ui_tap && sleep 1
ui_wait 10 --text-regex '^Home$' && ui_tap && sleep 1
collage_top_visible && pass_step drawer-home-scrolls-top || fail_step drawer-home-scrolls-top "Home stayed scrolled (app_drawer.dart:205)"
# B: list -> detail -> Home icon (popUntil) lands on the top of Home
for i in 1 2 3 4; do ui_fling up; sleep 0.5; done
if open_browse && wait_browse_ready; then
  ui_dump && ui_find --content-desc "Home" && ui_tap && sleep 1
  collage_top_visible && pass_step list-home-icon-top || fail_step list-home-icon-top "returned Home mid-page"
fi
# C: double tap the Home tile must not pop past Home / exit.
# The All Temples search flings this list. Put Home back on screen before
# the wait, or the && skips both taps.
ui_dump && ui_find --content-desc "Open navigation menu" && ui_tap && sleep 1
scroll_drawer_top || true
ui_wait 10 --text-regex '^Home$' && { adb_shell_capped 8 input tap "$UI_CX" "$UI_CY"; adb_shell_capped 8 input tap "$UI_CX" "$UI_CY"; sleep 1; }
wait_for_home && pass_step home-double-tap || fail_step home-double-tap "app left Home"
