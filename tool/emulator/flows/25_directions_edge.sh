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
adb_shell_capped 8 input tap "$UI_CX" "$UI_CY"
adb_shell_capped 8 input tap "$UI_CX" "$UI_CY"
sleep 3
adb_shell_capped 8 dumpsys activity activities | grep -c "maps\|chrome\|Chooser" > /tmp/n; step_shot dir-double
maps_tasks="$(adb_shell_capped 8 dumpsys activity activities 2>/dev/null | grep -c 'com.google.android.apps.maps/' || true)"
echo "directions: Maps activity records after double tap: ${maps_tasks:-0}"
# Maps may show "Update Google Maps to continue" or a location prompt, which
# take their own backs (run 41314245431). Back out until detail, at most 6.
if back_until_detail 6; then
  echo "directions: back on detail after ${BACKS_USED} backs"
  pass_step return-to-detail
else
  fail_step return-to-detail "not on detail after ${BACKS_USED} backs"
fi
adb_shell_capped 8 pm disable-user com.google.android.apps.maps >/dev/null 2>&1
ui_find --resource-id get-directions-button || ui_find --text-regex 'Get Directions' && ui_tap; sleep 3; ui_dump
ui_find --text-contains "irections" && pass_step no-maps-fallback || fail_step no-maps-fallback "nothing happened with Maps disabled"
adb_shell_capped 8 pm enable com.google.android.apps.maps >/dev/null 2>&1
