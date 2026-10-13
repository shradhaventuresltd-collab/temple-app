#!/usr/bin/env bash
# First job of android-smoke. Writes should_run, last_green_sha, and head_sha
# to GITHUB_OUTPUT.
#
# A scheduled run skips the emulator when main HEAD equals the last successful
# android-smoke job on main, or the last failed attempt on main (a red SHA is
# not retried every slot). workflow_dispatch always runs. Lookups pass
# branch=main. If the Actions API cannot be read, the emulator runs.
set -euo pipefail

if [[ -z "${GITHUB_OUTPUT:-}" ]]; then
  echo "error: GITHUB_OUTPUT is not set." >&2
  exit 1
fi

repo="${GITHUB_REPOSITORY:?}"
event="${GITHUB_EVENT_NAME:-}"
# shellcheck source=smoke_should_run.sh
source "$(dirname "$0")/smoke_should_run.sh"

# Newest android-smoke jobs on main. Skipped jobs do not count. Pages are
# newest-first. A quiet main produces skipped schedule runs, so look back
# far enough to reach a real green or failed attempt.
find_main_smoke_shas() {
  local page id row conclusion sha
  local sha_green="" sha_failed=""
  for page in 1 2 3 4 5 6 7 8; do
    local ids
    if ! ids="$(gh api "repos/${repo}/actions/workflows/android-smoke.yml/runs?branch=main&per_page=20&page=${page}" --jq '.workflow_runs[].id' 2>/dev/null)"; then
      echo "warning: could not list android-smoke runs on main (page ${page})." >&2
      if [[ "$page" -eq 1 ]]; then
        return 1
      fi
      break
    fi
    if [[ -z "$ids" ]]; then
      break
    fi
    for id in $ids; do
      row="$(gh api "repos/${repo}/actions/runs/${id}/jobs" --jq 'first(.jobs[] | select(.name=="android-smoke") | "\(.conclusion) \(.head_sha)")' 2>/dev/null || true)"
      conclusion="${row%% *}"
      sha="${row#* }"
      if [[ -z "$row" || "$conclusion" == "null" || -z "$sha" || "$sha" == "$conclusion" || "$sha" == "null" ]]; then
        continue
      fi
      case "$conclusion" in
        success)
          if [[ -z "$sha_green" ]]; then
            sha_green="$sha"
          fi
          ;;
        failure|cancelled|timed_out)
          if [[ -z "$sha_failed" ]]; then
            sha_failed="$sha"
          fi
          ;;
      esac
      if [[ -n "$sha_green" && -n "$sha_failed" ]]; then
        break
      fi
    done
    if [[ -n "$sha_green" && -n "$sha_failed" ]]; then
      break
    fi
  done
  printf '%s\n%s\n' "$sha_green" "$sha_failed"
}

last_green=""
last_failed=""
if found="$(find_main_smoke_shas)"; then
  last_green="$(printf '%s\n' "$found" | sed -n '1p')"
  last_failed="$(printf '%s\n' "$found" | sed -n '2p')"
else
  echo "warning: Actions API lookup failed; android-smoke will run." >&2
  last_green=""
  last_failed=""
fi

if [[ "$event" == "workflow_dispatch" ]]; then
  head_sha="${GITHUB_SHA:?}"
else
  head_sha="$(gh api "repos/${repo}/commits/main" --jq .sha)"
fi

should_run="$(smoke_should_run "$event" "$head_sha" "$last_green" "$last_failed")"
if [[ "$should_run" == "true" ]]; then
  echo "android-smoke will run (event=${event}, head=${head_sha}, last_green=${last_green:-none}, last_failed=${last_failed:-none})."
elif [[ -n "$last_green" && "$last_green" == "$head_sha" ]]; then
  echo "android-smoke skipped: main HEAD ${head_sha} already has a successful android-smoke job."
else
  echo "android-smoke skipped: main HEAD ${head_sha} matches the last failed android-smoke attempt."
fi

{
  echo "should_run=${should_run}"
  echo "last_green_sha=${last_green}"
  echo "head_sha=${head_sha}"
} >>"$GITHUB_OUTPUT"
