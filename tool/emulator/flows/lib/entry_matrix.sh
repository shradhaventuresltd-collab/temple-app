#!/usr/bin/env bash
# Flow 17. Every entry into the temple list x every filter control.
# Entry points: home-button, drawer-all, drawer-search, list-drawer-all (stacked list).
# Controls per entry: state/deity/district open, select+apply, chip shows value,
# clear via chip x, swipe-dismiss from header AND from the option list, double tap.
# Sourced by flows 17a/17b, which set ENTRY_MATRIX_ENTRIES. Four entries
# did not fit the 1140s flow budget (run 40916686359: ~55s per pick, ~355s
# per entry on the happy path, timeout in the fourth entry), so each flow
# runs two entries.

open_drawer() {
  ui_dump && ui_find --content-desc "Open navigation menu" || return 1
  ui_tap; sleep 1
}

enter_home_button() { reach_browse; }

enter_drawer_all() {
  launch_app; accept_policy_if_shown || return 1; wait_for_home || return 1
  open_drawer || return 1
  ui_wait_scrolled 15 --text-regex '^All Temples' || return 1
  ui_tap; wait_browse_ready
}

enter_drawer_search() {
  launch_app; accept_policy_if_shown || return 1; wait_for_home || return 1
  open_drawer || return 1
  # The field is under the drawer header. A dump taken at the top does not
  # contain temple-list-search-field (screenshot 39_).
  scroll_drawer_until --resource-id temple-list-search-field || return 1
  ui_tap; ui_type "temple"; adb shell input keyevent 66; sleep 2
  wait_browse_ready
}

enter_list_drawer_all() {
  enter_home_button || return 1
  open_drawer || return 1
  ui_wait_scrolled 15 --text-regex '^All Temples' || return 1
  ui_tap; wait_browse_ready
}

# Deity uses resource-id filter-chip-deity. The tooltip still matches a
# selected chip whose visible label is the deity name.
open_chip() {
  case "$1" in
    state) ui_dump && { ui_find --resource-id filter-chip-state || ui_find --content-desc "Choose a state"; } ;;
    district) ui_dump && { ui_find --resource-id filter-chip-district || ui_find --content-desc "Choose a district"; } ;;
    deity) ui_dump && { ui_find --resource-id filter-chip-deity || ui_find --content-desc "Choose a deity"; } ;;
  esac || return 1
  ui_tap
  ui_wait 20 --text-regex '^Filters$'
}

swipe_from_list() {
  local width height
  read -r width height < <(ui_screen_size) || return 1
  # Pull the option list down from its top (list at min extent): _pullToDismiss path.
  adb_shell_capped 8 input swipe $((width / 2)) $((height * 45 / 100)) $((width / 2)) $((height * 95 / 100)) 120 || {
    echo "swipe_from_list: swipe timed out" >&2
    return 1
  }
  sleep 1
  ! sheet_open
}

declare -A PICK=( [state]='^Kerala( +[0-9]+)?$' [deity]='^Shiva( +[0-9]+)?$' [district]='^Agra( +[0-9]+)?$' )
declare -A SECTION=( [state]=STATE [deity]=DEITY [district]=DISTRICT )

read -ra entry_list <<<"${ENTRY_MATRIX_ENTRIES:?flow must set ENTRY_MATRIX_ENTRIES}"
for entry in "${entry_list[@]}"; do
  if ! err="$("enter_${entry}")"; then
    fail_step "$entry-enter" "${err:-could not reach the list}"; continue
  fi
  pass_step "$entry-enter"
  for f in state deity district; do
    id="$entry-$f"
    if ! open_chip "$f"; then
      [[ $f == district ]] && { xfail_step "$id-open" "district chip hidden (asset not bundled?)"; continue; }
      fail_step "$id-open" "chip did not open the sheet"; continue
    fi
    pass_step "$id-open"
    if err="$(dismiss_sheet_swipe 2>&1)"; then pass_step "$id-swipe-header"; else fail_step "$id-swipe-header" "$err"; recover_sheet; fi
    open_chip "$f" && { if swipe_from_list; then pass_step "$id-swipe-list"; else fail_step "$id-swipe-list" "sheet stayed open"; recover_sheet; fi; }
    if open_chip "$f" && select_labeled "${PICK[$f]}" "${SECTION[$f]}" && apply_sheet && chip_exact "$SELECTED_LABEL"; then
      pass_step "$id-select"
    else
      fail_step "$id-select" "chip did not take the selection on this route"; recover_sheet; continue
    fi
    # Re-open a chip that now shows a value (deity has no id: tooltip only).
    if open_chip "$f"; then pass_step "$id-reopen-selected"; ui_back; sleep 1; else fail_step "$id-reopen-selected" "selected chip did not reopen"; fi
    if clear_named "$f"; then pass_step "$id-clear"; else fail_step "$id-clear" "chip x did not clear"; fi
    # Double tap: must open exactly one sheet, one back closes it.
    open_chip "$f" >/dev/null 2>&1 && { adb_shell_capped 8 input tap "$UI_CX" "$UI_CY"; sleep 1; ui_back; sleep 1;
      if sheet_open; then fail_step "$id-double-tap" "two sheets stacked"; recover_sheet; else pass_step "$id-double-tap"; fi; }
  done
  # Empty-state Clear filters, from this entry. The chip-row Clear is a
  # different control. The search text must go. The State chip is checked
  # only when Kerala actually applied; a missed pick is not a failed clear.
  kerala_applied=0
  if ui_dump && ui_find --resource-id filter-chip-state --text-regex '^State$'; then
    ui_tap
    if ui_wait 12 --text-regex '^Filters$'; then
      if select_labeled '^Kerala( +[0-9]+)?$' STATE && apply_sheet; then
        kerala_applied=1
      else
        recover_sheet || true
      fi
    fi
  fi
  if ui_dump && ui_find --resource-id temple-list-search-field; then
    ui_tap
    # drawer_search opens with "temple" in the field. Typing after it gave
    # "templezzzqqq", which search still matches as a prefix of "temple"
    # (50 Kerala temples in run 40698852836), so no empty state appeared.
    if ui_dump && ui_find --content-desc "Clear search"; then
      ui_tap
      sleep 0.5
      ui_dump && ui_find --resource-id temple-list-search-field && ui_tap
    fi
    # Do not type onto a leftover query. Clear search is shown only while
    # the field has text; the field node itself must not still say "temple".
    ui_dump || true
    if ui_find --content-desc "Clear search"; then
      fail_step "$entry-empty-clear" "search field was not empty before typing"
      continue
    fi
    if ui_find --resource-id temple-list-search-field && [[ "$UI_TEXT" == *temple* ]]; then
      fail_step "$entry-empty-clear" "search field still held '${UI_TEXT}' before typing"
      continue
    fi
    ui_find --resource-id temple-list-search-field && ui_tap
    ui_type "zzzqqq"
    adb_shell_capped 8 input keyevent 66 || true
    sleep 2
    if ui_dump && ui_find --resource-id filter-empty-clear; then
      ui_tap
      sleep 1
      ui_dump
      if ui_find --text-contains "zzzqqq"; then
        fail_step "$entry-empty-clear" "search text kept"
      elif [[ "$kerala_applied" == 1 ]] && ! ui_find --resource-id filter-chip-state --text-regex '^State$'; then
        fail_step "$entry-empty-clear" "state chip kept"
      else
        pass_step "$entry-empty-clear"
      fi
    elif [[ "$kerala_applied" != 1 ]]; then
      # The app offers "Clear filters" only while a filter is active
      # (app_drawer.dart: onClearFilters is null otherwise); with no filter
      # it shows "Clear search". Run 40916686359: the Kerala pick had
      # failed, so this was reported as a missing button.
      fail_step "$entry-empty-clear" "prerequisite: Kerala did not apply, so no filter was active for Clear filters"
    else
      fail_step "$entry-empty-clear" "Clear filters was not shown with Kerala applied"
    fi
  else
    fail_step "$entry-empty-clear" "search field missing"
  fi
  force_stop_app
done
