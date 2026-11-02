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

# Shard results first: run_shard.sh writes "BOOT <tier>-<shard> <verdict>"
# from the RAM-only marker property, and the summary job already has the
# results artifacts. Run 41373837994 printed "boot: unknown (... log not
# readable)" for all six jobs: the jobs/<id>/logs API was not readable from
# the summary job. The API scan is only the fallback now, and its error is
# printed instead of swallowed.
# Usage: boot_log_check.sh --results DIR (DIR/*/results.txt)
from_results() {
  local dir="$1" f n=0 tag verdict
  for f in "$dir"/*/results.txt; do
    [[ -f "$f" ]] || continue
    while read -r _ tag verdict; do
      [[ -n "$tag" ]] || continue
      report "emulator ${tag}" "$verdict"
      n=$((n + 1))
    done < <(grep -E '^BOOT [^ ]+ (snapshot|cold)$' "$f")
  done
  (( n > 0 ))
}

if [[ "${1:-}" == --results ]]; then
  from_results "${2:-shard-results}" || echo "boot: unknown (no BOOT lines under ${2:-shard-results})"
  exit 0
fi
if [[ -d shard-results ]] && from_results shard-results; then
  exit 0
fi

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
  if gh api "repos/${GITHUB_REPOSITORY}/actions/jobs/${id}/logs" > "$tmp" 2>"${tmp}.err"; then
    report "$name" "$(classify "$tmp")"
  else
    echo "boot: unknown (${name}: log not readable: $(head -c 200 "${tmp}.err" | tr '\n' ' '))"
  fi
done <<<"$jobs"
rm -f "$tmp" "${tmp}.err"
exit 0
