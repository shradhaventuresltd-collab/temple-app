#!/usr/bin/env bash
# First job of android-smoke. Writes should_run, last_green_sha, and head_sha
# to GITHUB_OUTPUT.
#
# Skips the emulator when main HEAD equals the last successful android-smoke
# job, unless this run was started with workflow_dispatch. If the Actions API
# cannot be read, the emulator runs (a missed skip costs one smoke; a false
# skip would hide a red main).
set -euo pipefail

if [[ -z "${GITHUB_OUTPUT:-}" ]]; then
  echo "error: GITHUB_OUTPUT is not set." >&2
  exit 1
fi

repo="${GITHUB_REPOSITORY:?}"
event="${GITHUB_EVENT_NAME:-}"
# shellcheck source=smoke_should_run.sh
source "$(dirname "$0")/smoke_should_run.sh"

# Newest successful android-smoke *job* (skipped jobs do not count).
# Pages are newest-first. A quiet main produces skipped schedule runs, so
# look back far enough to reach the real green SHA (about a month of skips).
find_last_green_sha() {
  local page id sha
  for page in 1 2 3 4 5 6 7 8; do
    local ids
    if ! ids="$(gh api "repos/${repo}/actions/workflows/android-smoke.yml/runs?status=success&per_page=20&page=${page}" --jq '.workflow_runs[].id' 2>/dev/null)"; then
      echo "warning: could not list android-smoke runs (page ${page})." >&2
      return 1
    fi
    if [[ -z "$ids" ]]; then
      return 0
    fi
    for id in $ids; do
      sha="$(gh api "repos/${repo}/actions/runs/${id}/jobs" --jq 'first(.jobs[] | select(.name=="android-smoke" and .conclusion=="success") | .head_sha)' 2>/dev/null || true)"
      if [[ -n "$sha" && "$sha" != "null" ]]; then
        printf '%s' "$sha"
        return 0
      fi
    done
  done
  return 0
}

last_green=""
if last_green="$(find_last_green_sha)"; then
  :
else
  echo "warning: Actions API lookup failed; android-smoke will run." >&2
  last_green=""
fi

if [[ "$event" == "workflow_dispatch" ]]; then
  head_sha="${GITHUB_SHA:?}"
else
  head_sha="$(gh api "repos/${repo}/commits/main" --jq .sha)"
fi

should_run="$(smoke_should_run "$event" "$head_sha" "$last_green")"
if [[ "$should_run" == "true" ]]; then
  echo "android-smoke will run (event=${event}, head=${head_sha}, last_green=${last_green:-none})."
else
  echo "android-smoke skipped: main HEAD ${head_sha} already has a successful android-smoke job."
fi

{
  echo "should_run=${should_run}"
  echo "last_green_sha=${last_green}"
  echo "head_sha=${head_sha}"
} >>"$GITHUB_OUTPUT"
