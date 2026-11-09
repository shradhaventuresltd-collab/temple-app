#!/usr/bin/env bash
# Flow 29. Filter chip matrix: every chip x action (select+apply, pick+close-X,
# dismiss-empty, clear) x then tap EVERY other chip, x entry point, plus 3+ step
# sequences. Regression for: District -> pick -> close sheet -> other chip dead.
# User Tester drafted this as flow 21. That number is Bug Hunter's
# district-close flow, so this copy is 29.
# Sourced by run_one_flow.sh (needs lib/common.sh).

CHIPS=(state district deity)
declare -A PICK=( [state]='^Tamil Nadu( +[0-9]+)?$' [deity]='^Shiva( +[0-9]+)?$' [district]='^Madurai( +[0-9]+)?$' )
declare -A APPLIED=()
declare -A SECTION=( [state]=STATE [deity]=DEITY [district]=DISTRICT )

open_drawer() {
  ui_dump && ui_find --content-desc "Open navigation menu" || return 1
  ui_tap; sleep 1
}
# Round 4.4.8 (run 41601153030, 29e first cell): the first launch after the
# install sat on the splash for 21s+ while the emulator's GL context was
# lost (logcat: EGL_BAD_CONTEXT, "Surface lost, forcing relayout"); the next
# launch drew in 3.6s. One relaunch before giving up on the entry.
fresh_home_once() {
  force_stop_app; launch_app; accept_policy_if_shown || return 1; wait_for_home
}
# Round 4.4.8b: emulator GPU context loss on the app's own process
# (29e, run 41601153030 shard 5: EGL_BAD_CONTEXT / eglMakeCurrent 0x3006 /
# "Surface lost, forcing relayout", first launch never displayed).
# Reads logcat threadtime text on stdin; pids from "Start proc <pid>:$PKG/".
app_gpu_context_lost_in_log() {
  local pkg="${1:-$PKG}"
  awk -v pkg="$pkg" '
    { line[NR] = $0 }
    match($0, /Start proc [0-9]+:[^ \/]+\//) {
      s = substr($0, RSTART + 11, RLENGTH - 12); split(s, a, ":")
      if (a[2] == pkg) pid[a[1]] = 1
    }
    END {
      for (i = 1; i <= NR; i++) { split(line[i], f, " ")
        if ((f[3] in pid) && line[i] ~ /EGL_BAD_CONTEXT|0x3006|Surface lost/) { found = 1; exit } }
      exit !found
    }'
}
fresh_home() {
  # Round 4.4.8b (Manu, Reviewer): relaunch ONCE only when home was not
  # reached AND, since the first launch, logcat shows the GPU context-loss
  # signature on the app's pid AND no FATAL EXCEPTION / ANR / "has stopped"
  # for the package under test ($PKG from the APK; com.shradhaventures.temple
  # in CI). Anything else (crash, no signature, unreadable logcat) FAILs
  # without a relaunch. A relaunch writes a RELAUNCH line that
  # release_gate.sh reports (count + flow ids), not a failure.
  local window
  logcat_window_start fresh_home || { record_fail "fresh_home" "logcat window could not start; not relaunching"; return 1; }
  fresh_home_once && return 0
  if ! window="$(logcat_window_read)"; then
    record_fail "fresh_home" "home not reached and logcat unreadable; not relaunching"; return 1
  fi
  if printf '%s\n' "$window" | app_crashed_in_log "$PKG"; then
    record_fail "fresh_home" "home not reached: ${PKG} crashed (FATAL EXCEPTION/ANR in logcat); not relaunching"; return 1
  fi
  if ! printf '%s\n' "$window" | app_gpu_context_lost_in_log "$PKG"; then
    record_fail "fresh_home" "home not reached, no GPU context-loss signature for ${PKG}; not relaunching"; return 1
  fi
  echo "fresh_home: home not reached after GPU context loss; relaunching the app once" >&2
  printf 'RELAUNCH %s: fresh_home: home not reached, EGL context lost on %s (no crash/ANR); relaunched the app once\n' "$FLOW" "$PKG" | tee -a "$RESULTS"
  fresh_home_once
}
enter_home_browse() {
  fresh_home || return 1
  open_browse || return 1
  wait_browse_ready
}
enter_drawer_all() {
  fresh_home || return 1; open_drawer || return 1
  ui_wait_scrolled 15 --text-regex '^All Temples' || return 1
  ui_tap; wait_browse_ready
}
# Filters inside the drawer itself (the "District from drawer" bar).
# The drawer sheet filters "the temples already loaded": opened before the
# list loads it offers "Any state 0" and "Show 0 temples" (run 41373837994,
# 30 drawer_bar-state-select, first cell after boot). Wait for a non-zero
# "All Temples" count first. The FILTERS row sits at ~75% of the height,
# below the 70% chip band of the list screens: CHIP_MAX_TOP_PCT=95.
enter_drawer_bar() {
  fresh_home || return 1; open_drawer || return 1
  ui_wait 30 --content-desc-regex '^All Temples\s+[1-9][0-9]*$' || return 1
  CHIP_MAX_TOP_PCT=95
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

# Every chip scrolls into view in both directions (find_filter_chip): after
# district/deity probes the row is scrolled right and the state chip is off
# the left edge (run 41373837994, 29 home_browse-state-select-then-state).
chip_present() {
  ui_dump || return 1
  case "$1" in
    state) find_filter_chip filter-chip-state "" "Choose a state" ;;
    district) find_filter_chip filter-chip-district "" "Choose a district" ;;
    deity) find_filter_chip filter-chip-deity "" "Choose a deity" ;;
  esac
}
open_chip() {
  chip_present "$1" || return 1
  ui_tap
  wait_filter_sheet 20 || return 1
  # The district sheet opens with a loader. Names can take several seconds
  # on the first load. filter-district-loading is a resource-id, not title text.
  if [[ "$1" == district ]]; then
    ui_dump || return 1
    if ui_find --resource-id filter-district-loading \
      || ui_find --text-contains "Loading districts"; then
      wait_out_district_loader || return 1
    fi
  fi
}
close_x() {
  ui_dump && ui_find --resource-id filter-sheet-close || ui_find --content-desc "Close filters" || return 1
  ui_tap; sleep 1; ! sheet_open
}

# Action leaves the sheet closed; returns 0 if the action itself worked.
# The pick is scoped (round 4.3, scoped_pick in lib/common.sh): Shiva and
# Madurai only when the state chip already shows Tamil Nadu, otherwise the
# head-of-list all-India picks. PICK keeps the Tamil Nadu targets.
do_action() {
  local chip="$1" action="$2" pick rc=0
  case "$action" in
    select|pick-close|clear)
      open_chip "$chip" || rc=1
      if (( rc == 0 )) && [[ "$chip" == district ]] && declare -F finish_choose_state_first >/dev/null; then
        finish_choose_state_first || rc=1
      fi
      if (( rc == 0 )); then pick="$(scoped_pick "$chip")" || pick="${PICK[$chip]}"; fi
      ;;
    *) pick="${PICK[$chip]}" ;;
  esac
  if (( rc == 0 )); then
    case "$action" in
      select) select_labeled "$pick" "${SECTION[$chip]}" && apply_sheet || rc=1 ;;
      pick-close) select_labeled "$pick" "${SECTION[$chip]}" && close_x || rc=1 ;;
      dismiss-empty) open_chip "$chip" && dismiss_sheet_swipe || rc=1 ;;
      back-empty) open_chip "$chip" && { ui_back; sleep 1; ! sheet_open; } || rc=1 ;;
      outside-empty) open_chip "$chip" && dismiss_sheet_outside || rc=1 ;;
      clear) select_labeled "$pick" "${SECTION[$chip]}" && apply_sheet && clear_named "$chip" || rc=1 ;;
    esac
  fi
  # Round 4.4.1: what should still be applied, for seqN-filter-kept. A
  # state change resets the district, so district is only known until then.
  if (( rc == 0 )); then
    case "$action" in
      select) [[ "$chip" == state ]] && unset 'APPLIED[district]'; APPLIED[$chip]="$SELECTED_LABEL" ;;
      clear) unset "APPLIED[$chip]"; [[ "$chip" == state ]] && unset 'APPLIED[district]' ;;
    esac
  fi
  return "$rc"
}

# Round 4.4.2: with nothing applied, the chip bar is on screen and
# filter-clear (built only while a filter is active) is not.
none_applied_ok() {
  FILTER_KEPT_WHY=""
  if ! filter_bar_present; then FILTER_KEPT_WHY="filter bar missing after detail"; return 1; fi
  if ui_find --resource-id filter-clear; then FILTER_KEPT_WHY="filter-clear shown with no filter applied"; return 1; fi
  return 0
}

# Expected KIND=LABEL pairs for filter_kept.
applied_pairs() {
  local k
  for k in "${!APPLIED[@]}"; do printf '%s=%s\n' "$k" "${APPLIED[$k]}"; done
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

# The bug check: every other chip must open a sheet after the action.
# District's first load can take longer than a chip tap. State and deity stay at 3 s.
probe_others() {
  local id="$1" done_chip="$2" other in_dump state_selected outcome
  # CHIPS already holds done_chip; the old extra re-tap of it repeated the
  # same probe and cost ~25s a cell.
  : "$done_chip"
  for other in "${CHIPS[@]}"; do
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
        if [[ "$outcome" == xfail ]] && chip_bar_only_district_missing; then
          xfail_known "$id-then-$other" KAN-190 "district chip hidden with no state selected" district_chip_reappears
          continue
        fi
        if [[ "$outcome" == xfail ]]; then
          fail_step "$id-then-$other" "filter chip bar not on screen"
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
    local wait_s=3
    if [[ "$other" == district ]]; then
      wait_s=10
    fi
    if wait_filter_sheet "$wait_s"; then
      pass_step "$id-then-$other"; ui_back; sleep 1; recover_sheet
    else
      fail_step "$id-then-$other" "tap on ${other} chip did nothing after ${id}"
    fi
  done
}

# One 1140s budget died at cell 47, still inside the first half of this
# matrix, so the 3+ step sequences never started. Part a is home + drawer
# All Temples. Part b is the drawer bar, Search, near me, and the sequences.
# Run 41373837994: part a reached cell 32 of 90 and part b cell 24 at the
# 600s cap. plan.sh now runs one entry x one chip per flow:
# FILTER_MATRIX_PART=<entry>:<chip> (e.g. drawer_bar:state), or "seqs".
MATRIX_CHIPS=("${CHIPS[@]}")
case "${FILTER_MATRIX_PART:-all}" in
  seqs)
    ENTRIES=()
    RUN_SEQS=1
    ;;
  # Round 4.4.8: one sequence per flow (30s1-30s5). The five sequences took
  # ~226-260s each (run 41601153030: seq1 260s, seq2 226s), so one 600s flow
  # never got past seq3.
  seqs:[1-5])
    ENTRIES=()
    RUN_SEQS=1
    SEQ_ONLY="${FILTER_MATRIX_PART#seqs:}"
    ;;
  *:*)
    ENTRIES=("${FILTER_MATRIX_PART%%:*}")
    if [[ "${FILTER_MATRIX_PART##*:}" != all ]]; then
      MATRIX_CHIPS=("${FILTER_MATRIX_PART##*:}")
    fi
    RUN_SEQS=0
    ;;
  a)
    ENTRIES=(home_browse drawer_all)
    RUN_SEQS=0
    ;;
  b)
    ENTRIES=(drawer_bar search near_me)
    RUN_SEQS=1
    ;;
  *)
    ENTRIES=(home_browse drawer_all drawer_bar search near_me)
    RUN_SEQS=1
    ;;
esac
ACTIONS=(select pick-close dismiss-empty back-empty outside-empty clear)

for entry in "${ENTRIES[@]}"; do
  # shellcheck disable=SC2034 # read by lib/common.sh chip lookups
  CHIP_MAX_TOP_PCT=70
  for chip in "${MATRIX_CHIPS[@]}"; do
    for action in "${ACTIONS[@]}"; do
      id="$entry-$chip-$action"
      step_reset
      APPLIED=()  # each cell starts from a fresh entry (scoped_pick reads APPLIED)
      CHOOSE_STATE_APPLIED=""
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
if [[ "$RUN_SEQS" -eq 1 ]]; then
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
  [[ -n "${SEQ_ONLY:-}" && "$n" != "$SEQ_ONLY" ]] && continue
  enter_home_browse >/dev/null 2>&1 || { fail_step "seq$n-enter" "browse not reached"; continue; }
  APPLIED=()
  CHOOSE_STATE_APPLIED=""
  ok=1
  for st in $seq; do
    # Round 4.4.9g (run 41825986479 shard 9): no result line is written
    # between a sequence's actions, so the 150s step clock ran from the flow
    # start (install + Home + 3 actions) and cut seq5's 4th action. Each
    # action gets its own step budget; the 540s flow cap still bounds it.
    step_reset
    do_action "${st%%:*}" "${st##*:}" || { ok=0; fail_step "seq$n-$st" "step failed"; recover_sheet; break; }
  done
  [[ $ok -eq 1 ]] && pass_step "seq$n" && probe_others "seq$n" "${st%%:*}"
  # then detail -> back -> probe
  if ui_wait_scrolled 20 --resource-id temple-browse-card; then
    ui_tap; ui_wait_scrolled 20 --text-contains "How to Reach" && ui_back; sleep 2
    ui_dump || true
    # Round 4.4.1 (Manu): a filter should still be applied, so filter-clear
    # (and the applied labels) are required; chips alone do not pass.
    mapfile -t kept < <(applied_pairs)
    if (( ${#kept[@]} == 0 )); then
      # Nothing applied: the bar must be there and filter-clear must not.
      if none_applied_ok; then pass_step "seq$n-filter-kept"; else fail_step "seq$n-filter-kept" "$FILTER_KEPT_WHY"; fi
    elif filter_kept "${kept[@]}"; then
      pass_step "seq$n-filter-kept"
    else
      fail_step "seq$n-filter-kept" "filter lost after detail: ${FILTER_KEPT_WHY}"
    fi
    probe_others "seq$n-after-detail" state
  fi
done
fi
force_stop_app
