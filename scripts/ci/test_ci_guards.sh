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

expect_eq "analyze-test and android-smoke share one total" \
  "$(sum_minutes 12.50 7.25)" "19.75"
expect_eq "minutes total is analyze-test plus android-smoke" \
  "$(minutes_workflows)" $'ci.yml\nandroid-smoke.yml'
expect_eq "1,500 alert says to cut smoke to 10 AM and 10 PM IST" \
  "$(minutes_over_budget_action)" \
  "Change the android-smoke cron to two runs a day, 10 AM and 10 PM IST (cron '30 4,16 * * *')."

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
