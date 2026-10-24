#!/usr/bin/env bash
# Flow 10. Get Directions fires a maps VIEW intent. Confirmed from dumpsys and logcat.
if ! err="$(reach_browse)"; then
  fail_step browse "${err:-could not open the temple list}"
  return 0
fi
pass_step browse

if ! ui_wait 12 --resource-id temple-list-search-field && ! ui_wait 8 --text-contains "Name, city, state"; then
  fail_step search "search field was not shown"
  return 0
fi
if ! ui_replace_field_text "Meenakshi"; then
  fail_step open-detail "search field text was '${UI_FIELD_ACTUAL:-unreadable}', expected Meenakshi"
  return 0
fi
if ! ui_wait_scrolled 25 --resource-id temple-browse-card --text-contains "Meenakshi Amman Temple"; then
  fail_step open-detail "Meenakshi Amman Temple was not listed"
  return 0
fi
ui_tap
if ! ui_wait_scrolled 25 --text-contains "Get Directions"; then
  if ! ui_wait_scrolled 10 --resource-id get-directions-button; then
    fail_step directions-button "Get Directions was not shown"
    return 0
  fi
fi
pass_step directions-button

adb logcat -c >/dev/null 2>&1 || true
ui_tap
sleep 3
adb shell dumpsys activity activities > "${DUMP_DIR}/${FLOW}-activities.txt" 2>/dev/null || true
adb logcat -d -t 600 > "${LOG_DIR}/${FLOW}-tap.txt" 2>/dev/null || true

if grep -Eiq 'google.com/maps|maps/dir|geo:|com.google.android.apps.maps|android.intent.action.VIEW' \
  "${DUMP_DIR}/${FLOW}-activities.txt" "${LOG_DIR}/${FLOW}-tap.txt"; then
  pass_step maps-intent
else
  fail_step maps-intent "dumpsys activity and logcat did not show a maps VIEW intent"
fi
