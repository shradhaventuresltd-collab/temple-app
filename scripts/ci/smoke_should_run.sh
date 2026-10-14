#!/usr/bin/env bash
# Decision for the android-smoke schedule. Sourced by the workflow script
# and by scripts/ci/test_ci_guards.sh. Prints "true" or "false".
#
# workflow_dispatch always runs. pull_request always runs: the plan job
# must not apply the green/failed SHA skip to a labelled PR. A scheduled
# run is skipped when main HEAD is the head_sha of the last successful
# android-smoke job on main, or of the last failed attempt. A failure
# conclusion counts. A cancelled conclusion on a schedule-triggered run
# counts as failed. Setup usually takes about 6 to 7 minutes, so the
# 15-minute job limit fires before the 12-minute shell timeout, and GitHub
# concludes that job cancelled. Manually cancelling a scheduled run also
# counts, so that SHA is not retried until a new commit or a
# workflow_dispatch. A workflow_dispatch cancel does not count. A red SHA
# is not retried every slot.

# Echoes the SHA for conclusion "failure", and for "cancelled" when the
# triggering event is "schedule" (the job limit, or a manual cancel of
# that scheduled run). A workflow_dispatch cancel echoes nothing.
failed_attempt_sha() {
  local conclusion="$1"
  local sha="$2"
  local event="${3:-}"
  if [[ "$conclusion" == "failure" ]]; then
    printf '%s' "$sha"
    return 0
  fi
  if [[ "$conclusion" == "cancelled" && "$event" == "schedule" ]]; then
    printf '%s' "$sha"
  fi
}

# Play release gate. pull_request runs are ignored. They carry the PR
# head SHA, not the merge ref, and a labelled PR smoke must not unlock a
# Play bundle. Schedule and workflow_dispatch runs on the exact SHA still
# count, including a dispatch whose branch is not main.
gate_accepts_smoke_run() {
  local event="$1"
  [[ "$event" != "pull_request" ]]
}

smoke_should_run() {
  local event="$1"
  local main_sha="$2"
  local last_green="$3"
  local last_failed="${4:-}"
  if [[ "$event" == "workflow_dispatch" || "$event" == "pull_request" ]]; then
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
