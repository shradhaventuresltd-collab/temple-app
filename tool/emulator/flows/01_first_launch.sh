#!/usr/bin/env bash
# Flow 1. Clean install shows the first-launch policy gate. Back leaves the
# app. Relaunch shows the gate again, and Accept opens Home.
clean_install || return 0

launch_app
if ui_wait 45 --text-contains "Before you begin"; then
  pass_step gate-title
else
  fail_step gate-title "first-launch title was not shown"
  return 0
fi

if ui_dump && ui_find --text-contains "Accept & continue"; then
  pass_step accept-button
else
  fail_step accept-button "Accept & continue was not shown"
fi

if ui_dump && ui_find --text-contains "Terms of Service"; then
  pass_step terms-link
else
  fail_step terms-link "Terms of Service was not shown"
fi

if ui_dump && ui_find --text-contains "Privacy Policy"; then
  pass_step privacy-link
else
  fail_step privacy-link "Privacy Policy was not shown"
fi

ui_back
sleep 2
ui_dump || true
if ui_find --text-contains "Temple Directory"; then
  fail_step back-exits "home was visible after back on the gate"
elif ui_find --text-contains "Before you begin"; then
  fail_step back-exits "gate stayed up after back"
else
  pass_step back-exits
fi

launch_app
if ui_wait 30 --text-contains "Before you begin"; then
  pass_step gate-returns
else
  fail_step gate-returns "gate was not shown again after relaunch"
  return 0
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
  fail_step accepted-home "home did not appear after accept"
fi
