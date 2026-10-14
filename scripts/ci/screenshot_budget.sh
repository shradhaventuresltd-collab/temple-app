#!/usr/bin/env bash
# Screenshot time left inside the android-smoke job.
#
# Elapsed is seconds since JOB_START_EPOCH, not $SECONDS. $SECONDS starts
# when the smoke script starts, after the APK build, so it under-counts.
# Skip once 600s have passed. Otherwise the timeout is
# min(180, 780 - elapsed) seconds, and 0 means skip.

# min(180, max(0, 780 - elapsed))
screenshot_timeout_cap() {
  local elapsed="$1"
  local remain=$((780 - elapsed))
  if (( remain > 180 )); then
    printf '180'
  elif (( remain > 0 )); then
    printf '%s' "$remain"
  else
    printf '0'
  fi
}

# Prints the timeout in seconds, or nothing when screenshots should be skipped.
screenshot_run_seconds() {
  local elapsed="$1"
  local cap
  cap="$(screenshot_timeout_cap "$elapsed")"
  if (( elapsed >= 600 || cap <= 0 )); then
    return 0
  fi
  printf '%s\n' "$cap"
}
