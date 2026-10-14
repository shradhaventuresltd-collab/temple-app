#!/usr/bin/env bash
# First job of android-smoke. Writes should_run, last_green_sha, and head_sha
# to GITHUB_OUTPUT.
#
# A scheduled run skips the emulator when main HEAD equals the last successful
# android-smoke job on main, or the last failed attempt (a red SHA is not
# retried every slot). A failure conclusion counts. A cancelled conclusion
# counts when that run's event is schedule. Setup usually takes about 6 to
# 7 minutes, so the 15-minute job limit fires before the 12-minute shell
# timeout and that scheduled cancel counts as failed. Manually cancelling
# a scheduled run also counts, so that SHA stays blocked until a new commit
# or a workflow_dispatch. A workflow_dispatch cancel does not count.
# workflow_dispatch always runs. A pull_request run always runs and does
# not consult the green/failed SHA skip. Lookups for the schedule pass
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

# Labelled PR smoke always runs the emulator. Do not read main's green or
# failed SHA, and do not skip when that SHA matches.
if [[ "$event" == "pull_request" ]]; then
  head_sha="${PR_HEAD_SHA:-${GITHUB_SHA:?}}"
  should_run="$(smoke_should_run "$event" "$head_sha" "" "")"
  echo "android-smoke will run (event=pull_request, head=${head_sha}; green/failed SHA skip does not apply)."
  {
    echo "should_run=${should_run}"
    echo "last_green_sha="
    echo "head_sha=${head_sha}"
  } >>"$GITHUB_OUTPUT"
  exit 0
fi

# Newest android-smoke jobs on main. Skipped jobs do not count. Pages are
# newest-first. A quiet main produces skipped schedule runs, so look back
# far enough to reach a real green or failed attempt.
find_main_smoke_shas() {
  local page id row conclusion sha remembered run_event line
  local sha_green="" sha_failed=""
  for page in 1 2 3 4 5 6 7 8; do
    local runs
    # Last green and last failed both come from this list. A pull_request
    # run carries the PR head SHA, so it must not become main's last green
    # or last failed SHA.
    if ! runs="$(gh api "repos/${repo}/actions/workflows/android-smoke.yml/runs?branch=main&per_page=20&page=${page}" --jq '.workflow_runs[] | select(.event != "pull_request") | "\(.id) \(.event)"' 2>/dev/null)"; then
      echo "warning: could not list android-smoke runs on main (page ${page})." >&2
      if [[ "$page" -eq 1 ]]; then
        return 1
      fi
      break
    fi
    if [[ -z "$runs" ]]; then
      break
    fi
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      id="${line%% *}"
      run_event="${line#* }"
      row="$(gh api "repos/${repo}/actions/runs/${id}/jobs" --jq 'first(.jobs[] | select(.name=="android-smoke") | "\(.conclusion) \(.head_sha)")' 2>/dev/null || true)"
      conclusion="${row%% *}"
      sha="${row#* }"
      if [[ -z "$row" || "$conclusion" == "null" || -z "$sha" || "$sha" == "$conclusion" || "$sha" == "null" ]]; then
        continue
      fi
      if [[ "$conclusion" == "success" ]]; then
        if [[ -z "$sha_green" ]]; then
          sha_green="$sha"
        fi
      else
        remembered="$(failed_attempt_sha "$conclusion" "$sha" "$run_event")"
        if [[ -n "$remembered" && -z "$sha_failed" ]]; then
          sha_failed="$remembered"
        fi
      fi
      if [[ -n "$sha_green" && -n "$sha_failed" ]]; then
        break
      fi
    done <<< "$runs"
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
