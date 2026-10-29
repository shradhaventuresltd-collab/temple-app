#!/usr/bin/env bash
# Filter matrix part b (was flow 30, FILTER_MATRIX_PART=b of 29_filter_matrix.sh),
# one small slice per flow: 30a-30d. Sourced by those flows, which run under
# run_one_flow.sh (lib/common.sh is already loaded).
#
# Caller sets MATRIX_ENTRY (drawer_bar | near_me) and, for drawer_bar,
# MATRIX_CHIP (state | district | deity).
#
# Follows the emulator test-script guide (Confluence PRODUCT 11632642):
# - every case starts from force-stop + launch and its entry helper, which
#   ends with an assertion of the target screen;
# - every wait is bounded; every action is followed by a dump assertion;
# - before every probe the entry screen is re-asserted, and re-opened when
#   it is gone (the drawer bar lives inside the drawer);
# - one case is capped at CASE_MAX seconds (case_start/case_end in common.sh);
# - the first failure in a case is its only FAIL; dependants are NOT RUN.
#
# Run 40463875634 root causes this slice addresses (all script-side):
# - probes never re-checked the drawer, so once it closed every later probe
#   said "chip not found" on Home;
# - enter_drawer_bar did not check its last wait, and its output was hidden;
# - "district chip hidden with no state selected" was recorded while the
#   drawer was closed, not because the drawer hides it.
#
# Six cases at ~55s entry + 90s actions + ~10s of shots is about 15 minutes
# on the happy path. A failing case runs longer, and six of those can pass
# the 1140s flow budget. matrix_main therefore stops once another case
# would not finish in time and marks the rest NOT RUN.

CASE_MAX="${CASE_MAX:-90}"
ACTIONS=(select pick-close dismiss-empty back-empty outside-empty clear)
# Option chips are "Name  N" in one node. Allow the count, no hard $ on the name.
declare -A PICK=( [state]='^Tamil Nadu( +[0-9]+)?$' [deity]='^Shiva( +[0-9]+)?$' [district]='^Madurai( +[0-9]+)?$' )
declare -A SECTION=( [state]=STATE [deity]=DEITY [district]=DISTRICT )
LAST_ERR=""
STATE_APPLIED=0

err() { LAST_ERR="$*"; echo "matrix: $*" >&2; return 1; }

fresh_home() {
  force_stop_app
  launch_app
  accept_policy_if_shown || err "policy gate or home did not appear" || return 1
  ui_wait 30 --text-contains "Temple Directory" || err "home did not appear" || return 1
}

drawer_is_open() {
  ui_find --text-regex '^All Temples( [0-9]+)?$' || ui_find --text-regex '^FILTERS$' \
    || ui_find --text-regex '^SEARCH$'
}

open_drawer() {
  ui_wait 10 --content-desc "Open navigation menu" || err "menu button missing" || return 1
  ui_tap
  ui_wait 8 --text-regex '^(All Temples( [0-9]+)?|FILTERS|SEARCH)$' || err "drawer did not open" || return 1
}

# The bar sits below SEARCH in the drawer's own list. scroll_drawer_until
# swipes inside the drawer; ui_wait_scrolled flings the whole screen.
show_drawer_bar() {
  scroll_drawer_until --resource-id filter-chip-state || err "drawer filter bar not reachable" || return 1
  # b85fee1 shows drawer-filters-loading until the directory arrives.
  local start=$SECONDS
  while ui_find --resource-id drawer-filters-loading; do
    (( SECONDS - start > 20 )) && { err "drawer filters still loading after 20s"; return 1; }
    sleep 1; ui_dump || true
  done
  ui_wait 5 --resource-id filter-chip-state || err "filter-chip-state missing in drawer" || return 1
}

enter_drawer_bar() {
  fresh_home || return 1
  open_drawer || return 1
  show_drawer_bar
}

# Near me has no DirectoryFilterBar; return 2 so the caller records NOT RUN.
enter_near_me() {
  fresh_home || return 1
  ui_wait_scrolled 40 --text-contains "Temples near me" || err "Temples near me tile missing" || return 1
  ui_tap
  # Near me reached: one of the screen's own keys. near-me-rationale-sheet
  # (location consent), near-me-status ("Finding temples..."), near-me-list
  # (results) or near-me-fallback (declined/no fix). None exists elsewhere.
  ui_wait 15 --resource-id-regex '^near-me-(rationale-sheet|status|list|fallback)$' \
    || err "near me screen did not render" || return 1
  dismiss_location_consent "Not now" || true
  ui_wait 15 --resource-id-regex '^near-me-(status|list|fallback|empty)$' \
    || err "near me stuck after consent" || return 1
  [[ "${NEAR_ME_MARKED:-0}" -eq 1 ]] || { pass_step "near_me-reached"; NEAR_ME_MARKED=1; }
  if ui_wait 5 --resource-id filter-chip-state; then
    return 0
  fi
  return 2
}

# Entry screen on top before every action or probe: no sheet, drawer bar
# visible. A closed drawer is re-opened (the guide's reopen_entry).
REOPENED=0
assert_entry_screen() {
  if sheet_open; then
    recover_sheet
    sheet_open && { err "sheet stuck open"; return 1; }
  fi
  ui_dump || { err "no hierarchy"; return 1; }
  if ! drawer_is_open; then
    REOPENED=1
    echo "matrix: drawer was closed; reopening it" >&2
    open_drawer || return 1
  fi
  show_drawer_bar
}

district_in_bar() {
  python3 "$UI_PY" resource-ids "$DUMP" --prefix filter-chip- | grep -qx filter-chip-district
}

find_chip() {
  case "$1" in
    state) ui_dump && ui_find --resource-id filter-chip-state ;;
    *) scroll_chips_until --resource-id "filter-chip-$1" ;;
  esac
}

open_chip() {
  assert_entry_screen || return 1
  find_chip "$1" || err "$1 chip not in the drawer bar" || return 1
  ui_tap
  ui_wait 10 --text-regex '^Filters$' || err "$1 chip tap did not open the sheet" || return 1
  if [[ "$1" == district ]]; then
    wait_out_district_loader || err "district list still loading" || return 1
  fi
}

wait_sheet_closed() {
  local _
  for _ in 1 2 3 4 5; do
    sheet_open || return 0
    sleep 1
  done
  return 1
}

close_x() {
  { ui_dump && { ui_find --resource-id filter-sheet-close || ui_find --content-desc "Close filters"; }; } \
    || err "close button missing" || return 1
  ui_tap
  wait_sheet_closed || err "sheet still open after close X"
}

back_close() {
  ui_back
  wait_sheet_closed || err "sheet still open after Back"
}

pick() { select_labeled "${PICK[$1]}" "${SECTION[$1]}" || err "could not pick ${PICK[$1]} in the $1 list"; }
apply() { apply_sheet || err "Show N temples did not apply and close"; }

# After apply the chip carries "Clear <chip> filter" and the drawer shows
# its "Browse N Temples" summary button.
assert_applied() {
  ui_wait 8 --content-desc "Clear $1 filter" || err "$1 chip shows no applied value after Show N temples" || return 1
}
assert_not_applied() {
  ui_dump || return 1
  ! ui_find --content-desc "Clear $1 filter" || err "$1 filter applied after a close without Show" || return 1
}
# The drawer must survive a sheet action; it holds the filter state.
assert_drawer_kept() {
  ui_dump || return 1
  drawer_is_open || err "drawer closed after the $1 sheet action" || return 1
}

do_action() {
  local chip="$1" action="$2"
  open_chip "$chip" || return 1
  case "$action" in
    select) pick "$chip" && apply && assert_applied "$chip" || return 1 ;;
    pick-close) pick "$chip" && close_x && assert_not_applied "$chip" || return 1 ;;
    dismiss-empty) dismiss_sheet_swipe >/dev/null || err "swipe down did not close the sheet" || return 1 ;;
    back-empty) back_close || return 1 ;;
    outside-empty) dismiss_sheet_outside >/dev/null || err "tap outside did not close the sheet" || return 1 ;;
    clear) pick "$chip" && apply && assert_applied "$chip" || return 1
      show_drawer_bar || return 1
      clear_named "$chip" || err "$chip filter did not clear" || return 1 ;;
  esac
  assert_drawer_kept "$chip" || return 1
  if [[ "$chip" == state ]]; then
    case "$action" in select) STATE_APPLIED=1 ;; clear) STATE_APPLIED=0 ;; esac
  fi
  return 0
}

# Probes: every chip, then the acted chip again. District is probed when the
# bar shows it; with no district chip and no state the case is NOT RUN.
probe_list() {
  local done_chip="$1" c
  for c in state district deity "$done_chip"; do printf '%s\n' "$c"; done
}

probe() {
  local id="$1" other="$2"
  assert_entry_screen || return 1
  if [[ "$other" == district ]] && ! district_in_bar; then
    if [[ "$STATE_APPLIED" -eq 0 ]]; then
      return 3
    fi
    err "district chip missing from the drawer bar after a state was applied"
    return 1
  fi
  find_chip "$other" || err "$other chip not in the drawer bar after $id" || return 1
  ui_tap
  ui_wait 10 --text-regex '^Filters$' || err "tap on $other chip did nothing after $id" || return 1
  back_close
}

run_case() {
  local id="$1"; shift
  local steps=("$@") st p probes=() rc q rest
  STATE_APPLIED=0
  LAST_ERR=""
  REOPENED=0
  "enter_${MATRIX_ENTRY}"
  rc=$?
  if [[ "$rc" -eq 2 ]]; then
    record_not_run "$id" "near me has no directory filter bar"
    step_shot "$id"
    case_end; return
  fi
  if [[ "$rc" -ne 0 ]]; then
    fail_step "$id" "could not reach ${MATRIX_ENTRY}: ${LAST_ERR}"
    case_end; return
  fi
  # The budget covers actions and probes, not relaunch + directory load
  # (~55s on the 320x640 AVD in run 40698852836).
  case_start
  for st in "${steps[@]}"; do
    if ! do_action "${st%%:*}" "${st##*:}"; then
      fail_step "$id" "${st}: ${LAST_ERR}"
      for p in $(probe_list "${steps[-1]%%:*}"); do skip_step "$id-then-$p" "prerequisite $id failed"; done
      case_end; return
    fi
  done
  pass_step "$id"
  mapfile -t probes < <(probe_list "${steps[-1]%%:*}")
  for p in "${probes[@]}"; do
    if flow_over; then
      record_not_run "$id-then-$p" "stopped before the ${FLOW_BUDGET_S}s flow budget"
      rest=0
      for q in "${probes[@]}"; do
        [[ "$rest" -eq 1 ]] && record_not_run "$id-then-$q" "stopped before the ${FLOW_BUDGET_S}s flow budget"
        [[ "$q" == "$p" ]] && rest=1
      done
      break
    fi
    if case_over; then
      fail_step "$id-then-$p" "case exceeded ${CASE_MAX}s"
      continue
    fi
    probe "$id" "$p"
    rc=$?
    if [[ "$rc" -eq 0 ]]; then
      pass_step "$id-then-$p"
    elif [[ "$rc" -eq 3 ]]; then
      record_not_run "$id-then-$p" "district chip not offered with no state applied"
    else
      fail_step "$id-then-$p" "$LAST_ERR"
      rest=0
      for q in "${probes[@]}"; do
        [[ "$rest" -eq 1 ]] && skip_step "$id-then-$q" "prerequisite $id-then-$p failed"
        [[ "$q" == "$p" ]] && rest=1
      done
      break
    fi
  done
  case_end
}

matrix_main() {
  local t0=$SECONDS action
  if [[ "$MATRIX_ENTRY" == near_me ]]; then
    run_case_or_stop near_me-state-select state:select
  else
    for action in "${ACTIONS[@]}"; do
      run_case_or_stop "$MATRIX_ENTRY-$MATRIX_CHIP-$action" "$MATRIX_CHIP:$action"
    done
  fi
  force_stop_app
  echo "ELAPSED ${FLOW}: $((SECONDS - t0))s"
}
