#!/usr/bin/env bash
# Flow 31. KAN-198: State, reopen, District, Deity, Clear all.
# Runs on Browse and on drawer Search. Sourced by run_one_flow.sh.

chain_filters() {
  local where="$1"
  find_filter_chip filter-chip-state "" "Choose a state" || return 1
  ui_tap
  wait_filter_sheet 15 || return 1
  select_labeled '^Kerala( +[0-9]+)?$' STATE || return 1
  apply_sheet || return 1
  pass_step "$where-state"

  find_filter_chip filter-chip-state "" "Choose a state" || return 1
  ui_tap
  wait_filter_sheet 12 || return 1
  ui_dump && ui_find --text-regex '^Kerala( +[0-9]+)?$' || return 1
  ui_back || return 1
  sleep 1
  pass_step "$where-reopen"

  find_filter_chip filter-chip-district "" "Choose a district" || return 1
  ui_tap
  wait_filter_sheet 15 || return 1
  if ui_find --resource-id filter-choose-state-first; then
    finish_choose_state_first || return 1
  fi
  select_labeled '^Kottayam( +[0-9]+)?$' DISTRICT || return 1
  apply_sheet || return 1
  pass_step "$where-district"

  find_filter_chip filter-chip-deity "" "Choose a deity" || return 1
  ui_tap
  wait_filter_sheet 15 || return 1
  select_labeled '^Shiva( +[0-9]+)?$' DEITY || return 1
  apply_sheet || return 1
  pass_step "$where-deity"

  ui_dump && ui_find --resource-id filter-clear || return 1
  ui_tap
  sleep 1
  filter_chips_idle || return 1
  pass_step "$where-clear-all"
}

if ! err="$(reach_browse)"; then
  fail_step browse "${err:-could not open the temple list}"
  return 0
fi
pass_step browse
if ! chain_filters browse; then
  fail_step browse-chain "State, District, Deity, Clear all did not finish"
  recover_sheet || true
fi

force_stop_app
launch_app
accept_policy_if_shown || { fail_step search-enter "policy"; return 0; }
wait_for_home || { fail_step search-enter "home"; return 0; }
ui_dump && ui_find --content-desc "Open navigation menu" || {
  fail_step search-enter "drawer"
  return 0
}
ui_tap
sleep 1
scroll_drawer_until --resource-id temple-list-search-field || {
  fail_step search-enter "search field"
  return 0
}
ui_tap
ui_type "temple"
adb_shell_capped 8 input keyevent 66 || {
  fail_step search-enter "search submit"
  return 0
}
sleep 2
wait_browse_ready || { fail_step search-enter "results"; return 0; }
pass_step search-enter
if ! chain_filters search; then
  fail_step search-chain "drawer Search chain did not finish"
  recover_sheet || true
fi
