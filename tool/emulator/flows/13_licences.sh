#!/usr/bin/env bash
# Flow 13. Drawer Licences screen shows the district-boundary credit.
launch_app
if ! accept_policy_if_shown || ! wait_for_home; then
  fail_step home "home did not appear"
  return 0
fi
pass_step home

opened=0
if ui_dump && ui_find --content-desc "Open navigation menu"; then
  ui_tap
  opened=1
fi
if [[ "$opened" -eq 0 ]]; then
  read -r width height < <(ui_screen_size)
  adb_shell_capped 8 input swipe 8 $((height / 2)) $((width / 2)) $((height / 2)) 250 || echo "licences: drawer swipe timed out" >&2
  sleep 1
fi

if ui_wait_scrolled 15 --text-regex '^Licences$'; then
  ui_tap
  pass_step open-licences
else
  fail_step open-licences "Licences was not in the drawer"
  return 0
fi

if ui_wait 15 --text-contains "District boundaries"; then
  pass_step district-heading
else
  fail_step district-heading "District boundaries heading was not shown"
fi

if ui_dump && ui_find --text-contains "Bharatlas"; then
  pass_step attribution
else
  fail_step attribution "Bharatlas attribution was not shown"
fi

if ui_dump && ui_find --text-contains "CC BY 4.0"; then
  pass_step licence
else
  fail_step licence "CC BY 4.0 was not shown"
fi

ui_back
sleep 1
if ui_wait 15 --text-contains "Temple Directory"; then
  pass_step back-home
else
  fail_step back-home "back from Licences did not return home"
fi
