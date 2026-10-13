#!/usr/bin/env bash
# Decision for the android-smoke schedule. Sourced by the workflow script
# and by scripts/ci/test_ci_guards.sh. Prints "true" or "false".
#
# workflow_dispatch always runs. A scheduled run is skipped only when main
# HEAD is already the head_sha of the last successful android-smoke job.

smoke_should_run() {
  local event="$1"
  local main_sha="$2"
  local last_green="$3"
  if [[ "$event" == "workflow_dispatch" ]]; then
    echo true
    return 0
  fi
  if [[ -n "$last_green" && "$last_green" == "$main_sha" ]]; then
    echo false
    return 0
  fi
  echo true
}
