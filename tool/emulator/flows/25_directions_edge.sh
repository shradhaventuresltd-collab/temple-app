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
maps_mark="$(logcat_mark)"
adb_shell_capped 8 input tap "$UI_CX" "$UI_CY"
adb_shell_capped 8 input tap "$UI_CX" "$UI_CY"
sleep 3
adb_shell_capped 8 dumpsys activity activities | grep -c "maps\|chrome\|Chooser" > /tmp/n; step_shot dir-double
if back_until_app 6 30; then
  maps_starts="$(maps_start_count "$maps_mark")"
  echo "directions: maps START count=${maps_starts} backs=${BACK_PRESSES}" >&2
  if [[ "${maps_starts:-0}" -ge 1 ]]; then
    pass_step maps-start
  else
    fail_step maps-start "no ActivityTaskManager START for com.google.android.apps.maps after Directions tap"
  fi
  ui_dump || true
  ui_find --resource-id get-directions-button || ui_find --text-regex 'Get Directions' && pass_step return-to-detail || fail_step return-to-detail "app in front after ${BACK_PRESSES} backs but not on detail (maps starts=${maps_starts})"
else
  maps_starts="$(maps_start_count "$maps_mark")"
  echo "directions: maps START count=${maps_starts}" >&2
  fail_step return-to-detail "${PKG} not in foreground after ${BACK_PRESSES} backs/30s (maps starts=${maps_starts}; stuck on Maps first-run?)"
  resume_app
  ui_dump || true
fi
adb_shell_capped 8 pm disable-user com.google.android.apps.maps >/dev/null 2>&1
ui_find --resource-id get-directions-button || ui_find --text-regex 'Get Directions' && ui_tap; sleep 3; ui_dump
ui_find --text-contains "irections" && pass_step no-maps-fallback || fail_step no-maps-fallback "nothing happened with Maps disabled"
adb_shell_capped 8 pm enable com.google.android.apps.maps >/dev/null 2>&1
