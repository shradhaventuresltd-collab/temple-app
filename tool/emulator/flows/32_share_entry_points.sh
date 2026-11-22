#!/usr/bin/env bash
# Flow 32. Ux SHARE-SPEC.md sequences 1, 2, 4 and 7 (spec name
# 31_share_entry_points.sh; 31 is taken by 31_filter_chain.sh).
# The detail page's Share button (detail-share-button, under Get Directions
# in How to Reach) opens the system chooser exactly once, back returns to
# the same detail page, and that holds from Browse card, drawer Search and
# filtered results. The AVD has no WhatsApp, so the label is "Share" in
# both builds (sequence 4). Sourced by run_one_flow.sh.

# Chooser STARTs in a logcat window: Android 10-13 run
# com.android.internal.app.ChooserActivity, 14+ com.android.intentresolver.
count_chooser_starts() {
  grep -cE 'ActivityTaskManager: START u0 .*(act=android\.intent\.action\.CHOOSER|ChooserActivity)' || true
}

# Chooser on screen: a dump whose top package is the resolver, not ours.
chooser_shown() {
  [[ -s "${DUMP:-}" ]] || return 1
  grep -Eq 'package="(android|com\.android\.intentresolver)"' "$DUMP"
}

seek_share_button() {
  ui_wait_scrolled 25 --resource-id detail-share-button
}

# $1 step prefix, $2 taps (1 or 2). Leaves the app on detail on success.
share_once_and_back() {
  local where="$1" taps="$2" window starts
  seek_share_button || { fail_step "$where-seek" "Share not found on detail"; return 1; }
  if ui_find --content-desc-regex '^Share on WhatsApp' &&
     ! adb_shell_capped 8 pm path com.whatsapp >/dev/null 2>&1; then
    fail_step "$where-label" "label says WhatsApp but WhatsApp is not installed"
  else
    pass_step "$where-label"
  fi
  logcat_window_start "share-$where" || echo "share: TempleEmuMark marker not written" >&2
  adb_shell_capped 8 input tap "$UI_CX" "$UI_CY"
  if (( taps > 1 )); then
    adb_shell_capped 8 input tap "$UI_CX" "$UI_CY"
  fi
  sleep 3
  ui_dump || true
  step_shot "share-$where"
  if ! window="$(logcat_window_read)"; then
    fail_step "$where-single-chooser" "TempleEmuMark logcat marker missing: chooser STARTs cannot be counted"
  else
    starts="$(count_chooser_starts <<< "$window")"
    echo "share: chooser START lines after ${taps} tap(s) from ${where}: ${starts:-0}"
    if [[ "${starts:-0}" -eq 1 ]] || { [[ "${starts:-0}" -eq 0 ]] && chooser_shown; }; then
      pass_step "$where-single-chooser"
    else
      fail_step "$where-single-chooser" "${taps} tap(s) started the chooser ${starts:-0} times (want 1)"
    fi
  fi
  # Cancel the chooser: back lands on the same detail page, no SnackBar.
  ui_back
  sleep 1
  if ui_wait 8 --resource-id detail-share-button --package-contains "$PKG" ||
     back_until_detail 3; then
    ui_dump || true
    if ui_find --text-contains "open sharing"; then
      fail_step "$where-back" "cancelled chooser showed the share-failed SnackBar"
    else
      pass_step "$where-back"
    fi
  else
    fail_step "$where-back" "not on detail after closing the chooser"
    return 1
  fi
}

open_first_card() {
  ui_wait 15 --resource-id temple-browse-card || return 1
  ui_tap
  ui_wait_scrolled 25 --text-contains "How to Reach"
}

# Sequences 1 and 2 from a Browse card.
if ! err="$(reach_browse)"; then
  fail_step browse "${err:-could not open the temple list}"
  return 0
fi
pass_step browse
if open_first_card; then
  share_once_and_back browse 1 && share_once_and_back browse-double 2
else
  fail_step browse-open "detail did not open from a Browse card"
fi

# Sequence 7: drawer Search results.
force_stop_app
launch_app
accept_policy_if_shown || { fail_step search-enter "policy"; return 0; }
wait_for_home || { fail_step search-enter "home"; return 0; }
ui_dump && ui_find --content-desc "Open navigation menu" || {
  fail_step search-enter "drawer"
  return 0
}
ui_tap
sleep 1
if scroll_drawer_until --resource-id temple-list-search-field; then
  ui_tap
  ui_type "temple"
  adb_shell_capped 8 input keyevent 66 || true
  sleep 2
  if wait_browse_ready && open_first_card; then
    pass_step search-enter
    share_once_and_back search 1 || true
  else
    fail_step search-enter "no search result opened"
  fi
else
  fail_step search-enter "search field"
fi

# Sequence 7: filtered results (State = Kerala).
force_stop_app
launch_app
accept_policy_if_shown || { fail_step filter-enter "policy"; return 0; }
wait_for_home || { fail_step filter-enter "home"; return 0; }
if ! err="$(reach_browse)"; then
  fail_step filter-enter "${err:-could not open the temple list}"
  return 0
fi
if find_filter_chip filter-chip-state "" "Choose a state" && ui_tap &&
   wait_filter_sheet 15 && select_labeled '^Kerala( +[0-9]+)?$' STATE &&
   apply_sheet && open_first_card; then
  pass_step filter-enter
  share_once_and_back filter 1 || true
else
  fail_step filter-enter "Kerala results did not open a detail"
  recover_sheet || true
fi
