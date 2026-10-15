#!/usr/bin/env bash
# Decision checks for the smoke schedule and the Actions minute budget.
# Does not call GitHub.
set -euo pipefail

cd "$(dirname "$0")/../.."

# shellcheck source=smoke_should_run.sh
source scripts/ci/smoke_should_run.sh
# shellcheck source=check_actions_minutes.sh
source scripts/ci/check_actions_minutes.sh

expect_eq() {
  local desc="$1" got="$2" want="$3"
  if [[ "$got" != "$want" ]]; then
    echo "FAIL: ${desc}: got '${got}', want '${want}'" >&2
    exit 1
  fi
  echo "ok: ${desc}"
}

expect_eq "dispatch runs even when main is already green" \
  "$(smoke_should_run workflow_dispatch abc abc)" true
expect_eq "dispatch runs even when main HEAD is the last failed SHA" \
  "$(smoke_should_run workflow_dispatch abc "" abc)" true
expect_eq "schedule skips when main HEAD is the last green SHA" \
  "$(smoke_should_run schedule abc abc)" false
expect_eq "schedule skips when main HEAD is the last failed SHA" \
  "$(smoke_should_run schedule abc "" abc)" false
expect_eq "schedule cancel blocks a scheduled retry" \
  "$(smoke_should_run schedule abc "" "$(failed_attempt_sha cancelled abc schedule)")" false
expect_eq "dispatch cancel does not block a scheduled retry" \
  "$(smoke_should_run schedule abc "" "$(failed_attempt_sha cancelled abc workflow_dispatch)")" true
expect_eq "failure conclusion still blocks a scheduled retry" \
  "$(smoke_should_run schedule abc "" "$(failed_attempt_sha failure abc)")" false
expect_eq "schedule runs when main moved" \
  "$(smoke_should_run schedule abc def failed)" true
expect_eq "schedule runs when nothing has ever gone green" \
  "$(smoke_should_run schedule abc "")" true
expect_eq "pull_request runs even when that SHA is already green" \
  "$(smoke_should_run pull_request abc abc abc)" true
expect_eq "pull_request runs even when that SHA is the last failed SHA" \
  "$(smoke_should_run pull_request abc "" abc)" true

if gate_accepts_smoke_run pull_request; then
  echo "FAIL: a pull_request smoke run must not satisfy the Play gate" >&2
  exit 1
fi
echo "ok: pull_request smoke does not satisfy the Play gate"
if ! gate_accepts_smoke_run schedule; then
  echo "FAIL: a schedule run on the exact SHA must satisfy the Play gate" >&2
  exit 1
fi
echo "ok: schedule smoke can satisfy the Play gate"
if ! gate_accepts_smoke_run workflow_dispatch; then
  echo "FAIL: a workflow_dispatch run on the exact SHA must satisfy the Play gate" >&2
  exit 1
fi
echo "ok: workflow_dispatch smoke can satisfy the Play gate"

pr_report="$(GITHUB_EVENT_NAME=pull_request bash scripts/ci/report_smoke_failure.sh)"
expect_eq "pull_request does not file a smoke-failure issue" \
  "$pr_report" "Not filing a smoke-failure issue for a pull_request run."

plan_dir="$(mktemp -d)"
fake_bin="$(mktemp -d)"
cat >"$fake_bin/gh" <<'EOF'
#!/bin/sh
echo "gh should not be called for a pull_request plan" >&2
exit 1
EOF
chmod +x "$fake_bin/gh"
PATH="$fake_bin:/usr/bin:/bin" \
  GITHUB_OUTPUT="$plan_dir/out" \
  GITHUB_EVENT_NAME=pull_request \
  GITHUB_SHA=merge-ref \
  PR_HEAD_SHA=pr-head \
  GITHUB_REPOSITORY=example/repo \
  bash scripts/ci/android_smoke_plan.sh >/dev/null
expect_eq "pull_request plan should_run" \
  "$(grep '^should_run=' "$plan_dir/out" | cut -d= -f2-)" true
expect_eq "pull_request plan records the PR head, not the merge ref" \
  "$(grep '^head_sha=' "$plan_dir/out" | cut -d= -f2-)" pr-head
rm -rf "$plan_dir" "$fake_bin"

if ! grep -q 'select(.event != "pull_request")' scripts/ci/android_smoke_plan.sh; then
  echo "FAIL: last-green and last-failed lookups must ignore pull_request runs" >&2
  exit 1
fi
echo "ok: schedule lookups ignore pull_request runs"

perm_jobs="$(awk '
  /^  [a-z0-9-]+:$/ { job=$1; sub(/:$/, "", job) }
  /^      pull-requests: write$/ { print job }
' .github/workflows/android-smoke.yml)"
expect_eq "pull-requests: write is only on the label-removal job" \
  "$perm_jobs" "remove-run-smoke-label"
if ! grep -q 'needs.android-smoke.result == '"'"'success'"'"'' .github/workflows/android-smoke.yml; then
  echo "FAIL: run-smoke is removed only after a green pull_request smoke" >&2
  exit 1
fi
echo "ok: run-smoke is removed only after a green pull_request smoke"

if ! grep -q 'JOB_START_EPOCH=$(date +%s)' .github/workflows/android-smoke.yml; then
  echo "FAIL: the smoke job must record JOB_START_EPOCH in its first step" >&2
  exit 1
fi
echo "ok: the smoke job records JOB_START_EPOCH"
if grep -q 'SECONDS >= 600' scripts/ci/run_android_smoke.sh; then
  echo "FAIL: screenshot skip must use job start, not \$SECONDS" >&2
  exit 1
fi
# shellcheck source=screenshot_budget.sh
source scripts/ci/screenshot_budget.sh
expect_eq "screenshot cap at job start is 180s" \
  "$(screenshot_timeout_cap 0)" 180
expect_eq "screenshot cap just under 10 minutes stays 180s" \
  "$(screenshot_timeout_cap 599)" 180
expect_eq "screenshot cap at 700s is the time left before 780s" \
  "$(screenshot_timeout_cap 700)" 80
expect_eq "screenshot cap at 780s is 0" \
  "$(screenshot_timeout_cap 780)" 0
expect_eq "screenshots run for 180s near the start" \
  "$(screenshot_run_seconds 0)" 180
expect_eq "screenshots are skipped once 600s have passed" \
  "$(screenshot_run_seconds 600)" ""
expect_eq "screenshots are skipped at 700s even though 80s remain" \
  "$(screenshot_run_seconds 700)" ""
echo "ok: screenshot budget uses job start and the 780s cap"

if minutes_at_or_over_threshold 1499.9; then
  echo "FAIL: 1499.9 should be under the 75% threshold" >&2
  exit 1
fi
echo "ok: 1499.9 is under 75%"

if ! minutes_at_or_over_threshold 1500; then
  echo "FAIL: 1500 should meet the 75% threshold" >&2
  exit 1
fi
echo "ok: 1500 meets 75%"

if ! minutes_at_or_over_threshold 2000; then
  echo "FAIL: 2000 should meet the 75% threshold" >&2
  exit 1
fi
echo "ok: 2000 meets 75%"

expect_eq "every workflow shares one total" \
  "$(sum_workflow_minutes 12 7 40 1)" 60
listed="$(printf '%s\n' \
  '222	.github/workflows/android-smoke.yml' \
  '444	.github/workflows/actions-minutes.yml' \
  '161335	.github/workflows/ci.yml' \
  '333	.github/workflows/demo-seed-launch.yml' \
  '555	.github/workflows/retired.yml' \
  | workflow_rows_from_api_tsv)"
expect_eq "the minutes total lists every workflow, including deleted ones" \
  "$listed" \
  $'444\tactions-minutes.yml\n222\tandroid-smoke.yml\n161335\tci.yml\n333\tdemo-seed-launch.yml\n555\tretired.yml'
if workflow_rows_from_api_tsv </dev/null >/dev/null 2>&1; then
  echo "FAIL: an empty workflow list should fail" >&2
  exit 1
fi
echo "ok: an empty workflow list fails"
if grep -q 'printf '"'"'%s\\n'"'"' "ci.yml" "android-smoke.yml"' scripts/ci/check_actions_minutes.sh; then
  echo "FAIL: workflow minutes must not be a hardcoded ci.yml plus android-smoke.yml list" >&2
  exit 1
fi
echo "ok: workflow minutes are not a hardcoded pair"
if ! grep -q 'actions/workflows?per_page=100' scripts/ci/check_actions_minutes.sh; then
  echo "FAIL: workflows must be listed through the Actions API" >&2
  exit 1
fi
echo "ok: workflows are listed through the Actions API"
expect_eq "1,500 alert says to cut smoke to 10 AM and 10 PM IST" \
  "$(minutes_over_budget_action)" \
  "Change the android-smoke cron to two runs a day, 10 AM and 10 PM IST (cron '30 4,16 * * *')."
expect_eq "issue names this repository's minutes and the shared quota" \
  "$(minutes_issue_opening)" \
  "This repository's Actions minutes are at or above 1,500 of 2,000 free private minutes. Those 2,000 minutes are shared across the account. Other repositories on the account use the same quota and are not included in this total."
if ! grep -q "this repository's minutes" docs/testing.md; then
  echo "FAIL: docs must say this repository's minutes" >&2
  exit 1
fi
echo "ok: docs say this repository's minutes"
if ! grep -q 'Other repositories use the same quota' docs/testing.md; then
  echo "FAIL: docs must note that other repositories share the quota" >&2
  exit 1
fi
echo "ok: docs note that other repositories share the quota"
if ! grep -q 'demo-seed-launch.yml' docs/testing.md || ! grep -q 'actions-minutes.yml' docs/testing.md; then
  echo "FAIL: docs must include demo-seed-launch.yml and actions-minutes.yml in the minutes total" >&2
  exit 1
fi
echo "ok: docs include demo-seed-launch and actions-minutes"

minutes_bin="$(mktemp -d)"
cat >"$minutes_bin/gh" <<'EOF'
#!/bin/bash
url=""
for arg in "$@"; do
  case "$arg" in
    repos/*) url="$arg" ;;
  esac
done
case "$url" in
  repos/example/repo/actions/workflows\?per_page=100)
    printf '%s\n' \
      '10	.github/workflows/ci.yml' \
      '20	.github/workflows/android-smoke.yml' \
      '30	.github/workflows/demo-seed-launch.yml' \
      '40	.github/workflows/actions-minutes.yml'
    ;;
  repos/example/repo/actions/workflows/10/runs\?*)
    echo 1001
    ;;
  repos/example/repo/actions/workflows/20/runs\?*)
    echo 2001
    ;;
  repos/example/repo/actions/workflows/30/runs\?*)
    echo 3001
    ;;
  repos/example/repo/actions/workflows/40/runs\?*)
    echo 4001
    ;;
  repos/example/repo/actions/runs/1001/jobs\?*)
    printf 'success\t2026-10-01T00:00:00Z\t2026-10-01T00:02:00Z\n'
    ;;
  repos/example/repo/actions/runs/2001/jobs\?*)
    printf 'success\t2026-10-01T00:00:00Z\t2026-10-01T00:03:00Z\n'
    ;;
  repos/example/repo/actions/runs/3001/jobs\?*)
    printf 'success\t2026-10-01T00:00:00Z\t2026-10-01T00:40:00Z\n'
    ;;
  repos/example/repo/actions/runs/4001/jobs\?*)
    printf 'success\t2026-10-01T00:00:00Z\t2026-10-01T00:01:00Z\n'
    ;;
  *)
    echo "unexpected gh url: ${url}" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$minutes_bin/gh"
minutes_out="$(PATH="$minutes_bin:/usr/bin:/bin" GITHUB_REPOSITORY=example/repo bash scripts/ci/check_actions_minutes.sh)"
case "$minutes_out" in
  "This repository's minutes: 46 / 2000 "*) ;;
  *)
    echo "FAIL: minutes total should be 46 across every workflow, got: ${minutes_out}" >&2
    exit 1
    ;;
esac
echo "ok: minutes total includes ci, android-smoke, demo-seed-launch, and actions-minutes"
rm -rf "$minutes_bin"

expect_eq "skipped job does not count" \
  "$(job_billable_minutes skipped 2026-10-01T00:00:00Z 2026-10-01T00:05:00Z)" 0
expect_eq "skipped job with no timestamps does not count" \
  "$(job_billable_minutes skipped null null)" 0
expect_eq "a job without completed_at is skipped" \
  "$(job_billable_minutes failure null null)" 0
expect_eq "an in-progress job is skipped" \
  "$(job_billable_minutes success 2026-10-01T00:00:00Z null)" 0
expect_eq "a job that ran is at least 1 minute" \
  "$(job_billable_minutes success 2026-10-01T00:00:00Z 2026-10-01T00:00:00Z)" 1
expect_eq "30 seconds rounds up to 1 minute" \
  "$(job_billable_minutes success 2026-10-01T00:00:00Z 2026-10-01T00:00:30Z)" 1
expect_eq "60 seconds is 1 minute" \
  "$(job_billable_minutes success 2026-10-01T00:00:00Z 2026-10-01T00:01:00Z)" 1
expect_eq "61 seconds rounds up to 2 minutes" \
  "$(job_billable_minutes success 2026-10-01T00:00:00Z 2026-10-01T00:01:01Z)" 2
expect_eq "cancelled job still counts" \
  "$(job_billable_minutes cancelled 2026-10-01T00:00:00Z 2026-10-01T00:01:30Z)" 2

if job_billable_minutes success null 2026-10-01T00:01:00Z >/dev/null 2>&1; then
  echo "FAIL: a finished job missing started_at should fail" >&2
  exit 1
fi
echo "ok: a finished job missing started_at fails"

if job_billable_minutes success 2026-10-01T00:02:00Z 2026-10-01T00:01:00Z >/dev/null 2>&1; then
  echo "FAIL: completed_at before started_at should fail" >&2
  exit 1
fi
echo "ok: completed_at before started_at fails"

require_minutes_if_runs 0 0 0 ci.yml
echo "ok: no runs and 0 minutes is allowed"
require_minutes_if_runs 3 0 0 android-smoke.yml
echo "ok: all-skipped runs are not a zero-total error"
if require_minutes_if_runs 2 0 1 android-smoke.yml >/dev/null 2>&1; then
  echo "FAIL: finished jobs with a 0 minute total should fail" >&2
  exit 1
fi
echo "ok: finished jobs with a 0 minute total fails"
require_minutes_if_runs 2 5 2 android-smoke.yml
echo "ok: runs with measured minutes pass"

echo "CI guard checks passed."
