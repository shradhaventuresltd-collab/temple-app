#!/usr/bin/env bash
# Flow 23 (bughunter). Near me: GPS off, denied-forever -> Open settings -> grant ->
# return. near_me_session.dart:80-110 has no app-resume recheck (no
# didChangeAppLifecycleState in temples_near_me_screen.dart), so the screen may
# stay on "denied"/"location off" after the user fixes it. Also retry spam (_busy).
launch_app; accept_policy_if_shown; wait_for_home || { fail_step home "no home"; return 0; }
adb_shell_capped 8 pm revoke "$PKG" android.permission.ACCESS_COARSE_LOCATION >/dev/null 2>&1 || true
adb_shell_capped 8 pm revoke "$PKG" android.permission.ACCESS_FINE_LOCATION >/dev/null 2>&1 || true
adb_shell_capped 8 settings put secure location_mode 0
open_nm() {
  local i
  for i in 1 2 3 4 5 6; do
    ui_dump || true
    ui_find --text-regex 'near me' && { ui_tap; sleep 2; return 0; }
    ui_fling up || { echo "open_nm: fling timed out" >&2; return 1; }
  done
  echo "open_nm: gave up after 6 flings" >&2
  return 1
}
open_nm || { fail_step open "no near-me entry"; return 0; }
ui_dump; ui_find --text-contains "location" && pass_step service-off-copy || fail_step service-off-copy "no location-off state"
adb_shell_capped 8 settings put secure location_mode 3; push_emulator_geo; sleep 1
resume_app; ui_home_key; sleep 1; resume_app; sleep 3
ui_dump; ui_find --text-contains "Allow" || ui_find --text-regex 'km' && pass_step resume-recheck || fail_step resume-recheck "stuck on location-off after enabling (no resume recheck)"
# deny twice -> deniedForever
for i in 1 2; do ui_dump; ui_find --text-regex "Don.t allow|Deny" && ui_tap; sleep 1; ui_find --text-regex 'Try again|Allow location' && ui_tap; sleep 2; done
ui_dump; ui_find --text-contains "settings" && pass_step denied-forever || fail_step denied-forever "no settings CTA"
adb_shell_capped 8 pm grant "$PKG" android.permission.ACCESS_COARSE_LOCATION; push_emulator_geo
ui_home_key; sleep 1; resume_app; sleep 4
ui_dump; ui_find --text-regex '[0-9.]+ km' && pass_step granted-in-settings || fail_step granted-in-settings "list not shown after granting in Settings"
# retry button spam
ui_find --text-regex 'Try again|Refresh' && for i in 1 2 3 4 5; do adb_shell_capped 8 input tap "$UI_CX" "$UI_CY" || { echo "retry-spam: tap timed out" >&2; break; }; done; sleep 12
ui_dump; ui_find --text-contains "Locating" && fail_step retry-spam "stuck locating" || pass_step retry-spam
# rotate mid-locating
adb_shell_capped 8 settings put system accelerometer_rotation 0
adb_shell_capped 8 settings put system user_rotation 1
sleep 3
ui_dump; pass_step rotated
adb_shell_capped 8 settings put system user_rotation 0
