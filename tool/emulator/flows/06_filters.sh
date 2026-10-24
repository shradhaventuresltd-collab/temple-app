#!/usr/bin/env bash
# Flow 6. Every directory filter: open, dismiss, select, back, tap-outside,
# clear, repeat, then combined filters, detail, resume, and process death.
if ! err="$(reach_browse)"; then
  fail_step browse "${err:-could not open the temple list}"
  return 0
fi
pass_step browse

scroll_chips_until() {
  local i
  for i in 1 2 3; do
    if ui_dump && ui_find "$@"; then
      return 0
    fi
    local width height
    read -r width height < <(ui_screen_size) || return 1
    adb shell input swipe \
      $((width * 75 / 100)) $((height * 16 / 100)) \
      $((width * 20 / 100)) $((height * 16 / 100)) 250
    sleep 1
  done
  return 1
}

select_labeled() {
  local regex="$1"
  local i width height min_top
  for i in 1 2 3 4 5 6 7 8; do
    ui_dump || true
    read -r width height < <(ui_screen_size) || return 1
    min_top=$((height * 22 / 100))
    if ui_find --text-regex "$regex" --min-top "$min_top" --prefer lower; then
      SELECTED_LABEL="$(chip_label "$UI_TEXT")"
      ui_tap
      sleep 1
      return 0
    fi
    ui_fling up || true
    sleep 1
  done
  return 1
}

apply_sheet() {
  if ! ui_wait 12 --text-regex '^Show [0-9]+ temples?$'; then
    return 1
  fi
  ui_tap
  sleep 1
  if sheet_open; then
    return 1
  fi
  return 0
}

chip_exact() {
  ui_dump || return 1
  ui_find --text-regex "^$(python3 -c 'import re,sys; print(re.escape(sys.argv[1]))' "$1")$"
}

open_state() {
  scroll_chips_until --resource-id filter-chip-state || scroll_chips_until --text-regex '^State$' || return 1
  ui_tap
  ui_wait 12 --text-regex '^Filters$'
}

open_deity() {
  scroll_chips_until --text-regex '^Deity$' || scroll_chips_until --content-desc "Choose a deity" || return 1
  ui_tap
  ui_wait 12 --text-regex '^Filters$'
}

open_district() {
  scroll_chips_until --resource-id filter-chip-district || scroll_chips_until --text-regex '^All districts$' || return 1
  ui_tap
  ui_wait 20 --text-regex '^DISTRICT$' || ui_wait 8 --text-regex '^Filters$'
}

open_by_id() {
  scroll_chips_until --resource-id "$1" || return 1
  ui_tap
  ui_wait 12 --text-regex '^Filters$'
}

recover_sheet() {
  if sheet_open; then
    ui_back
    sleep 1
  fi
}

clear_named() {
  local which="$1"
  if ui_dump && ui_find --content-desc "Clear ${which} filter"; then
    ui_tap
    sleep 1
    return 0
  fi
  if ui_dump && ui_find --text-regex '^Clear$' --prefer upper; then
    ui_tap
    sleep 1
    return 0
  fi
  return 1
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
  if select_labeled "$regex"; then
    picked="$SELECTED_LABEL"
    if apply_sheet && chip_exact "$picked"; then
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
    if ! select_labeled "$regex"; then
      fail_step "${key}-repeat-${n}" "option not found"
      recover_sheet
      continue
    fi
    local again="$SELECTED_LABEL"
    if apply_sheet && chip_exact "$again"; then
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

# Combined state + deity (+ district when the chip exists), then navigation.
if ! open_state || ! select_labeled '^Kerala( +[0-9]+)?$' || ! apply_sheet; then
  fail_step combined-state "could not apply Kerala"
else
  pass_step combined-state
fi
if ! open_deity || ! select_labeled '^Shiva( +[0-9]+)?$' || ! apply_sheet; then
  fail_step combined-deity "could not apply Shiva"
else
  pass_step combined-deity
fi
if scroll_chips_until --resource-id filter-chip-district || scroll_chips_until --text-regex '^All districts$'; then
  if open_district && select_labeled '^(?!All districts).+[0-9]+$' && apply_sheet; then
    pass_step combined-district
    DISTRICT_LABEL="$SELECTED_LABEL"
  else
    fail_step combined-district "could not apply a district inside the selected state"
    recover_sheet
    DISTRICT_LABEL=""
  fi
else
  DISTRICT_LABEL=""
  pass_step combined-district-not-visible
fi

if chip_exact "Kerala" && chip_exact "Shiva"; then
  pass_step combined-chips
else
  fail_step combined-chips "Kerala and Shiva were not both selected"
fi

if ui_wait_scrolled 20 --text-regex '.+Temple$'; then
  ui_tap
  if ui_wait_scrolled 20 --text-contains "How to Reach"; then
    pass_step detail-open
    ui_back
    sleep 2
    if chip_exact "Kerala" && chip_exact "Shiva"; then
      pass_step detail-back-keeps-filter
    else
      fail_step detail-back-keeps-filter "filters were not on the list after back"
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
if chip_exact "Kerala" && chip_exact "Shiva"; then
  pass_step home-resume-keeps-filter
else
  fail_step home-resume-keeps-filter "filters were not kept after HOME and resume"
fi

force_stop_app
launch_app
accept_policy_if_shown || true
if ! open_browse || ! wait_browse_ready; then
  fail_step force-stop-relaunch "browse list did not return after force-stop"
else
  if chip_exact "Kerala" && chip_exact "Shiva"; then
    pass_step force-stop-keeps-filter
  else
    fail_step force-stop-keeps-filter "filters were not kept after force-stop and relaunch"
  fi
fi
