#!/usr/bin/env bash
# Flow 14. Back, HOME resume, and force-stop relaunch on each main screen.
launch_app
if ! accept_policy_if_shown || ! wait_for_home; then
  fail_step home "home did not appear"
  return 0
fi
pass_step home-visible

see_text() {
  ui_wait_scrolled "${2:-12}" --text-contains "$1"
}

home_back_leaves() {
  ui_back
  sleep 2
  ui_dump || return 0
  if ui_find --text-contains "Temple Directory"; then
    return 1
  fi
  return 0
}

if home_back_leaves; then
  pass_step home-back
else
  fail_step home-back "home stayed in the foreground after back"
fi
launch_app
if wait_for_home; then
  pass_step home-relaunch
else
  fail_step home-relaunch "home did not return"
  return 0
fi

ui_home_key
sleep 1
resume_app
if see_text "Temple Directory" 20; then
  pass_step home-resume
else
  fail_step home-resume "home was not resumed"
fi

open_list() {
  open_browse && wait_browse_ready
}

check_child() {
  local key="$1"
  local marker="$2"
  local opener="$3"
  if ! "$opener"; then
    fail_step "${key}-open" "could not open ${key}"
    return 0
  fi
  if see_text "$marker" 18; then
    pass_step "${key}-visible"
  else
    fail_step "${key}-visible" "${marker} was not shown"
  fi

  ui_back
  sleep 1
  # A sheet (near me rationale) consumes the first back.
  if ! see_text "Temple Directory" 8; then
    ui_back
    sleep 1
  fi
  if see_text "Temple Directory" 12; then
    pass_step "${key}-back"
  else
    fail_step "${key}-back" "back did not return home"
  fi

  if ! "$opener"; then
    fail_step "${key}-resume" "could not reopen ${key}"
    return 0
  fi
  ui_home_key
  sleep 1
  resume_app
  if see_text "$marker" 18; then
    pass_step "${key}-resume"
  else
    fail_step "${key}-resume" "${marker} was not showing after HOME"
  fi

  force_stop_app
  launch_app
  accept_policy_if_shown || true
  if see_text "Temple Directory" 25 || see_text "$marker" 8; then
    pass_step "${key}-force-stop"
  else
    fail_step "${key}-force-stop" "app did not return after force-stop"
  fi
}

open_detail() {
  open_list || return 1
  ui_wait_scrolled 20 --resource-id temple-browse-card --text-contains "Temple" || return 1
  ui_tap
  ui_wait_scrolled 15 --text-contains "How to Reach"
}

open_near() {
  # Land on home first; near me is launched from there.
  if ! see_text "Temple Directory" 8; then
    ui_back || true
    launch_app
    wait_for_home || return 1
  fi
  ui_wait_scrolled 20 --text-contains "Temples near me" || return 1
  ui_tap
  sleep 1
  # Not now is enough for the back-stack check. The sheet must not stay up.
  if ui_wait 8 --text-contains "Sort by distance"; then
    dismiss_location_consent "Not now" || true
  fi
  ui_wait 15 --text-contains "Temples near me"
}

open_licences() {
  if ! see_text "Temple Directory" 8; then
    launch_app
    wait_for_home || return 1
  fi
  if ui_dump && ui_find --content-desc "Open navigation menu"; then
    ui_tap
    sleep 1
  fi
  ui_wait_scrolled 12 --text-regex '^Licences$' || return 1
  ui_tap
  ui_wait 12 --text-contains "District boundaries"
}

check_child list "State" open_list
check_child detail "How to Reach" open_detail
check_child near-me "Temples near me" open_near
check_child licences "District boundaries" open_licences
