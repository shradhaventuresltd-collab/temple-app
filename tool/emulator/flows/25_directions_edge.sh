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
# The button has to be found and tapped before the foreground package
# means anything. `a || b && c` would still classify when the find missed.
directions_tapped=0
if ui_find --resource-id get-directions-button || ui_find --text-regex 'Get Directions'; then
  ui_tap
  directions_tapped=1
fi
if [[ "$directions_tapped" -ne 1 ]]; then
  fail_step no-maps-fallback "Get Directions was not on screen to tap"
else
  sleep 3
  ui_dump || true
  # With Maps disabled the app opens the same URL in a browser (run
  # 40698852836: Chrome first-run page). That is the fallback working.
  # The Get Directions button is still on screen when the tap did nothing,
  # so "irections" is not a pass. In-app passes only for the snackbar
  # "Couldn't open directions on this device."
  fallback_fg="$(foreground_pkg)"
  echo "fallback_fg=${fallback_fg}" >&2
  case "$(classify_fallback_pkg "$fallback_fg" "$(https_view_handler)" "$(home_handler)")" in
    browser)
      pass_step no-maps-fallback
      back_until_app 6 30 || resume_app
      ;;
    launcher)
      fail_step no-maps-fallback "fallback_fg=${fallback_fg} is a launcher, not a browser"
      ;;
    permission)
      fail_step no-maps-fallback "fallback_fg=${fallback_fg} is a permission controller, not a browser"
      ;;
    *)
      message_visible=0
      if [[ "$fallback_fg" == "$PKG" ]] && ui_find --text-contains "Couldn't open directions"; then
        message_visible=1
      fi
      if [[ "$(no_maps_in_app_result "$fallback_fg" "$message_visible")" == pass ]]; then
        pass_step no-maps-fallback
      else
        fail_step no-maps-fallback "fallback_fg=${fallback_fg} is not a browser (in-app pass needs Couldn't open directions)"
      fi
      ;;
  esac
fi
adb_shell_capped 8 pm enable com.google.android.apps.maps >/dev/null 2>&1
