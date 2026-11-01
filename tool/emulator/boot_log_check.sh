#!/usr/bin/env bash
# Summary job: scan each emulator job's log for a failed snapshot load and
# print "boot: snapshot" or "boot: cold" per job. Read-only (actions: read).
# Needs GH_TOKEN, GITHUB_REPOSITORY, GITHUB_RUN_ID; never fails the job.
# Usage: boot_log_check.sh            (CI)
#        boot_log_check.sh --file LOG (one saved job log, for the self-test)
set -uo pipefail

classify() {
  if grep -Eq "cannot load snapshot|different AVD configuration" "$1"; then
    echo cold
  else
    echo snapshot
  fi
}

report() {
  local name="$1" verdict="$2"
  echo "boot: ${verdict} (${name})"
  [[ -n "${GITHUB_STEP_SUMMARY:-}" ]] && echo "boot: ${verdict} (${name})" >> "$GITHUB_STEP_SUMMARY"
  if [[ "$verdict" == cold ]]; then
    echo "::warning::${name}: emulator log has 'cannot load snapshot' or 'different AVD configuration'; it cold-booted"
  fi
}

if [[ "${1:-}" == --file ]]; then
  report "${3:-log}" "$(classify "$2")"
  exit 0
fi

: "${GITHUB_REPOSITORY:?}" "${GITHUB_RUN_ID:?}"
jobs="$(gh api "repos/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}/attempts/${GITHUB_RUN_ATTEMPT:-1}/jobs?per_page=100" \
  --jq '.jobs[] | select(.name | startswith("emulator")) | "\(.id)\t\(.name)"' 2>/dev/null)" || {
  echo "::warning::boot log check: could not list jobs"; exit 0; }
tmp="$(mktemp)"
while IFS=$'\t' read -r id name; do
  [[ -n "$id" ]] || continue
  if gh api "repos/${GITHUB_REPOSITORY}/actions/jobs/${id}/logs" > "$tmp" 2>/dev/null; then
    report "$name" "$(classify "$tmp")"
  else
    echo "boot: unknown (${name}: log not readable)"
  fi
done <<<"$jobs"
rm -f "$tmp"
exit 0
