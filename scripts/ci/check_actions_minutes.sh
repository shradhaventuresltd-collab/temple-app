#!/usr/bin/env bash
# Compare GitHub Actions usage with the 2,000 minute private-repo budget.
# Opens or updates one issue labelled actions-minutes at or above 75% (1,500).
#
# The total compared with 1,500 is analyze-test minutes plus android-smoke
# minutes for this repository. Each job that ran is timed from started_at to
# completed_at on /actions/runs/<id>/jobs, rounded up to a whole minute, with
# a 1-minute minimum. Skipped jobs are not counted. The run timing API is not
# used. An Actions API error fails the check, and so does a workflow that has
# runs but a minute total of 0.
#
# /settings/billing/usage is not called. That report mixes products and unit
# types (quantity on one route, grossQuantity on the summary), and it is not
# a reliable Actions-minute total for this user-owned account.
set -euo pipefail

budget_minutes=2000
threshold_minutes=1500

# Exit 0 when usage is at or above 75% of the 2,000 minute budget.
minutes_at_or_over_threshold() {
  awk -v used="$1" -v limit="$threshold_minutes" 'BEGIN { exit !(used + 0 >= limit) }'
}

# Workflow files whose billable minutes share one total.
minutes_workflows() {
  printf '%s\n' "ci.yml" "android-smoke.yml"
}

sum_minutes() {
  awk -v a="$1" -v b="$2" 'BEGIN { printf "%.2f", (a + 0) + (b + 0) }'
}

# Exact instruction written to the actions-minutes issue at 1,500 minutes.
minutes_over_budget_action() {
  printf '%s\n' "Change the android-smoke cron to two runs a day, 10 AM and 10 PM IST (cron '30 4,16 * * *')."
}

# Whole minutes for one job. Skipped jobs print 0. A job that ran is at
# least 1 minute, rounded up. Missing timestamps on a job that ran fail.
job_billable_minutes() {
  local conclusion="$1"
  local started="$2"
  local completed="$3"
  local start_epoch end_epoch seconds
  if [[ "$conclusion" == "skipped" ]]; then
    printf '0\n'
    return 0
  fi
  if [[ -z "$started" || "$started" == "null" || -z "$completed" || "$completed" == "null" ]]; then
    echo "error: a job with conclusion '${conclusion}' is missing started_at or completed_at." >&2
    return 1
  fi
  start_epoch="$(date -u -d "$started" +%s)" || return 1
  end_epoch="$(date -u -d "$completed" +%s)" || return 1
  if [[ "$end_epoch" -lt "$start_epoch" ]]; then
    echo "error: completed_at ${completed} is before started_at ${started}." >&2
    return 1
  fi
  seconds=$((end_epoch - start_epoch))
  awk -v s="$seconds" 'BEGIN { m = int((s + 59) / 60); if (m < 1) m = 1; printf "%d\n", m }'
}

# Fail when runs were listed and the computed minute total is 0.
require_minutes_if_runs() {
  local run_count="$1"
  local minutes="$2"
  local label="$3"
  if [[ "$run_count" -gt 0 && "$minutes" -eq 0 ]]; then
    echo "error: ${label} has ${run_count} runs but the minute total is 0." >&2
    return 1
  fi
}

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  return 0 2>/dev/null || exit 0
fi

repo="${GITHUB_REPOSITORY:?}"
source_label=""
used=""
month_start="$(date -u +%Y-%m-01)"
today="$(date -u +%Y-%m-%d)"

# Whole minutes for one workflow file during the current calendar month.
# API errors propagate. A listed run with no measurable jobs fails.
workflow_minutes() {
  local workflow_file="$1"
  local ids id jobs conclusion started completed job_minutes
  local total=0 run_count=0
  if ! ids="$(gh api --paginate "repos/${repo}/actions/workflows/${workflow_file}/runs?created=${month_start}..${today}&per_page=100" --jq '.workflow_runs[].id')"; then
    echo "error: could not list ${workflow_file} runs." >&2
    return 1
  fi
  if [[ -z "$ids" ]]; then
    printf '0\n'
    return 0
  fi
  while IFS= read -r id; do
    [[ -z "$id" ]] && continue
    run_count=$((run_count + 1))
    if ! jobs="$(gh api --paginate "repos/${repo}/actions/runs/${id}/jobs" --jq '.jobs[] | [.conclusion // "null", .started_at // "null", .completed_at // "null"] | @tsv')"; then
      echo "error: could not list jobs for ${workflow_file} run ${id}." >&2
      return 1
    fi
    if [[ -z "$jobs" ]]; then
      echo "error: ${workflow_file} run ${id} returned no jobs." >&2
      return 1
    fi
    while IFS=$'\t' read -r conclusion started completed; do
      [[ -z "${conclusion}${started}${completed}" ]] && continue
      job_minutes="$(job_billable_minutes "$conclusion" "$started" "$completed")" || return 1
      total=$((total + job_minutes))
    done <<<"$jobs"
  done <<<"$ids"
  require_minutes_if_runs "$run_count" "$total" "$workflow_file" || return 1
  printf '%s\n' "$total"
}

analyze_minutes="$(workflow_minutes ci.yml)"
smoke_minutes="$(workflow_minutes android-smoke.yml)"
used="$((analyze_minutes + smoke_minutes))"
source_label="Sum of job minutes for analyze-test (ci.yml) and android-smoke (android-smoke.yml) in ${repo} from ${month_start} through ${today} UTC. Each job that ran is rounded up from started_at to completed_at, with a 1-minute minimum. Skipped jobs are not counted."

echo "Actions minutes used: ${used} / ${budget_minutes} (${source_label})"

if ! minutes_at_or_over_threshold "$used"; then
  echo "Under 75% (${threshold_minutes} minutes). No issue."
  exit 0
fi

body_file="$(mktemp)"
action="$(minutes_over_budget_action)"
{
  echo "Actions usage is at or above 1,500 of 2,000 free private minutes."
  echo
  echo "- analyze-test: ${analyze_minutes} minutes"
  echo "- android-smoke: ${smoke_minutes} minutes"
  echo "- Total: ${used} minutes (analyze-test and android-smoke together)"
  echo "- Budget: ${budget_minutes} minutes"
  echo "- Threshold: ${threshold_minutes} minutes (75%)"
  echo "- Source: ${source_label}"
  echo
  echo "${action}"
  echo
  echo "The android-smoke schedule stays four runs a day until that cron is changed."
  echo
  echo "Checked at ${today} UTC by the actions-minutes workflow."
} >"$body_file"
echo "${action}"

gh label create actions-minutes \
  --repo "$repo" \
  --color D93F0B \
  --description "Actions minutes at or above 75% of 2000" \
  >/dev/null 2>&1 || true

existing="$(gh issue list --repo "$repo" --state open --label actions-minutes --limit 1 --json number --jq '.[0].number')"
title="Actions minutes passed 75% of 2,000"
if [[ -z "$existing" || "$existing" == "null" ]]; then
  gh issue create --repo "$repo" --label actions-minutes --title "$title" --body-file "$body_file"
else
  gh issue edit "$existing" --repo "$repo" --title "$title" --body-file "$body_file"
  echo "Updated issue #${existing}."
fi
