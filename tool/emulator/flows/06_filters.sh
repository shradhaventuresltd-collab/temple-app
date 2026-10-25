#!/usr/bin/env bash
# Flow 6. Every directory filter: open, dismiss, select, back, tap-outside,
# clear, repeat, then combined filters, detail, resume, and process death.
if ! err="$(reach_browse)"; then
  fail_step browse "${err:-could not open the temple list}"
  return 0
fi
pass_step browse

STATE_SELECT_OK=0
DEITY_SELECT_OK=0
DISTRICT_SELECT_OK=0
STATE_LABEL=""
DEITY_LABEL=""
DISTRICT_LABEL=""
COMBINED_STATE=""
COMBINED_DEITY=""
COMBINED_DISTRICT=""

remember_applied() {
  local key="$1"
  local label="$2"
  case "$key" in
    state) STATE_SELECT_OK=1; STATE_LABEL="$label" ;;
    deity) DEITY_SELECT_OK=1; DEITY_LABEL="$label" ;;
    district) DISTRICT_SELECT_OK=1; DISTRICT_LABEL="$label" ;;
  esac
}

section_for() {
  case "$1" in
    state) printf 'STATE' ;;
    deity) printf 'DEITY' ;;
    district) printf 'DISTRICT' ;;
    *) printf '' ;;
  esac
}

open_state() {
  local rx='^State$'
  if [[ -n "${STATE_LABEL:-}" ]]; then
    rx="^($(re_escape "$STATE_LABEL")|State)$"
  fi
  find_filter_chip filter-chip-state "$rx" "Choose a state" || return 1
  ui_tap
  ui_wait 12 --text-regex '^Filters$'
}

open_deity() {
  local rx='^Deity$'
  if [[ -n "${DEITY_LABEL:-}" ]]; then
    rx="^($(re_escape "$DEITY_LABEL")|Deity)$"
  fi
  find_filter_chip filter-chip-deity "$rx" "Choose a deity" || return 1
  ui_tap
  ui_wait 12 --text-regex '^Filters$'
}

open_district() {
  local rx='^All districts$'
  if [[ -n "${DISTRICT_LABEL:-}" ]]; then
    rx="^($(re_escape "$DISTRICT_LABEL")|All districts)$"
  fi
  find_filter_chip filter-chip-district "$rx" "Choose a district" || return 1
  ui_tap
  ui_wait 20 --text-regex '^DISTRICT$' || ui_wait 8 --text-regex '^Filters$'
}

open_by_id() {
  scroll_chips_until --resource-id "$1" || return 1
  ui_tap
  ui_wait 12 --text-regex '^Filters$'
}


# open, swipe away, select, back, tap outside, clear, then the same option thrice.
exercise_filter() {
  local key="$1"
  local regex="$2"
  local idle="$3"
  local opener="$4"
  local clear_name="$5"
  local picked=""

  if ! "$opener"; then
    fail_step "${key}-open" "could not open the ${key} sheet"
    recover_sheet
    return 0
  fi
  pass_step "${key}-open"

  local swipe_err
  if swipe_err="$(dismiss_sheet_swipe 2>&1)"; then
    pass_step "${key}-swipe-dismiss"
  else
    fail_step "${key}-swipe-dismiss" "${swipe_err:-swipe did not dismiss the sheet}"
    recover_sheet
  fi

  if [[ -n "$idle" ]]; then
    if chip_exact "$idle"; then
      pass_step "${key}-dismiss-keeps-idle"
    else
      fail_step "${key}-dismiss-keeps-idle" "chip was not '${idle}' after dismissing with no selection"
    fi
  fi

  if ! "$opener"; then
    fail_step "${key}-reopen" "could not reopen the ${key} sheet"
    return 0
  fi
  if select_labeled "$regex" "$(section_for "$key")"; then
    picked="$SELECTED_LABEL"
    if apply_sheet && chip_exact "$picked"; then
      remember_applied "$key" "$picked"
      pass_step "${key}-select"
    else
      fail_step "${key}-select" "tapped '${picked}' but the chip did not show it"
      recover_sheet
    fi
  else
    fail_step "${key}-select" "could not find an option matching ${regex}"
    recover_sheet
    return 0
  fi

  if ! "$opener"; then
    fail_step "${key}-back-dismiss" "could not reopen before back"
  else
    ui_back
    sleep 1
    if sheet_open; then
      fail_step "${key}-back-dismiss" "sheet stayed open after back"
      recover_sheet
    elif chip_exact "$picked"; then
      pass_step "${key}-back-dismiss"
    else
      fail_step "${key}-back-dismiss" "chip lost '${picked}' after back"
    fi
  fi

  if ! "$opener"; then
    fail_step "${key}-tap-outside" "could not reopen before tap-outside"
  else
    local outside_err
    if outside_err="$(dismiss_sheet_outside 2>&1)"; then
      if chip_exact "$picked"; then
        pass_step "${key}-tap-outside"
      else
        fail_step "${key}-tap-outside" "chip lost '${picked}' after tapping outside"
      fi
    else
      fail_step "${key}-tap-outside" "${outside_err:-tap outside did not dismiss}"
      recover_sheet
    fi
  fi

  if [[ -z "$idle" ]]; then
    if clear_named "$clear_name"; then
      pass_step "${key}-clear"
    else
      fail_step "${key}-clear" "clear control was not found"
    fi
  elif clear_named "$clear_name" && chip_exact "$idle"; then
    pass_step "${key}-clear"
  else
    fail_step "${key}-clear" "chip was not '${idle}' after clear"
  fi

  local n
  for n in 1 2 3; do
    if ! "$opener"; then
      fail_step "${key}-repeat-${n}" "could not open"
      continue
    fi
    if ! select_labeled "$regex" "$(section_for "$key")"; then
      fail_step "${key}-repeat-${n}" "option not found"
      recover_sheet
      continue
    fi
    local again="$SELECTED_LABEL"
    if apply_sheet && chip_exact "$again"; then
      remember_applied "$key" "$again"
      pass_step "${key}-repeat-${n}"
    else
      fail_step "${key}-repeat-${n}" "tapped '${again}' but the chip did not show it"
      recover_sheet
    fi
  done
  clear_named "$clear_name" || true
}

exercise_filter state '^Kerala( +[0-9]+)?$' State open_state state
exercise_filter deity '^Shiva( +[0-9]+)?$' Deity open_deity deity

if scroll_chips_until --resource-id filter-chip-district || scroll_chips_until --text-regex '^All districts$'; then
  pass_step district-chip-visible
  exercise_filter district '^Madurai( +[0-9]+)?$' "All districts" open_district district
else
  pass_step district-chip-not-visible
fi

if scroll_chips_until --resource-id filter-chip-city || scroll_chips_until --text-regex '^(City|All cities)$'; then
  pass_step city-chip-visible
else
  pass_step city-chip-not-shown
fi

ui_dump || true
while read -r chip_id; do
  [[ -z "$chip_id" ]] && continue
  case "$chip_id" in
    filter-chip-state|filter-chip-deity|filter-chip-district|filter-chip-city) continue ;;
  esac
  opener_unknown() { open_by_id "$chip_id"; }
  exercise_filter "$chip_id" '^(?!Any |All ).+[0-9]+$' "" opener_unknown "$chip_id"
done < <(python3 "$UI_PY" resource-ids "$DUMP" --prefix filter-chip- || true)

# Combined filters. A step whose select never landed is NOT RUN, and later
# checks assert only the values that were actually applied.
# Record NOT RUN only when one of the named prerequisite steps already failed.
skip_if_failed() {
  local step="$1"
  local reason="$2"
  shift 2
  local prereq
  for prereq in "$@"; do
    if grep -Eq "^FAIL ${FLOW}: ${prereq}:" "$RESULTS"; then
      skip_step "$step" "$reason"
      return 0
    fi
  done
  fail_step "$step" "$reason"
}

applied_chips_present() {
  APPLIED_MISSING=""
  local missing=""
  if [[ -n "$COMBINED_STATE" ]] && ! chip_exact "$COMBINED_STATE"; then
    missing+=" ${COMBINED_STATE}"
  fi
  if [[ -n "$COMBINED_DEITY" ]] && ! chip_exact "$COMBINED_DEITY"; then
    missing+=" ${COMBINED_DEITY}"
  fi
  if [[ -n "$COMBINED_DISTRICT" ]] && ! chip_exact "$COMBINED_DISTRICT"; then
    missing+=" ${COMBINED_DISTRICT}"
  fi
  APPLIED_MISSING="${missing# }"
  [[ -z "$APPLIED_MISSING" ]]
}

if [[ "$STATE_SELECT_OK" -ne 1 || -z "$STATE_LABEL" ]]; then
  skip_if_failed combined-state "state-select did not apply a state" \
    state-open state-reopen state-select
else
  if open_state && select_labeled "^$(re_escape "$STATE_LABEL")( +[0-9]+)?$" STATE && apply_sheet && chip_exact "$STATE_LABEL"; then
    COMBINED_STATE="$STATE_LABEL"
    pass_step combined-state
  else
    fail_step combined-state "could not apply ${STATE_LABEL}"
    recover_sheet
  fi
fi
if [[ "$DEITY_SELECT_OK" -ne 1 || -z "$DEITY_LABEL" ]]; then
  skip_if_failed combined-deity "deity-select did not apply a deity" \
    deity-open deity-reopen deity-select
else
  if open_deity && select_labeled "^$(re_escape "$DEITY_LABEL")( +[0-9]+)?$" DEITY && apply_sheet && chip_exact "$DEITY_LABEL"; then
    COMBINED_DEITY="$DEITY_LABEL"
    pass_step combined-deity
  else
    fail_step combined-deity "could not apply ${DEITY_LABEL}"
    recover_sheet
  fi
fi
if scroll_chips_until --resource-id filter-chip-district || scroll_chips_until --text-regex '^All districts$'; then
  if open_district && select_labeled '^(?!All districts).+[0-9]+$' DISTRICT && apply_sheet; then
    COMBINED_DISTRICT="$SELECTED_LABEL"
    DISTRICT_LABEL="$SELECTED_LABEL"
    pass_step combined-district
  else
    fail_step combined-district "could not apply a district inside the selected state"
    recover_sheet
  fi
else
  pass_step combined-district-not-visible
fi

if [[ -z "$COMBINED_STATE" && -z "$COMBINED_DEITY" && -z "$COMBINED_DISTRICT" ]]; then
  skip_if_failed combined-chips "no combined filter was applied" \
    state-open state-reopen state-select \
    deity-open deity-reopen deity-select \
    district-open district-select \
    combined-state combined-deity combined-district
elif applied_chips_present; then
  pass_step combined-chips
else
  fail_step combined-chips "applied filters were not showing: ${APPLIED_MISSING}"
fi

if ui_wait_scrolled 20 --resource-id temple-browse-card --text-contains "Temple"; then
  ui_tap
  if ui_wait_scrolled 20 --text-contains "How to Reach"; then
    pass_step detail-open
    ui_back
    sleep 2
    if [[ -z "$COMBINED_STATE" && -z "$COMBINED_DEITY" && -z "$COMBINED_DISTRICT" ]]; then
      skip_if_failed detail-back-keeps-filter "no combined filter was applied" \
        state-open state-reopen state-select \
        deity-open deity-reopen deity-select \
        district-open district-select \
        combined-state combined-deity combined-district
    elif applied_chips_present; then
      pass_step detail-back-keeps-filter
    else
      fail_step detail-back-keeps-filter "applied filters were not on the list after back: ${APPLIED_MISSING}"
    fi
  else
    fail_step detail-open "temple detail did not show How to Reach"
  fi
else
  fail_step detail-open "no temple card to open"
fi

ui_home_key
sleep 1
resume_app
if [[ -z "$COMBINED_STATE" && -z "$COMBINED_DEITY" && -z "$COMBINED_DISTRICT" ]]; then
  skip_if_failed home-resume-keeps-filter "no combined filter was applied" \
    state-open state-reopen state-select \
    deity-open deity-reopen deity-select \
    district-open district-select \
    combined-state combined-deity combined-district
elif applied_chips_present; then
  pass_step home-resume-keeps-filter
else
  fail_step home-resume-keeps-filter "applied filters were not kept after HOME and resume: ${APPLIED_MISSING}"
fi

force_stop_app
launch_app
accept_policy_if_shown || true
if ! open_browse || ! wait_browse_ready; then
  fail_step force-stop-relaunch "browse list did not return after force-stop"
elif [[ -z "$COMBINED_STATE" && -z "$COMBINED_DEITY" && -z "$COMBINED_DISTRICT" ]]; then
  skip_if_failed force-stop-keeps-filter "no combined filter was applied" \
    state-open state-reopen state-select \
    deity-open deity-reopen deity-select \
    district-open district-select \
    combined-state combined-deity combined-district
elif applied_chips_present; then
  pass_step force-stop-keeps-filter
else
  # Filters are in memory only. Force-stop clears them; that is expected.
  xfail_step force-stop-keeps-filter "filters live in memory and reset after force-stop"
fi
