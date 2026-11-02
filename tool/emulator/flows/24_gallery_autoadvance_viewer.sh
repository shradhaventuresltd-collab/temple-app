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
# One fling, then dump and compare (round 4.3). The gallery auto-advances
# every 5s and wraps ((_currentPage + 1) % length, temple_detail_screen.dart
# :200): six flings 0.3s apart took ~8s on 5 pages, reached the end and
# wrapped back to the start index (run 41391038302: "1 -> 1", later "2 / 5").
# The fling must page the gallery (run 41314245431: flings were vertical).
# PageView clamps: on the last page a forward fling cannot move, so step
# back first.
ui_dump; page_before="$(gallery_page || echo none)"; n_pages="$(gallery_count)"
# Up to 2 tries: a timer tick can undo the step back off the last page.
for _ in 1 2; do
  for _ in 1 2; do
    [[ "$page_before" != none ]] && (( n_pages > 1 && page_before == n_pages - 1 )) || break
    # Two back flings: -2, so one timer tick (+1) still leaves the last page.
    ui_fling right; ui_fling right; ui_dump; page_before="$(gallery_page || echo none)"
  done
  ui_fling left
  ui_dump; page_after="$(gallery_page || echo none)"
  [[ "$page_after" == "$page_before" && "$page_after" != none ]] || break
  page_before="$page_after"
done
# Round 4.3.1/4.3.2: the timer only moves forward, so a forward change (or
# a wrap to page 0) can be the timer alone. A window is flings + one dump
# (~3.3-4.3s, under the 5s period: at most one advance per window).
#  - 4+ pages: from a page in [2, last-1], two back flings then a dump must
#    land BELOW it (swipes -2, clamped at 0; the timer at most +1). The timer
#    alone gives the same page, +1, or last -> 0 (not counted).
#  - 3 pages: from page 1, the same window must show 0; the timer needs two
#    advances (1 -> 2 -> 0) to get there, which one window cannot hold.
#  - 2 pages: every swipe result (1 -> 0, 0 -> 1) is also the timer's next
#    page, and a ~3.3s window holds a tick 2/3 of the time, so no window
#    pattern separates a swipe from the timer (round 4.3.2 replay: three
#    clean windows in a row passed 0/20 with a real swipe). Recorded as NA,
#    never a weak PASS.
# At most 3 tries; each try first steps to its start page with single flings.
back_trace="${page_after}"
back_ok=0
slow_windows=""
if (( n_pages >= 4 )); then lo=2; hi=$((n_pages - 2)); else lo=1; hi=1; fi
two_page=0
(( n_pages == 2 )) && two_page=1
if (( ! two_page )) && [[ "$page_before" != none && "$page_after" != none && "$page_after" != "$page_before" ]]; then
  cur="$page_after"
  for _ in 1 2 3; do
    for _ in 1 2 3; do
      [[ "$cur" == none ]] && break
      if (( cur < lo )); then ui_fling left
      elif (( cur > hi )); then ui_fling right
      else break; fi
      ui_dump; cur="$(gallery_page || echo none)"; back_trace+=" ~${cur}"
    done
    [[ "$cur" == none ]] && break
    (( cur >= lo && cur <= hi )) || continue
    w0="$(mono_now)"
    ui_fling right; ui_fling right
    ui_dump; nb="$(gallery_page || echo none)"; back_trace+=" <<${nb}"
    # Round 4.3.3: the one-tick-per-window argument needs the window under
    # the 5s timer period. A slower window can hold two ticks, so its
    # result proves nothing (recorded, not trusted).
    w="$(python3 -c "print(round($(mono_now) - $w0, 2))")"
    if python3 -c "import sys; sys.exit(0 if $w > ${GALLERY_TICK_S:-5} else 1)"; then
      slow_windows+=" ${w}s"; back_trace+="(slow ${w}s)"
      [[ "$nb" == none ]] && break
      cur="$nb"; continue
    fi
    [[ "$nb" == none ]] && break
    if (( nb < cur )) && ! (( cur == n_pages - 1 && nb == 0 )); then back_ok=1; break; fi
    cur="$nb"
  done
fi
if (( two_page )); then
  # A forward fling plus a tick also reads "unchanged", so not even the
  # forward check is meaningful on 2 pages.
  na_step swipe-pages "2-page gallery: a swipe and the 5s auto-advance wrap give the same pages (${page_before} -> ${page_after}); not provable from dumps"
elif [[ "$page_after" == none || "$page_after" == "$page_before" ]]; then
  fail_step swipe-pages "one fling did not change the page (${page_before} -> ${page_after})"
elif (( back_ok )); then
  pass_step swipe-pages
elif [[ -n "$slow_windows" ]]; then
  na_step swipe-pages "weak: fling+dump window(s)${slow_windows} over the ${GALLERY_TICK_S:-5}s timer period, so a page change cannot be told from the timer (${page_before} -> ${back_trace})"
else
  fail_step swipe-pages "fling back did not move the page back (${page_before} -> ${back_trace}; the timer only moves forward)"
fi
for _ in 1 2 3 4 5 6; do ui_fling right; sleep 0.3; done; step_shot swipe-burst
# The timer keeps auto-advancing, so the page after the burst is not fixed.
# Let the last fling and any advance settle, then check the counter against
# the page on screen: two consecutive dumps 0.8s apart must each be
# consistent and show the same page.
sleep 1.5
burst_ok=0
prev_page=""
for _ in 1 2 3 4 5; do
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
network_off; for _ in 1 2 3; do ui_fling left; sleep 1; done; step_shot offline-gallery
ui_dump; ui_find --text-contains "Exception" && fail_step offline-photo "raw error text" || pass_step offline-photo; network_on
