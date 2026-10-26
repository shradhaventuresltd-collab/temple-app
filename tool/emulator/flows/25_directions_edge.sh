#!/usr/bin/env bash
# Flow 25 (bughunter). Get Directions double tap (two Maps intents, temple_detail_screen.dart:265),
# a temple with no coords (url null -> snackbar; check copy/button state), return from Maps
# lands back on detail not Home, and no maps app (pm disable Maps).
reach_browse || { fail_step browse "no list"; return 0; }
ui_dump && ui_find --text-regex 'Get Directions|Temple' ; ui_find --resource-id-regex 'temple-card' && ui_tap; sleep 3
directions_found=0
for i in 1 2 3; do
  ui_dump || true
  if ui_find --text-regex 'Get Directions'; then
    directions_found=1
    break
  fi
  ui_fling up || { echo "directions: fling timed out" >&2; break; }
done
if [[ "$directions_found" -ne 1 ]]; then
  echo "directions: Get Directions not in view after 3 flings" >&2
fi
adb shell input tap "$UI_CX" "$UI_CY"; adb shell input tap "$UI_CX" "$UI_CY"; sleep 3
adb shell dumpsys activity activities | grep -c "maps\|chrome\|Chooser" > /tmp/n; step_shot dir-double
ui_back; sleep 1; ui_back; sleep 1; ui_dump
ui_find --text-regex 'Get Directions' && pass_step return-to-detail || fail_step return-to-detail "after 2 backs not on detail (double launch stacked 2 maps?)"
adb shell pm disable-user com.google.android.apps.maps >/dev/null 2>&1
ui_find --text-regex 'Get Directions' && ui_tap; sleep 3; ui_dump
ui_find --text-contains "irections" && pass_step no-maps-fallback || fail_step no-maps-fallback "nothing happened with Maps disabled"
adb shell pm enable com.google.android.apps.maps >/dev/null 2>&1
