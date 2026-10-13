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

echo "CI guard checks passed."
