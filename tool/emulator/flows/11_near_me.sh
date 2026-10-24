#!/usr/bin/env bash
# Flow 11. Temples near me with coarse location granted, then revoked.
launch_app
if ! accept_policy_if_shown; then
  fail_step launch "policy gate or home did not appear"
  return 0
fi
if ! wait_for_home; then
  fail_step launch "home did not appear"
  return 0
fi
pass_step home

push_emulator_geo

if ! adb shell pm grant "$PKG" android.permission.ACCESS_COARSE_LOCATION >/tmp/pm-grant.err 2>&1; then
  fail_step grant "pm grant ACCESS_COARSE_LOCATION failed ($(tr '\n' ' ' < /tmp/pm-grant.err))"
else
  pass_step grant
fi

open_near_me() {
  if ui_wait_scrolled 25 --text-contains "Temples near me"; then
    ui_tap
    return 0
  fi
  return 1
}

dismiss_permission_dialog() {
  local choice="$1"
  ui_dump || return 1
  if ui_find --text-regex "$choice" --package-contains permissioncontroller; then
    ui_tap
    sleep 1
    return 0
  fi
  return 1
}

if ! open_near_me; then
  fail_step open-granted "Temples near me was not shown"
  return 0
fi
if ui_wait 12 --text-contains "Sort by distance"; then
  dismiss_location_consent Continue || true
fi
dismiss_permission_dialog '^(Allow|While using the app)$' || true
dismiss_location_consent Continue || true

granted_sorted=0
granted_start="$SECONDS"
while (( SECONDS - granted_start < 30 )); do
  push_emulator_geo
  if ui_dump && { ui_find --text-contains "Nearest temples" || ui_find --text-regex '[0-9]+(\.[0-9]+)? km$'; }; then
    granted_sorted=1
    break
  fi
  dismiss_location_consent Continue || true
  sleep 2
done
if [[ "$granted_sorted" -eq 1 ]]; then
  pass_step granted-sorted
else
  ui_dump || true
  if ui_find --text-contains "Could not read a location in time"; then
    fail_step granted-sorted "location timed out after pm grant and geo fix"
  else
    fail_step granted-sorted "nearest-temple list was not shown"
  fi
fi

force_stop_app
if ! adb shell pm revoke "$PKG" android.permission.ACCESS_COARSE_LOCATION >/tmp/pm-revoke.err 2>&1; then
  fail_step revoke "pm revoke failed ($(tr '\n' ' ' < /tmp/pm-revoke.err))"
else
  pass_step revoke
fi

launch_app
accept_policy_if_shown || true
if ! wait_for_home; then
  fail_step open-denied "home did not return"
  return 0
fi
if ! open_near_me; then
  fail_step open-denied "Temples near me was not shown"
  return 0
fi
if ui_wait 12 --text-contains "Sort by distance"; then
  dismiss_location_consent Continue || true
fi
dismiss_permission_dialog "^(Don.t allow|Deny)$" || true
if ui_wait 20 --text-contains "Location is off" || ui_wait 8 --text-contains "Pick a state or city"; then
  pass_step denied-fallback
else
  fail_step denied-fallback "denied location did not show the state or city fallback"
fi
