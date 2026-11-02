#!/usr/bin/env bash
# Polls the booted emulator until the system services a flow (and the
# android-emulator-runner's own "input keyevent 82") needs are up:
#   service check input/settings/package/activity -> "found"
#   pm path android                               -> "package:..."
#   getprop sys.boot_completed                    -> 1
# Run 41461260068: shards 1, 2, 5, 8, 12 loaded the snapshot ("Boot
# completed in ~5.8 s"), then "cmd: Can't find service: settings" and "No
# service published for: input"; the warm-up had saved that snapshot 6.4s
# after boot with no readiness check.
#
#   services_ready.sh [TIMEOUT_S]   exit 0 when ready, 1 on timeout
# EMULATOR_SERVICES_POLL_S (default 3) is the pause between polls. Each adb
# call is capped at 5s (or the time left). Prints one line per poll.
set -uo pipefail
budget="${1:-90}"
poll="${EMULATOR_SERVICES_POLL_S:-3}"
started=$SECONDS
n=0
while :; do
  n=$((n + 1))
  left=$((budget - (SECONDS - started)))
  (( left > 0 )) || break
  cap=$(( left < 5 ? left : 5 ))
  missing=""
  for svc in input settings package activity; do
    out="$(timeout "$cap" adb shell service check "$svc" 2>/dev/null </dev/null | tr -d '\r')"
    [[ "$out" == *": found"* ]] || missing+="${svc} "
  done
  out="$(timeout "$cap" adb shell pm path android 2>/dev/null </dev/null | tr -d '\r')"
  [[ "$out" == package:* ]] || missing+="pm "
  out="$(timeout "$cap" adb shell getprop sys.boot_completed 2>/dev/null </dev/null | tr -d '\r')"
  [[ "$out" == 1 ]] || missing+="boot_completed "
  if [[ -z "$missing" ]]; then
    echo "services ready after ${n} poll(s), $((SECONDS - started))s"
    exit 0
  fi
  echo "services poll ${n}: waiting for ${missing% }"
  (( SECONDS - started + poll < budget )) || break
  sleep "$poll"
done
echo "services not ready after ${budget}s (${n} polls): ${missing% }"
exit 1
