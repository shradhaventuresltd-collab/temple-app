#!/usr/bin/env bash
# Decision for the android-smoke schedule. Sourced by the workflow script
# and by scripts/ci/test_ci_guards.sh. Prints "true" or "false".
#
# workflow_dispatch always runs. A scheduled run is skipped when main HEAD
# is the head_sha of the last successful android-smoke job on main, or of
# the last job whose conclusion is exactly "failure". A cancelled run does
# not count, so it does not block the next scheduled retry. GitHub concludes
# a job that hits timeout-minutes as cancelled, not failure. The smoke script
# is wrapped in a shorter shell timeout so a hang exits non-zero and the job
# concludes failure instead. A red failure SHA is not retried every slot.

# Echoes the SHA only when conclusion is "failure". Cancelled and every
# other conclusion echo nothing.
failed_attempt_sha() {
  local conclusion="$1"
  local sha="$2"
  if [[ "$conclusion" == "failure" ]]; then
    printf '%s' "$sha"
  fi
}

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
