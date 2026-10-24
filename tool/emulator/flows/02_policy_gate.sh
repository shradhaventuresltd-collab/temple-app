#!/usr/bin/env bash
# Flow 2. Seed shared_prefs with policy version 2 (older than current 3)
# and expect the update gate, then re-accept and stay on Home after relaunch.
launch_app
sleep 3
force_stop_app

if ! write_policy_prefs 2 seed-v2; then
  return 0
fi
pass_step seed-v2

launch_app
if ui_wait 45 --text-contains "We've updated our terms"; then
  pass_step update-title
else
  fail_step update-title "policy update title was not shown for stored version 2"
  return 0
fi

ui_dump || true
if ui_find --text-contains "Before you begin"; then
  fail_step update-frame "first-launch title was showing instead of the update"
else
  pass_step update-frame
fi

if ui_wait 10 --text-contains "Accept & continue"; then
  ui_tap
else
  fail_step accept "could not tap Accept & continue"
  return 0
fi

if wait_for_home; then
  pass_step accepted-home
else
  fail_step accepted-home "home did not appear after re-accept"
  return 0
fi

force_stop_app
launch_app
sleep 2
if ui_wait 12 --text-contains "We've updated our terms"; then
  fail_step relaunch "update gate returned after accepting the current policy"
  return 0
fi
ui_dump || true
if ui_find --text-contains "Before you begin"; then
  fail_step relaunch "first-launch gate returned after accepting"
  return 0
fi
if ui_wait 25 --text-contains "Temple Directory"; then
  pass_step relaunch-home
else
  fail_step relaunch "home was not shown after accepting version 3"
fi
