#!/usr/bin/env bash
# Decide whether this run should go ahead. Writes run=true|false to
# GITHUB_OUTPUT. Only a schedule event can be skipped: when main's HEAD
# (GITHUB_SHA) equals the head_sha of the last green full run on main
# (event push or schedule), the nightly has nothing new to test.
# Any lookup error, timeout, or empty answer fails open (run=true).
set -uo pipefail

decide() {
  local event="${GITHUB_EVENT_NAME:-}" sha="${GITHUB_SHA:-}" last=""
  if [[ "$event" != schedule ]]; then
    echo "run=true reason=event ${event} is never skipped"
    return 0
  fi
  if ! command -v gh >/dev/null 2>&1 || [[ -z "${GITHUB_REPOSITORY:-}" || -z "$sha" ]]; then
    echo "run=true reason=fail-open: gh or repository context missing"
    return 0
  fi
  last="$(timeout "${NIGHTLY_GATE_TIMEOUT_S:-30}" gh api \
    "repos/${GITHUB_REPOSITORY}/actions/workflows/emulator-app-test.yml/runs?branch=main&status=success&per_page=30" \
    --jq '[.workflow_runs[] | select(.event == "push" or .event == "schedule")][0].head_sha // empty' 2>/dev/null)" || last=""
  if [[ ! "$last" =~ ^[0-9a-f]{40}$ ]]; then
    echo "run=true reason=fail-open: no last green full run found"
    return 0
  fi
  if [[ "$last" == "$sha" ]]; then
    echo "run=false reason=main ${sha} already had a green full run"
    return 0
  fi
  echo "run=true reason=main moved from ${last} to ${sha}"
}

line="$(decide)"
echo "$line"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  printf '%s\n' "${line%% reason=*}" >> "$GITHUB_OUTPUT"
fi
exit 0
