#!/usr/bin/env bash
# Flow 29. Filter chip matrix: every chip x action (select+apply, pick+close-X,
# dismiss-empty, clear) x then tap EVERY other chip, x entry point, plus 3+ step
# sequences. Regression for: District -> pick -> close sheet -> other chip dead.
# User Tester drafted this as flow 21. That number is Bug Hunter's
# district-close flow, so this copy is 29.
# Sourced by run_one_flow.sh (needs lib/common.sh).

CHIPS=(state district deity)
declare -A PICK=( [state]='^Tamil Nadu( +[0-9]+)?$' [deity]='^Shiva( +[0-9]+)?$' [district]='^Madurai( +[0-9]+)?$' )
declare -A SECTION=( [state]=STATE [deity]=DEITY [district]=DISTRICT )

open_drawer() {
  ui_dump && ui_find --content-desc "Open navigation menu" || return 1
  ui_tap; sleep 1
}
fresh_home() {
  force_stop_app; launch_app; accept_policy_if_shown || return 1; wait_for_home
}
enter_home_browse() { reach_browse; }
enter_drawer_all() {
  fresh_home || return 1; open_drawer || return 1
  ui_wait_scrolled 15 --text-regex '^All Temples' || return 1
  ui_tap; wait_browse_ready
}
# Filters inside the drawer itself (the "District from drawer" bar).
enter_drawer_bar() {
  fresh_home || return 1; open_drawer || return 1
  ui_wait_scrolled 15 --text-regex '^FILTERS$'
}
enter_search() {
  fresh_home || return 1; open_drawer || return 1
  scroll_drawer_until --resource-id temple-list-search-field || return 1
  ui_tap; ui_type "temple"; adb shell input keyevent 66; sleep 2
  wait_browse_ready
}
# Near me has no DirectoryFilterBar. The caller records NOT RUN (status 2).
enter_near_me() {
  fresh_home || return 1
  ui_wait_scrolled 15 --text-contains "Temples near me" || return 1
  ui_tap; sleep 3
  if ui_dump && ui_find --resource-id filter-chip-state; then
    return 0
  fi
  return 2
}

chip_present() {
  ui_dump || return 1
  case "$1" in
    state) ui_find --resource-id filter-chip-state || ui_find --content-desc "Choose a state" ;;
    district) scroll_chips_until --resource-id filter-chip-district || ui_find --content-desc "Choose a district" ;;
    deity) scroll_chips_until --resource-id filter-chip-deity || ui_find --content-desc "Choose a deity" ;;
  esac
}
open_chip() {
  chip_present "$1" || return 1
  ui_tap
  ui_wait 20 --text-regex '^Filters$'
}
close_x() {
  ui_dump && ui_find --resource-id filter-sheet-close || ui_find --content-desc "Close filters" || return 1
  ui_tap; sleep 1; ! sheet_open
}

# Action leaves the sheet closed; returns 0 if the action itself worked.
do_action() {
  local chip="$1" action="$2"
  case "$action" in
    select) open_chip "$chip" && select_labeled "${PICK[$chip]}" "${SECTION[$chip]}" && apply_sheet ;;
    pick-close) open_chip "$chip" && select_labeled "${PICK[$chip]}" "${SECTION[$chip]}" && close_x ;;
    dismiss-empty) open_chip "$chip" && dismiss_sheet_swipe ;;
    back-empty) open_chip "$chip" && { ui_back; sleep 1; ! sheet_open; } ;;
    outside-empty) open_chip "$chip" && dismiss_sheet_outside ;;
    clear) open_chip "$chip" && select_labeled "${PICK[$chip]}" "${SECTION[$chip]}" && apply_sheet && clear_named "$chip" ;;
  esac
}

# xfail only when the district chip id is missing from the dump and no state
# is selected. A chip that is present but off-screen, or missing after a
# state was applied, is a failure.
district_miss_outcome() {
  local in_dump="$1"
  local state_selected="$2"
  if [[ "$in_dump" -eq 0 && "$state_selected" -eq 0 ]]; then
    printf 'xfail\n'
    return 0
  fi
  printf 'fail\n'
}

district_chip_in_dump() {
  python3 "$UI_PY" resource-ids "$DUMP" --prefix filter-chip- | grep -qx 'filter-chip-district'
}

state_is_selected() {
  if ui_find --content-desc "Clear state filter"; then
    return 0
  fi
  ui_find --resource-id filter-chip-state || return 1
  python3 -c '
import sys
text = " ".join(sys.argv[1].split()).replace("Choose a state", " ")
text = " ".join(text.split())
raise SystemExit(0 if text and text != "State" else 1)
' "$UI_TEXT"
}

# The bug check: every other chip must open a sheet within 3 s after the action.
probe_others() {
  local id="$1" done_chip="$2" other in_dump state_selected outcome
  for other in "${CHIPS[@]}" "$done_chip"; do
    # also re-tap the same chip last
    if ! chip_present "$other"; then
      if [[ "$other" == district ]] && ui_dump; then
        in_dump=0
        state_selected=0
        if district_chip_in_dump; then
          in_dump=1
        fi
        if state_is_selected; then
          state_selected=1
        fi
        outcome="$(district_miss_outcome "$in_dump" "$state_selected")"
        if [[ "$outcome" == xfail ]]; then
          xfail_step "$id-then-$other" "district chip hidden with no state selected"
          continue
        fi
        if [[ "$state_selected" -eq 1 && "$in_dump" -eq 0 ]]; then
          fail_step "$id-then-$other" "district chip missing after a state was selected"
          continue
        fi
      fi
      fail_step "$id-then-$other" "chip not found"
      continue
    fi
    ui_tap
    if ui_wait 3 --text-regex '^Filters$'; then
      pass_step "$id-then-$other"; ui_back; sleep 1; recover_sheet
    else
      fail_step "$id-then-$other" "tap on ${other} chip did nothing after ${id}"
    fi
  done
}

ENTRIES=(home_browse drawer_all drawer_bar search near_me)
ACTIONS=(select pick-close dismiss-empty back-empty outside-empty clear)

for entry in "${ENTRIES[@]}"; do
  for chip in "${CHIPS[@]}"; do
    for action in "${ACTIONS[@]}"; do
      id="$entry-$chip-$action"
      "enter_$entry" >/dev/null 2>&1
      status=$?
      if [[ "$status" -ne 0 ]]; then
        if [[ "$entry" == "near_me" && "$status" -eq 2 ]]; then
          record_not_run "$id" "near me has no directory filter bar"
          step_shot "$id"
        else
          fail_step "$id" "could not reach ${entry}"
        fi
        continue
      fi
      if do_action "$chip" "$action"; then pass_step "$id"; else fail_step "$id" "action failed"; recover_sheet; continue; fi
      probe_others "$id" "$chip"
    done
  done
done

# Sequences of 3+ on Home Browse, each followed by a full probe.
SEQS=(
  "district:pick-close state:select deity:select"
  "district:select deity:pick-close state:clear"
  "state:select district:pick-close district:select deity:dismiss-empty"
  "district:dismiss-empty district:pick-close state:back-empty deity:select"
  "deity:select district:select state:outside-empty district:clear"
)
n=0
for seq in "${SEQS[@]}"; do
  n=$((n+1))
  enter_home_browse >/dev/null 2>&1 || { fail_step "seq$n-enter" "browse not reached"; continue; }
  ok=1
  for st in $seq; do
    do_action "${st%%:*}" "${st##*:}" || { ok=0; fail_step "seq$n-$st" "step failed"; recover_sheet; break; }
  done
  [[ $ok -eq 1 ]] && pass_step "seq$n" && probe_others "seq$n" "${st%%:*}"
  # then detail -> back -> probe
  if ui_wait_scrolled 20 --resource-id temple-browse-card; then
    ui_tap; ui_wait_scrolled 20 --text-contains "How to Reach" && ui_back; sleep 2
    probe_others "seq$n-after-detail" state
  fi
done
force_stop_app
