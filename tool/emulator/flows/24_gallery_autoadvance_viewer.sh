#!/usr/bin/env bash
# Flow 24 (bughunter). Detail gallery. temple_detail_screen.dart:239-249 timer
# auto-advances forever: while a finger is mid-swipe, while the full-size
# InteractiveViewer (:1082) is zoomed, and in background. :315 gallery[_currentPage]
# can RangeError if frames shrink (full-size swap / photo failing).
reach_browse || { fail_step browse "no list"; return 0; }
# --- multi-photo open begin
# Open a temple KNOWN to have several photos by searching its name:
# "Aazhimala Shiva Temple" showed '1 / 5' in runs 41314245431 and
# 41373837994 (EMULATOR_MULTI_PHOTO_QUERY overrides). The old walk over
# the first 3 cards recorded a blanket "not applicable" PASS whenever it
# did not see '1 / N', even after a failed scroll/tap or on the wrong
# screen. Now:
#   detail page + '1 / 2..N'            -> PASS multi-photo, paging checks run
#   detail page + proven single photo   -> NA multi-photo ('1 / 1', or one
#     ('1 / 1' or one gallery page,       detail-gallery page and no counter);
#      no counter)                        the paging checks are NA too
#   anything else (search, tap, screen) -> FAIL multi-photo, paging checks
#                                          still run (and fail)
MULTI_QUERY="${EMULATOR_MULTI_PHOTO_QUERY:-Aazhimala}"
on_detail() {
  ui_find --resource-id-regex '^detail-gallery-[0-9]+$' || ui_find --text-contains "How to Reach"
}
gallery_single_proven() {
  python3 - "$DUMP" <<'PY'
import re, sys
s = open(sys.argv[1], encoding="utf-8", errors="replace").read()
counters = re.findall(r'(?:text|content-desc)="(\d+) / (\d+)"', s)
pages = set(re.findall(r'resource-id="detail-gallery-(\d+)"', s))
if counters:
    sys.exit(0 if all(t == "1" for _, t in counters) else 1)
sys.exit(0 if pages == {"0"} else 1)
PY
}
MULTI=0
SINGLE=0
open_why=""
if ! ui_replace_field_text "$MULTI_QUERY"; then
  open_why="search for '${MULTI_QUERY}' failed (field: ${UI_FIELD_ACTUAL:-?})"
else
  adb_shell_capped 8 input keyevent 66 >/dev/null 2>&1 || true
  sleep 2
  if ! ui_wait_scrolled 15 --resource-id temple-browse-card --text-contains "$MULTI_QUERY"; then
    open_why="no '${MULTI_QUERY}' card after the search"
  elif ! ui_tap; then
    open_why="tap on the '${MULTI_QUERY}' card failed"
  else
    sleep 3
    if ! ui_dump || ! on_detail; then
      open_why="not on the detail page after tapping '${MULTI_QUERY}'"
    elif ui_find --text-regex '^1 / [2-9][0-9]*$'; then
      MULTI=1
    elif gallery_single_proven; then
      SINGLE=1
    else
      open_why="detail page shows no readable photo counter or gallery"
    fi
  fi
fi
if (( MULTI )); then
  pass_step multi-photo
elif (( SINGLE )); then
  na_step multi-photo "'${MULTI_QUERY}' has a single photo (proven '1 / 1' / one gallery page)"
else
  fail_step multi-photo "$open_why"
fi
# --- multi-photo open end
if (( SINGLE )); then
  na_step swipe-pages "single-photo temple"
  na_step swipe-burst-index "single-photo temple"
fi
if (( ! SINGLE )); then
ui_dump; page_before="$(gallery_page || echo none)"
for i in 1 2 3 4 5 6; do ui_fling left; sleep 0.3; done
# The flings must page the gallery (run 41314245431: they were vertical).
ui_dump; page_after="$(gallery_page || echo none)"
if [[ "$page_before" != none && "$page_after" != none && "$page_after" != "$page_before" ]]; then
  pass_step swipe-pages
else
  fail_step swipe-pages "flings did not change the page (${page_before} -> ${page_after})"
fi
for i in 1 2 3 4 5 6; do ui_fling right; sleep 0.3; done; step_shot swipe-burst
# The timer keeps auto-advancing, so the page after the burst is not fixed.
# Let the last fling and any advance settle, then check the counter against
# the page on screen: two consecutive dumps 0.8s apart must each be
# consistent and show the same page.
sleep 1.5
burst_ok=0
prev_page=""
for i in 1 2 3 4 5; do
  if ui_dump && gallery_index_consistent; then
    cur_page="$(gallery_page || true)"
    if [[ -n "$prev_page" && "$cur_page" == "$prev_page" ]]; then burst_ok=1; break; fi
    prev_page="$cur_page"
  else
    prev_page=""
  fi
  sleep 0.8
done
[[ "$burst_ok" -eq 1 ]] && pass_step swipe-burst-index || fail_step swipe-burst-index "index/counter desync"
fi
# double-tap / tap to open full size, pinch is not possible; hold 10s for timer
ui_dump; ui_find --resource-id detail-gallery-0 && { ui_tap; sleep 1; ui_tap; }; sleep 10
dump_logcat; grep -q "RangeError\|FlutterError" "$LOG_DIR"/* 2>/dev/null && fail_step gallery-errors "RangeError in logcat" || pass_step gallery-errors
ui_home_key; sleep 20; resume_app; sleep 2; ui_dump && pass_step bg-resume
network_off; for i in 1 2 3; do ui_fling left; sleep 1; done; step_shot offline-gallery
ui_dump; ui_find --text-contains "Exception" && fail_step offline-photo "raw error text" || pass_step offline-photo; network_on
