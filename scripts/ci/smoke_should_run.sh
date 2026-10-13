#!/usr/bin/env bash
# Decision for the android-smoke schedule. Sourced by the workflow script
# and by scripts/ci/test_ci_guards.sh. Prints "true" or "false".
#
# workflow_dispatch always runs. A scheduled run is skipped when main HEAD
# is the head_sha of the last successful android-smoke job on main, or of
# the last failed attempt (failure, cancelled, or timed_out) on main.
# A red main is not retried on every schedule slot.

smoke_should_run() {
  local event="$1"
  local main_sha="$2"
  local last_green="$3"
  local last_failed="${4:-}"
  if [[ "$event" == "workflow_dispatch" ]]; then
    echo true
    return 0
  fi
  if [[ -n "$last_green" && "$last_green" == "$main_sha" ]]; then
    echo false
    return 0
  fi
  if [[ -n "$last_failed" && "$last_failed" == "$main_sha" ]]; then
    echo false
    return 0
  fi
  echo true
}
