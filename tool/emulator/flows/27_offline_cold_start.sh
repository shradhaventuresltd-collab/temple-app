#!/usr/bin/env bash
# Flow 27 (bughunter). Cold start with network OFF after clearState (no
# Firestore cache): expect bundled sample fallback or a retry UI, never an
# infinite "Loading temples". Then network on -> retry recovers without relaunch.
# Also flaky: toggle network while list loads.
clean_install 2>/dev/null || true
network_off
launch_app; accept_policy_if_shown; sleep 2
wait_for_home && pass_step offline-home || fail_step offline-home "home never shown offline (Remote Config/Firestore blocking?)"
open_browse; sleep 30; ui_dump
ui_find --text-contains "Loading temples" && fail_step offline-list "still loading after 30s" || pass_step offline-list
network_on; sleep 3; ui_dump
ui_find --text-regex 'Retry|Try again' && { ui_tap; sleep 5; }
# KAN-186: the list does not reload after the network returns (app bug,
# identical on main run 40658283240). XFAIL until the app fix (PR #127)
# lands; a pass is then XPASS, which fails the job so this mark is removed.
xfail_known recover KAN-186 "did not recover after network on" wait_browse_ready
for i in 1 2 3; do network_off; sleep 1; network_on; sleep 1; done
ui_dump; ui_find --resource-id filter-chip-state && ui_tap; sleep 1; xfail_known chips-after-flap KAN-186 "chips dead after network flaps" sheet_open
