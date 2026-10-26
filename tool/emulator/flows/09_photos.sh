#!/usr/bin/env bash
# Flow 9. A credited gallery frame shows its credit on the detail page.
if ! err="$(reach_browse)"; then
  fail_step browse "${err:-could not open the temple list}"
  return 0
fi
pass_step browse

open_named() {
  local name="$1"
  ui_wait_scrolled 20 --resource-id temple-browse-card --text-contains "$name" || return 1
  ui_tap
  ui_wait_scrolled 20 --text-contains "$name" || return 1
}

if ui_replace_field_text "Chintaman" && open_named "Chintaman Ganesh Temple"; then
  pass_step open-chintaman
  if ui_wait_scrolled 15 --text-contains "Gyanendra" || ui_wait_scrolled 8 --text-contains "CC BY"; then
    pass_step photo-credit
  else
    fail_step photo-credit "Chintaman detail did not show the CC BY credit"
  fi
elif ui_replace_field_text "Kaleshwara" && open_named "Kaleshwara Mukteswara Temple"; then
  pass_step open-kaleshwara
  # The first frame is CC0 with no caption. Swipe to the credited frame.
  read -r width height < <(ui_screen_size)
  adb_shell_capped 8 input swipe $((width * 80 / 100)) $((height * 28 / 100)) $((width * 20 / 100)) $((height * 28 / 100)) 250 || echo "photos: gallery swipe timed out" >&2
  sleep 1
  if ui_wait_scrolled 12 --text-contains "Kavurisgs" || ui_wait_scrolled 8 --text-contains "CC BY"; then
    pass_step photo-credit
  else
    fail_step photo-credit "Kaleshwara gallery did not show the CC BY-SA credit"
  fi
else
  fail_step photo-credit "could not open Chintaman or Kaleshwara to read a credit (field: ${UI_FIELD_ACTUAL:-unreadable})"
fi
