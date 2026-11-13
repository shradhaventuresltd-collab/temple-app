#!/usr/bin/env bash
# Flow 13. Drawer Licences screen shows the district-boundary credit.

# Open Licences from the drawer. A tap that leaves the drawer up is not a pass.
# Mirrors open_browse's All Temples path: drawer-local scroll, then one
# top-of-drawer retry. The screen is open only when "District boundaries"
# appears. Each wait is bounded (8 drawer swipes, then ui_wait 15).
open_licences_screen() {
  local attempt
  for attempt in 1 2; do
    if ! scroll_drawer_until --text-regex '^Licences$'; then
      scroll_drawer_top || true
      if ! ui_dump || ! ui_find --text-regex '^Licences$'; then
        return 1
      fi
    fi
    ui_tap || return 1
    if ui_wait 15 --text-contains "District boundaries"; then
      return 0
    fi
    if (( attempt == 2 )); then
      return 1
    fi
    # One retry after a short settle. absorbDrawerDrag can swallow the first tap.
    sleep 1
  done
  return 1
}

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

if open_licences_screen; then
  pass_step open-licences
else
  fail_step open-licences "Licences tile tap did not open the Licences screen"
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
