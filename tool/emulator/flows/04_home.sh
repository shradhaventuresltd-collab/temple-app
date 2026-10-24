#!/usr/bin/env bash
# Flow 4. Home landmarks after the policy gate.
launch_app
if ! accept_policy_if_shown; then
  fail_step launch "policy gate or home did not appear"
  return 0
fi

if wait_for_home; then
  pass_step title
else
  fail_step title "Temple Directory was not shown"
  return 0
fi

if ui_wait_scrolled 25 --text-contains "Temple Heritage of India"; then
  pass_step heritage
else
  fail_step heritage "Temple Heritage of India was not shown"
fi

if ui_wait_scrolled 20 --text-regex 'Browse .+Temple'; then
  pass_step browse-button
else
  fail_step browse-button "Browse temples button was not shown"
fi

if ui_wait_scrolled 15 --text-contains "Temples near me"; then
  pass_step near-me
else
  fail_step near-me "Temples near me was not shown"
fi

fling=0
while (( fling < 4 )); do
  ui_fling down || true
  fling=$((fling + 1))
done
if ui_dump && ui_find --content-desc "Open navigation menu"; then
  pass_step navigation-menu
else
  fail_step navigation-menu "Open navigation menu was not shown"
fi
