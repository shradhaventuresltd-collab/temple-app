#!/usr/bin/env bash
# Filter-chip matrix, one slice per flow. Replaces 29_filter_matrix.sh
# parts a and its sequences (flow 30 / part b is owned separately and still
# sourced 29_filter_matrix.sh, now removed).
#
# Caller sets MATRIX_ENTRY (home_browse | drawer_all | search | seq) and,
# except for seq, MATRIX_CHIP (state | district | deity).
#
# Rules from the emulator test-script guide (Confluence PRODUCT 11632642):
# - every case relaunches the app (force-stop, start) and asserts its entry;
# - every wait is bounded, every action is asserted with a dump;
# - one case (action + probes, after the entry screen) is capped at CASE_MAX seconds;
# - District is hidden by design until a State is chosen, so district
#   cases run as state:select -> district:<action>, and a district probe
#   is generated only while a state is applied;
# - the first failure in a case is the only FAIL; its probes are NOT RUN.
#
# Six cases at ~55s entry + 90s actions is about 15 minutes on the happy
# path. A failing case runs longer (retries, dismiss_blockers), and six of
# those can pass the 1140s flow budget. matrix_main therefore stops once
# another case would not finish in time and marks the rest NOT RUN.

CASE_MAX="${CASE_MAX:-90}"
ACTIONS=(select pick-close dismiss-empty back-empty outside-empty clear)
declare -A PICK=( [state]='^Tamil Nadu( +[0-9]+)?$' [deity]='^Shiva( +[0-9]+)?$' [district]='^Madurai( +[0-9]+)?$' )
declare -A SECTION=( [state]=STATE [deity]=DEITY [district]=DISTRICT )
# 29j picks its deity with a state (and district) applied, and the sheet
# only lists deities present under them. Run 40992967143 seq2 dump
# (29j-sequences_seq2.xml): Madurai lists "Any deity  4", "Devi  1",
# "Murugan  1", "Vishnu (Kallalagar)  1", "Vishnu (Koodal Azhagar /
# Viyooga Sundararajan)  1": no Shiva, so seq2 failed "not offered" (a
# script bug, the app was right). Murugan is under Madurai, so also under
# Tamil Nadu and all-India (29f dump: filter-option-deity-Murugan). In seq3
# a Shiva deity first would also hide Madurai from the district list.
SEQ_DEITY_PICK='^Murugan( +[0-9]+)?$'
LAST_ERR=""
STATE_APPLIED=0

# Budgets (run 40992967143). One CASE_MAX of 90s for the whole case failed
# every district case: state:select + district:<action> took ~65s, so the
# third probe always hit "case exceeded 90s" although each probe passed in
# ~12s (29b/29e/29h 8x each, 30a/30b once, 29j seq4/seq5). Now each action
# step gets ACTION_MAX (a deity pick DEITY_ACTION_MAX: the list is ~600
# names), and each probe gets its own PROBE_MAX. All waits inside stay
# bounded by their own timeouts; select_labeled is also capped by
# STEP_DEADLINE (common.sh case_start).
ACTION_MAX="${ACTION_MAX:-90}"
DEITY_ACTION_MAX="${DEITY_ACTION_MAX:-130}"
PROBE_MAX="${PROBE_MAX:-40}"
CASE_MAX_DEFAULT="$CASE_MAX"

# Seconds for the action steps of one case. Usage: actions_budget STEP...
actions_budget() {
  local st total=0
  for st in "$@"; do
    case "$st" in
      deity:select|deity:pick-close|deity:clear) total=$((total + DEITY_ACTION_MAX)) ;;
      *) total=$((total + ACTION_MAX)) ;;
    esac
  done
  echo "$total"
}

# flow_over (common.sh) needs one whole case at its typical length: entry
# (~55s), ~45s per action (a deity pick: its full 100s SELECT_MAX_DEITY
# window), four probes at ~15s
# (run 40992967143 timings). Budgets above are the caps, not the estimate.
# Usage: set_case_need STEP...
set_case_need() {
  local st need=$(( 55 + 4 * 15 ))
  for st in "$@"; do
    case "$st" in
      deity:select|deity:pick-close|deity:clear) need=$((need + 100)) ;;
      *) need=$((need + 45)) ;;
    esac
  done
  # shellcheck disable=SC2034  # read by flow_over in lib/common.sh
  CASE_NEED_S=$need
}

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
  ui_wait 40 --resource-id home-browse-temples || err "Browse button missing on Home" || return 1
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
  # Any chip marks the bar. With a state applied the row scrolls so the
  # State chip is off-screen to the left and uiautomator does not list it:
  # run 40992967143 29d/29g select-then-state ("filter bar not on screen"),
  # dump 29d-drawer-all-state_drawer_all-state-select-then-state.xml shows
  # filter-chip-district at x=14 and no filter-chip-state. Same fix as
  # filter_matrix_b.sh's DRAWER_CHIP_RX.
  ui_wait 8 --resource-id-regex '^filter-chip-(state|district|deity)$' \
    || err "filter bar not on screen" || return 1
}

# scroll_chips_until returns at once when the chip is on screen and
# otherwise swipes the row both ways (bounded at 8 swipes).
find_chip() {
  scroll_chips_until --resource-id "filter-chip-$1"
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
  STATE_APPLIED=0
  LAST_ERR=""
  if ! "enter_${MATRIX_ENTRY}"; then
    fail_step "$id" "could not reach ${MATRIX_ENTRY}: ${LAST_ERR}"
    case_end; return
  fi
  # The budget covers actions and probes, not relaunch + directory load
  # (~55s on the 320x640 AVD in run 40698852836).
  CASE_MAX="$(actions_budget "${steps[@]}")"
  case_start
  for st in "${steps[@]}"; do
    if ! do_action "${st%%:*}" "${st##*:}"; then
      fail_step "$id" "${st}: ${LAST_ERR}"
      for p in $(probe_list "${steps[-1]%%:*}"); do skip_step "$id-then-$p" "prerequisite $id failed"; done
      CASE_MAX="$CASE_MAX_DEFAULT"; case_end; return
    fi
  done
  if case_over; then
    fail_step "$id" "actions took $((SECONDS - CASE_T0))s, over their ${CASE_MAX}s budget"
    for p in $(probe_list "${steps[-1]%%:*}"); do skip_step "$id-then-$p" "prerequisite $id failed"; done
    CASE_MAX="$CASE_MAX_DEFAULT"; case_end; return
  fi
  pass_step "$id"
  mapfile -t probes < <(probe_list "${steps[-1]%%:*}")
  for p in "${probes[@]}"; do
    if flow_over; then
      budget_stop "$id-then-$p"
      local rest=0 q
      for q in "${probes[@]}"; do
        [[ "$rest" -eq 1 ]] && budget_stop "$id-then-$q"
        [[ "$q" == "$p" ]] && rest=1
      done
      break
    fi
    # Each probe has its own clock (see Budgets above).
    CASE_MAX="$PROBE_MAX"
    case_start
    rc=0
    probe "$id" "$p" || rc=1
    if [[ "$rc" -eq 0 ]] && case_over; then
      LAST_ERR="probe took $((SECONDS - CASE_T0))s, over its ${PROBE_MAX}s budget"
      rc=1
    fi
    if [[ "$rc" -eq 0 ]]; then
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
  CASE_MAX="$CASE_MAX_DEFAULT"
  case_end
}

# set_case_need before run_case_or_stop so flow_over sees this case's size.
matrix_case() {
  set_case_need "${@:2}"
  run_case_or_stop "$@"
}

matrix_main() {
  local t0=$SECONDS action
  if [[ "$MATRIX_ENTRY" == seq ]]; then
    MATRIX_ENTRY=home_browse
    # Shiva stays the target wherever the app offers it. seq1 picks the
    # deity under Tamil Nadu alone (pick-close leaves Madurai unapplied:
    # its seq1 dump shows "Any deity  50"), and run 4's seq1 failure was the
    # old shared 90s budget ("gave up ... after 2s"), not a missing Shiva.
    # Only seq2 (Madurai applied: Devi, Murugan, two Vishnu; seq2 dump)
    # and seq3 (Shiva first would hide Madurai, which has no Shiva temple)
    # need a deity that Madurai has.
    # 29j runs seq1-seq2, 29k seq3, 29l seq4-seq5 (SEQ_CASES), so even with
    # every action and probe at its cap (55s entry + 90s/130s per action +
    # 4x40s probes: 525s/485s a sequence) each flow stays under the 1140s
    # flow budget (five sequences in one flow were ~1085s at run
    # 40992967143's pace). The deity target is set per
    # sequence, not by position, so a subset keeps the same targets.
    local sq
    for sq in ${SEQ_CASES:-seq1 seq2 seq3 seq4 seq5}; do
      case "$sq" in
        seq2|seq3) PICK[deity]="$SEQ_DEITY_PICK" ;;
        *) PICK[deity]='^Shiva( +[0-9]+)?$' ;;
      esac
      case "$sq" in
        seq1) matrix_case seq1 state:select district:pick-close deity:select ;;
        seq2) matrix_case seq2 state:select district:select deity:pick-close ;;
        seq3) matrix_case seq3 deity:select state:select district:clear ;;
        seq4) matrix_case seq4 state:pick-close deity:dismiss-empty state:select ;;
        seq5) matrix_case seq5 state:select district:outside-empty state:clear ;;
        *) echo "matrix: unknown sequence ${sq}" >&2; return 1 ;;
      esac
    done
    PICK[deity]='^Shiva( +[0-9]+)?$'
  else
    for action in "${ACTIONS[@]}"; do
      if [[ "$MATRIX_CHIP" == district ]]; then
        matrix_case "$MATRIX_ENTRY-district-$action" state:select "district:$action"
      else
        matrix_case "$MATRIX_ENTRY-$MATRIX_CHIP-$action" "$MATRIX_CHIP:$action"
      fi
    done
  fi
  force_stop_app
  echo "ELAPSED ${FLOW}: $((SECONDS - t0))s"
  printf 'ELAPSED %s: %ss\n' "$FLOW" "$((SECONDS - t0))" >> "$RESULTS.elapsed"
}
