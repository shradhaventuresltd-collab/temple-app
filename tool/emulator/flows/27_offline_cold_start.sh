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
# Round 4.3 (run 41391038302): wait until Android validates the network,
# then tap Try again and allow 60s, re-tapping every 15s (recover_browse).
# The flaps run only after recover passed: flapping an in-flight retry
# killed it (ENETUNREACH) and left the error page for chips-after-flap.
network_on
wait_network_validated 60 || true
# KAN-186 (list did not reload after the network returned) is fixed on
# main by #127 (4bceb517f94ce757cb44326e77ef67d93862bf62): plain assertions.
if recover_browse 60 15; then
  pass_step recover
else
  fail_step recover "did not recover within 60s after the network was validated (KAN-186 regression): ${RECOVER_BROWSE_MSG:-}"
  skip_step chips-after-flap "recover failed; no flaps on an unrecovered list"
  return 0
fi
for _ in 1 2 3; do network_off; sleep 1; network_on; sleep 1; done
wait_network_validated 60 || true
# A flap may abort the reload; the list must come back the same way.
recover_browse 60 15 || true
ui_dump; ui_find --resource-id filter-chip-state && ui_tap; sleep 1
sheet_open && pass_step chips-after-flap || fail_step chips-after-flap "chips dead after network flaps (KAN-186 regression)"
recover_sheet
