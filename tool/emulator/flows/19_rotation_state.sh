#!/usr/bin/env bash
# Flow 19. Rotation and state on list (each entry), sheet open, detail.
# Apply Kerala before rotating. A failed select used to leave the sheet
# open (screenshot 01_), and the rotation check then never saw the chip.
rotate() { adb shell settings put system accelerometer_rotation 0; adb shell settings put system user_rotation "$1"; sleep 2; }
reach_browse || { fail_step browse "no list"; return 0; }
if ! scroll_chips_until --resource-id filter-chip-state || ! ui_tap || ! ui_wait 12 --text-regex '^Filters$' \
  || ! select_labeled '^Kerala( +[0-9]+)?$' STATE || ! apply_sheet || ! chip_exact Kerala; then
  fail_step apply-kerala "Kerala was not applied"
  recover_sheet
  return 0
fi
rotate 1
chip_exact Kerala && pass_step rotate-list-keeps-filter || fail_step rotate-list-keeps-filter "filter lost on rotation"
scroll_chips_until --resource-id filter-chip-state && ui_tap && ui_wait 12 --text-regex '^Filters$'
rotate 0
sheet_open && pass_step rotate-sheet-stays || fail_step rotate-sheet-stays "sheet vanished on rotation"
recover_sheet
ui_fling up; ui_fling up; rotate 1; rotate 0
chip_exact Kerala && pass_step rotate-back-keeps-filter || fail_step rotate-back-keeps-filter "filter lost"
adb shell settings put system accelerometer_rotation 1
