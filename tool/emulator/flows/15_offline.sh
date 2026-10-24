#!/usr/bin/env bash
# Flow 15. Offline banner on a cold start and again mid-session.
# svc wifi/data disable is required. Ethernet is also turned down because
# that is the route the emulator actually uses.
launch_app
if ! accept_policy_if_shown || ! wait_for_home; then
  fail_step online-home "home did not appear while online"
  return 0
fi
pass_step online-home

force_stop_app
network_off
launch_app
if ui_wait 30 --text-contains "offline" || ui_wait 8 --text-contains "Offline"; then
  pass_step cold-start-offline
else
  fail_step cold-start-offline "offline banner was not shown on cold start"
fi

network_on
sleep 3
if ui_wait 25 --text-contains "Temple Directory"; then
  ui_dump || true
  if ui_find --text-regex "[Oo]ffline"; then
    fail_step back-online "offline banner was still showing"
  else
    pass_step back-online
  fi
else
  fail_step back-online "home was not shown after the network returned"
fi

network_off
sleep 3
if ui_wait 25 --text-contains "offline" || ui_wait 8 --text-contains "Offline"; then
  pass_step mid-session-offline
else
  fail_step mid-session-offline "offline banner was not shown mid-session"
fi
network_on
