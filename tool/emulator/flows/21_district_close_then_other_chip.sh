#!/usr/bin/env bash
# Flow 21 (bughunter). Known open bug: District -> pick a district -> close
# (X / back / swipe / scrim, NOT apply) -> State / Deity chip must open.
# Also after Apply. Suspect: directory_filter_bar.dart:172-200 (no re-entrancy
# guard, awaits prepare() before pushing the sheet; Listener pop at :370-405).
other_chip_opens() {
  local which="$1"
  ui_dump && ui_find --resource-id "filter-chip-$which" || return 1
  ui_tap; sleep 1.5
  sheet_open || return 1
  ui_back; sleep 1; ! sheet_open
}
open_district() {
  ui_dump && ui_find --resource-id filter-chip-district || { scroll_chips_until --resource-id filter-chip-district || return 1; }
  ui_tap; sleep 3; sheet_open
}
close_how() {
  case "$1" in
    x) ui_dump && ui_find --content-desc "Close filters" && ui_tap ;;
    back) ui_back ;;
    swipe) dismiss_sheet_swipe ;;
    outside) dismiss_sheet_outside ;;
    apply) apply_sheet ;;
  esac
  sleep 1.5
}
reach_browse || { fail_step browse "could not reach list"; return 0; }
for how in x back swipe outside apply; do
  for other in state deity; do
    tag="district-select-${how}-then-${other}"
    open_district || { fail_step "$tag" "district sheet did not open"; recover_sheet; continue; }
    select_labeled '^(?!All districts).+ · ?[0-9]+' DISTRICT || select_labeled '^[A-Z][a-z]+' DISTRICT
    close_how "$how"
    if sheet_open; then fail_step "$tag" "sheet still open after $how"; recover_sheet; continue; fi
    other_chip_opens "$other" && pass_step "$tag" || fail_step "$tag" "$other chip dead after district+$how"
    clear_named district >/dev/null 2>&1 || true
  done
done
# Fast double-tap on District while boundaries load (no _opening guard -> two sheets stacked?)
ui_dump && ui_find --resource-id filter-chip-district && { adb shell input tap "$UI_CX" "$UI_CY"; adb shell input tap "$UI_CX" "$UI_CY"; sleep 4; }
ui_back; sleep 1
sheet_open && fail_step district-double-tap "second sheet left after one back (stacked sheets)" || pass_step district-double-tap
other_chip_opens deity && pass_step after-double-tap-deity || fail_step after-double-tap-deity "deity dead"
