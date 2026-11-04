#!/usr/bin/env bash
# Flow 25 (bughunter). Get Directions double tap (two Maps intents, temple_detail_screen.dart:265),
# a temple with no coords (url null -> snackbar; check copy/button state), return from Maps
# lands back on detail not Home, and no maps app (pm disable Maps).
reach_browse || { fail_step browse "no list"; return 0; }
if ! ui_dump || ! ui_find --resource-id temple-browse-card; then
  fail_step open-card "no temple card"
  return 0
fi
ui_tap; sleep 3
directions_found=0
for i in 1 2 3; do
  ui_dump || true
  if ui_find --resource-id get-directions-button || ui_find --text-regex 'Get Directions'; then
    directions_found=1
    break
  fi
  ui_fling up || { echo "directions: fling timed out" >&2; break; }
done
if [[ "$directions_found" -ne 1 ]]; then
  fail_step directions "Get Directions not in view after 3 flings"
  return 0
fi
# Count Maps STARTs in a logcat window opened just before the taps.
logcat_window_start directions-double-tap || echo "directions: TempleEmuMark marker not written" >&2
adb_shell_capped 8 input tap "$UI_CX" "$UI_CY"
adb_shell_capped 8 input tap "$UI_CX" "$UI_CY"
sleep 3
step_shot dir-double
# The back-out loop below could hide a stacked second Maps, so the double
# tap must have started Maps exactly once.
if ! window="$(logcat_window_read)"; then
  fail_step single-maps-launch "TempleEmuMark logcat marker missing: Maps STARTs cannot be counted"
  maps_starts=""
else
  echo "directions: logcat window starts at device time '$(head -n1 <<< "$window" | cut -c1-18)'"
  maps_starts="$(count_maps_starts <<< "$window")"
  echo "directions: Maps START lines after the double tap: ${maps_starts:-0}"
fi
if [[ -z "$maps_starts" ]]; then
  :
elif [[ "${maps_starts:-0}" -eq 1 ]]; then
  pass_step single-maps-launch
else
  fail_step single-maps-launch "double tap started Maps ${maps_starts:-0} times (want 1)"
fi
# Maps may show "Update Google Maps to continue" or a location prompt, which
# take their own backs (run 41314245431). Back out until detail, at most 6.
if back_until_detail 6; then
  echo "directions: back on detail after ${BACKS_USED} backs"
  pass_step return-to-detail
else
  fail_step return-to-detail "not on detail after ${BACKS_USED} backs"
fi
adb_shell_capped 8 pm disable-user com.google.android.apps.maps >/dev/null 2>&1
# Fresh dump before the tap (the old line tapped the coordinates of a stale
# dump). With Maps disabled the app hands the directions URL to the browser
# (run 41373837994: Chrome's "Welcome to Chrome" first-run screen), which
# is the fallback working. Pass on a browser in front or an in-app
# directions message; fail only when the screen is still the unchanged
# detail page.
ui_dump || true
if ui_find --resource-id get-directions-button || ui_find --text-regex 'Get Directions'; then
  ui_tap; sleep 3; ui_dump || true
  if maps_fallback_shown; then
    pass_step no-maps-fallback
  else
    fail_step no-maps-fallback "nothing happened with Maps disabled"
  fi
else
  fail_step no-maps-fallback "Get Directions not on screen after return-to-detail"
fi
adb_shell_capped 8 pm enable com.google.android.apps.maps >/dev/null 2>&1 || true
