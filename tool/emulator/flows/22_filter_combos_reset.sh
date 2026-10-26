#!/usr/bin/env bash
# Flow 22 (bughunter). Order/combination and reset. Distinct from 06/17:
# state->district->state change (stale district drop),
# deity first then state, Clear in-sheet vs bar Clear, filter + search query,
# 0-result combo.
# Picker scroll does not stop on the first no-op swipe. The finger can land
# on a chip (that used to stop at Ganesha and the A-districts). select_labeled
# retries other finger heights, then gives up on a 120s cap. This flow fails
# the step instead of scrolling again.
reach_browse || { fail_step browse "no list"; return 0; }
count() { ui_dump; ui_find --text-regex '^[0-9]+ temples?$' && echo "${UI_TEXT%% *}"; }

# Scroll the chip into view, open the sheet, and walk the picker.
# A miss hits select_labeled's cap and fails $step.
pick_labeled() {
  local rid="$1"
  local regex="$2"
  local section="$3"
  local step="$4"
  if ! find_filter_chip "$rid" "" ""; then
    echo "flow 22: ${rid} was not on the chip bar" >&2
    fail_step "$step" "could not scroll ${rid} into view"
    return 1
  fi
  ui_tap
  if ! ui_wait 12 --text-regex '^Filters$'; then
    fail_step "$step" "filter sheet did not open"
    return 1
  fi
  if ! select_labeled "$regex" "$section"; then
    echo "flow 22: picker scroll gave up before ${regex}" >&2
    fail_step "$step" "picker scroll gave up before ${regex}"
    recover_sheet
    return 1
  fi
  if ! apply_sheet; then
    echo "flow 22: apply was not tappable after ${regex}" >&2
    fail_step "$step" "apply did not close the sheet"
    recover_sheet
    return 1
  fi
  return 0
}

pick_labeled filter-chip-deity '^Shiva' DEITY deity-first && pass_step deity-first
pick_labeled filter-chip-state '^Kerala' STATE state-second && pass_step state-second
c1=$(count)
pick_labeled filter-chip-district '^(Thrissur|Ernakulam|Thiruvananthapuram)' DISTRICT district-pick || true
# change state: district must drop, not leave a 0-result hidden filter
pick_labeled filter-chip-state '^Tamil Nadu' STATE state-change || true
ui_dump; ui_find --text-regex '^(Thrissur|Ernakulam|Thiruvananthapuram)$' && fail_step stale-district "Kerala district chip survives state=Tamil Nadu" || pass_step stale-district
ui_find --text-contains "No temples" && fail_step tn-shiva-empty "0 results for TN+Shiva (stale district?)" || pass_step tn-shiva-empty
# search + filters
ui_find --resource-id temple-list-search-field && ui_tap && ui_type "zzzqqq" && adb_shell_capped 8 input keyevent 66; sleep 2
ui_dump; ui_find --text-contains "No temples" && pass_step empty-state-shown || fail_step empty-state-shown "no empty state for nonsense query+filters"
ui_dump && ui_find --text-regex '^Clear$' --prefer upper && ui_tap; sleep 1
ui_dump; ui_find --resource-id filter-chip-state --text-regex '^State$' >/dev/null
c3=$(count); [[ -z "$c3" ]] || [[ "$c3" -lt 900 ]] && fail_step bar-clear "Clear left count=$c3 (query kept? filters kept?)" || pass_step bar-clear
# in-sheet Clear then dismiss must NOT apply
if pick_labeled filter-chip-deity '^Vishnu' DEITY sheet-clear-dismiss-keeps; then
  ui_dump && ui_find --resource-id filter-chip-deity && ui_tap && sleep 1
  ui_dump && ui_find --resource-id filter-sheet-clear && ui_tap; ui_back; sleep 1
  ui_dump; ui_find --text-regex 'Vishnu' && pass_step sheet-clear-dismiss-keeps || fail_step sheet-clear-dismiss-keeps "dismissed draft clear was applied"
fi
: "${c1:-}"
