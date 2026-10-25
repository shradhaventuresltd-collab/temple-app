#!/usr/bin/env bash
# Flow 22 (bughunter). Order/combination and reset. Distinct from 06/17:
# state->district->state change (stale district drop, sheet :420-431),
# deity first then state, Clear in-sheet vs bar Clear, filter + search query, 0-result combo.
reach_browse || { fail_step browse "no list"; return 0; }
count() { ui_dump; ui_find --text-regex '^[0-9]+ temples?$' && echo "${UI_TEXT%% *}"; }
ui_find --resource-id filter-chip-deity && ui_tap && sleep 1
select_labeled '^Shiva' DEITY && apply_sheet && pass_step deity-first || fail_step deity-first "no Shiva"
ui_dump && ui_find --resource-id filter-chip-state && ui_tap && sleep 1
select_labeled '^Kerala' STATE && apply_sheet && pass_step state-second || fail_step state-second "no Kerala"
c1=$(count)
ui_dump && ui_find --resource-id filter-chip-district && ui_tap && sleep 3
select_labeled '^(Thrissur|Ernakulam|Thiruvananthapuram)' DISTRICT && apply_sheet
# change state: district must drop, not leave a 0-result hidden filter
ui_dump && ui_find --resource-id filter-chip-state && ui_tap && sleep 1
select_labeled '^Tamil Nadu' STATE && apply_sheet
ui_dump; ui_find --text-regex '^(Thrissur|Ernakulam|Thiruvananthapuram)$' && fail_step stale-district "Kerala district chip survives state=Tamil Nadu" || pass_step stale-district
ui_find --text-contains "No temples" && fail_step tn-shiva-empty "0 results for TN+Shiva (stale district?)" || pass_step tn-shiva-empty
# search + filters
ui_find --resource-id temple-list-search-field && ui_tap && ui_type "zzzqqq" && adb shell input keyevent 66; sleep 2
ui_dump; ui_find --text-contains "No temples" && pass_step empty-state-shown || fail_step empty-state-shown "no empty state for nonsense query+filters"
ui_dump && ui_find --text-regex '^Clear$' --prefer upper && ui_tap; sleep 1
ui_dump; ui_find --resource-id filter-chip-state --text-regex '^State$' >/dev/null
c3=$(count); [[ -z "$c3" ]] || [[ "$c3" -lt 900 ]] && fail_step bar-clear "Clear left count=$c3 (query kept? filters kept?)" || pass_step bar-clear
# in-sheet Clear then dismiss must NOT apply
ui_dump && ui_find --resource-id filter-chip-deity && ui_tap && sleep 1
select_labeled '^Vishnu' DEITY && apply_sheet
ui_dump && ui_find --resource-id filter-chip-deity && ui_tap && sleep 1
ui_dump && ui_find --resource-id filter-sheet-clear && ui_tap; ui_back; sleep 1
ui_dump; ui_find --text-regex 'Vishnu' && pass_step sheet-clear-dismiss-keeps || fail_step sheet-clear-dismiss-keeps "dismissed draft clear was applied"
