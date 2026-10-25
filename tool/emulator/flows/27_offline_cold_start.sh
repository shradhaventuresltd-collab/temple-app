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
wait_browse_ready && pass_step recover || fail_step recover "did not recover after network on"
for i in 1 2 3; do network_off; sleep 1; network_on; sleep 1; done
ui_dump; ui_find --resource-id filter-chip-state && ui_tap; sleep 1; sheet_open && pass_step chips-after-flap || fail_step chips-after-flap "chips dead after network flaps"
