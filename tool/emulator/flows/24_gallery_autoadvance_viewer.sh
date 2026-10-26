#!/usr/bin/env bash
# Flow 24 (bughunter). Detail gallery. temple_detail_screen.dart:239-249 timer
# auto-advances forever: while a finger is mid-swipe, while the full-size
# InteractiveViewer (:1082) is zoomed, and in background. :315 gallery[_currentPage]
# can RangeError if frames shrink (full-size swap / photo failing).
reach_browse || { fail_step browse "no list"; return 0; }
if ! ui_dump || ! ui_find --resource-id temple-browse-card; then
  fail_step open-card "no temple card"
  return 0
fi
ui_tap; sleep 3
ui_dump; ui_find --text-regex '^1 / [2-9]' && pass_step multi-photo || { skip_step multi-photo "single photo temple"; }
for i in 1 2 3 4 5 6; do ui_fling left; sleep 0.3; done
for i in 1 2 3 4 5 6; do ui_fling right; sleep 0.3; done; step_shot swipe-burst
ui_dump; ui_find --text-regex '^1 / ' && pass_step swipe-burst-index || fail_step swipe-burst-index "index/counter desync"
# double-tap / tap to open full size, pinch is not possible; hold 10s for timer
ui_dump; ui_find --resource-id detail-gallery-0 && { ui_tap; sleep 1; ui_tap; }; sleep 10
dump_logcat; grep -q "RangeError\|FlutterError" "$LOG_DIR"/* 2>/dev/null && fail_step gallery-errors "RangeError in logcat" || pass_step gallery-errors
ui_home_key; sleep 20; resume_app; sleep 2; ui_dump && pass_step bg-resume
network_off; for i in 1 2 3; do ui_fling left; sleep 1; done; step_shot offline-gallery
ui_dump; ui_find --text-contains "Exception" && fail_step offline-photo "raw error text" || pass_step offline-photo; network_on
