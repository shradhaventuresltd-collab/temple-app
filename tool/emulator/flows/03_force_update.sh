#!/usr/bin/env bash
# Flow 3. Local pref only. Does not fetch or write production Remote Config.
launch_app
sleep 2
force_stop_app

extra='<boolean name="flutter.emulator_force_update" value="true" />'
if ! write_policy_prefs 99 seed-pref "$extra"; then
  return 0
fi
pass_step seed-pref

launch_app
if ui_wait 45 --text-contains "Update required"; then
  pass_step screen
else
  fail_step screen "Update required was not shown. The APK needs to be debuggable (debug, or EMULATOR_APP_TEST) so the local pref is honored."
  return 0
fi

ui_dump || true
if ui_find --text-contains "Temple Heritage of India"; then
  fail_step blocks-home "home body was visible on the force-update screen"
else
  pass_step blocks-home
fi

if ! ui_wait 10 --text-contains "Update on Play Store"; then
  fail_step store-button "Update on Play Store was not shown"
  return 0
fi
ui_tap
pass_step store-button
sleep 2

adb shell dumpsys activity activities > "${DUMP_DIR}/${FLOW}-activities.txt" 2>/dev/null || true
adb logcat -d -t 500 > "${LOG_DIR}/${FLOW}-button.txt" 2>/dev/null || true
ui_dump || true
if grep -Eiq 'market://details|play.google.com/store|com.android.vending' \
  "${DUMP_DIR}/${FLOW}-activities.txt" "${LOG_DIR}/${FLOW}-button.txt" ||
  ui_find --text-contains "Could not open the Play Store"; then
  pass_step store-intent
else
  fail_step store-intent "dumpsys and logcat did not show a Play Store intent"
fi
