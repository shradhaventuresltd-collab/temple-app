#!/usr/bin/env bash
# Filter-chip matrix, one slice per flow. Replaces 29_filter_matrix.sh
# parts a and its sequences (flow 30 / part b is owned separately and still
# sources 29_filter_matrix.sh).
#
# Caller sets MATRIX_ENTRY (home_browse | drawer_all | search | seq) and,
# except for seq, MATRIX_CHIP (state | district | deity).
#
# Rules from the emulator test-script guide (Confluence PRODUCT 11632642):
# - every case relaunches the app (force-stop, start) and asserts its entry;
# - every wait is bounded, every action is asserted with a dump;
# - one case (entry + action + probes) is capped at CASE_MAX seconds;
# - District is hidden by design until a State is chosen, so district
#   cases run as state:select -> district:<action>, and a district probe
#   is generated only while a state is applied;
# - the first failure in a case is the only FAIL; its probes are NOT RUN.
#
# Worst case per flow: 6 cases x CASE_MAX (60 s) = 360 s, plus install.

CASE_MAX="${CASE_MAX:-60}"
ACTIONS=(select pick-close dismiss-empty back-empty outside-empty clear)
declare -A PICK=( [state]='^Tamil Nadu( +[0-9]+)?$' [deity]='^Shiva( +[0-9]+)?$' [district]='^Madurai( +[0-9]+)?$' )
declare -A SECTION=( [state]=STATE [deity]=DEITY [district]=DISTRICT )
LAST_ERR=""
STATE_APPLIED=0

err() { LAST_ERR="$*"; return 1; }

fresh_home() {
  force_stop_app
  launch_app
  accept_policy_if_shown || err "policy gate or home did not appear"  || return 1
  ui_wait 30 --text-contains "Temple Directory" || err "home did not appear" || return 1
}

open_drawer() {
  ui_wait 10 --content-desc "Open navigation menu" || err "menu button missing" || return 1
  ui_tap
  ui_wait 8 --text-regex '^All Temples( [0-9]+)?$' || err "drawer did not open" || return 1
}

browse_ready() {
  ui_wait 30 --resource-id filter-chip-state || err "browse filter bar did not appear" || return 1
  ! ui_find --text-contains "Loading temples" || ui_wait 20 --resource-id temple-browse-card \
    || err "browse list still loading" || return 1
}

enter_home_browse() {
  fresh_home || return 1
  ui_wait 15 --resource-id home-browse-temples || err "Browse button missing on Home" || return 1
  ui_tap
  browse_ready
}

enter_drawer_all() {
  fresh_home || return 1
  open_drawer || return 1
  ui_tap
  browse_ready
}

enter_search() {
  fresh_home || return 1
  open_drawer || return 1
  scroll_drawer_until --resource-id temple-drawer-search-field \
    || scroll_drawer_until --resource-id temple-list-search-field \
    || err "drawer search field missing" || return 1
  ui_tap
  ui_type "temple"
  adb_shell_capped 8 input keyevent 66 || err "enter key did not send" || return 1
  browse_ready
}

# The entry screen must be on top before every check: no sheet, bar visible.
assert_entry_screen() {
  if sheet_open; then
    recover_sheet
    sheet_open && { err "sheet stuck open"; return 1; }
  fi
  ui_wait 8 --resource-id filter-chip-state || err "filter bar not on screen" || return 1
}

find_chip() {
  case "$1" in
    state) ui_dump && ui_find --resource-id filter-chip-state ;;
    *) scroll_chips_until --resource-id "filter-chip-$1" ;;
  esac
}

open_chip() {
  assert_entry_screen || return 1
  find_chip "$1" || err "$1 chip not in the bar" || return 1
  ui_tap
  ui_wait 10 --text-regex '^Filters$' || err "$1 chip tap did not open the sheet" || return 1
  if [[ "$1" == district ]]; then
    wait_out_district_loader || err "district list still loading" || return 1
  fi
}

# Close with X and prove it closed. Grouped so a failed dump cannot fall
# through to a find on a stale dump (the old `a && b || c` precedence bug).
close_x() {
  { ui_dump && { ui_find --resource-id filter-sheet-close || ui_find --content-desc "Close filters"; }; } \
    || err "close button missing" || return 1
  ui_tap
  local _
  for _ in 1 2 3 4 5; do
    sheet_open || return 0
    sleep 1
  done
  err "sheet still open after close X"
}

pick() {
  select_labeled "${PICK[$1]}" "${SECTION[$1]}" || err "could not pick ${PICK[$1]} in $1 list"
}

back_close() {
  ui_back
  local _
  for _ in 1 2 3 4 5; do
    sheet_open || return 0
    sleep 1
  done
  err "sheet still open after Back"
}

apply() { apply_sheet || err "Show N temples did not apply and close"; }

# Leaves the sheet closed and asserts the visible outcome.
do_action() {
  local chip="$1" action="$2"
  open_chip "$chip" || return 1
  case "$action" in
    select) pick "$chip" && apply || return 1
      assert_applied "$chip" || return 1 ;;
    pick-close) pick "$chip" && close_x || return 1 ;;
    dismiss-empty) dismiss_sheet_swipe >/dev/null || err "swipe down did not close the sheet" || return 1 ;;
    back-empty) back_close || return 1 ;;
    outside-empty) dismiss_sheet_outside >/dev/null || err "tap outside did not close the sheet" || return 1 ;;
    clear) pick "$chip" && apply && assert_applied "$chip" || return 1
      clear_named "$chip" || err "$chip filter did not clear" || return 1 ;;
  esac
  if [[ "$chip" == state ]]; then
    case "$action" in select) STATE_APPLIED=1 ;; clear) STATE_APPLIED=0 ;; esac
  fi
  return 0
}

assert_applied() {
  ui_wait 8 --content-desc "Clear $1 filter" || err "$1 chip shows no applied value after Show N temples" || return 1
}

# Every other chip, then the same chip, must open the sheet.
probe_list() {
  local done_chip="$1" c
  for c in state district deity "$done_chip"; do
    if [[ "$c" == district && "$STATE_APPLIED" -ne 1 ]]; then
      continue  # hidden by design without a state; not generated
    fi
    printf '%s\n' "$c"
  done
}

probe() {
  local id="$1" other="$2"
  assert_entry_screen || return 1
  find_chip "$other" || err "$other chip not in the bar after $id" || return 1
  ui_tap
  ui_wait 10 --text-regex '^Filters$' || err "tap on $other chip did nothing after $id" || return 1
  back_close
}

run_case() {
  local id="$1"; shift
  local steps=("$@") st p probes=() rc
  case_start
  STATE_APPLIED=0
  LAST_ERR=""
  if ! "enter_${MATRIX_ENTRY}"; then
    fail_step "$id" "could not reach ${MATRIX_ENTRY}: ${LAST_ERR}"
    case_end; return
  fi
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
    if case_over; then
      fail_step "$id-then-$p" "case exceeded ${CASE_MAX}s"
      continue
    fi
    if probe "$id" "$p"; then
      pass_step "$id-then-$p"
    else
      fail_step "$id-then-$p" "$LAST_ERR"
      # The screen is unknown now; later probes would only cascade.
      local rest=0 q
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
  if [[ "$MATRIX_ENTRY" == seq ]]; then
    MATRIX_ENTRY=home_browse
    run_case seq1 state:select district:pick-close deity:select
    run_case seq2 state:select district:select deity:pick-close
    run_case seq3 deity:select state:select district:clear
    run_case seq4 state:pick-close deity:dismiss-empty state:select
    run_case seq5 state:select district:outside-empty state:clear
  else
    for action in "${ACTIONS[@]}"; do
      if [[ "$MATRIX_CHIP" == district ]]; then
        run_case "$MATRIX_ENTRY-district-$action" state:select "district:$action"
      else
        run_case "$MATRIX_ENTRY-$MATRIX_CHIP-$action" "$MATRIX_CHIP:$action"
      fi
    done
  fi
  force_stop_app
  echo "ELAPSED ${FLOW}: $((SECONDS - t0))s"
  printf 'ELAPSED %s: %ss\n' "$FLOW" "$((SECONDS - t0))" >> "$RESULTS.elapsed"
}
