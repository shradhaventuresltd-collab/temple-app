#!/usr/bin/env bash
# Write results to the job summary and fail if any flow failed.
# XFAIL and NOT RUN are reported and do not fail the job.
# When Resolve APK source failed, a flow that never started is NOT RUN.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
results="${EMULATOR_ARTIFACTS:-${root}/emulator-app-test-artifacts}/results.txt"
mkdir -p "$(dirname "$results")"
touch "$results"

flows=(
  01-first-launch
  02-policy-gate
  03-force-update
  04-home
  05-search
  06-filters
  07-district
  08-list-detail
  09-photos
  10-directions
  11-near-me
  12-ads
  13-licences
  14-back-relaunch
  15-offline
)

resolve_outcome="${EMULATOR_RESOLVE_OUTCOME:-success}"

for flow in "${flows[@]}"; do
  if grep -Eq "^(PASS|FAIL|XFAIL) ${flow}:" "$results"; then
    continue
  fi
  if grep -Eq "^NOT RUN ${flow}$" "$results"; then
    continue
  fi
  if [[ "$resolve_outcome" == "failure" ]]; then
    printf 'NOT RUN %s\n' "$flow" | tee -a "$results"
  else
    printf 'FAIL %s: missing: flow did not report a result\n' "$flow" | tee -a "$results"
  fi
done

passes="$(grep -c '^PASS ' "$results" || true)"
fails="$(grep -c '^FAIL ' "$results" || true)"
xfails="$(grep -c '^XFAIL ' "$results" || true)"
not_run="$(grep -c '^NOT RUN ' "$results" || true)"

{
  echo "### Emulator app test"
  echo
  echo "${passes} passed, ${fails} failed, ${xfails} expected failures, ${not_run} not run."
  echo
  echo '```'
  cat "$results"
  echo '```'
} >> "${GITHUB_STEP_SUMMARY:-/dev/null}"

echo "${passes} passed, ${fails} failed, ${xfails} expected failures, ${not_run} not run."
if [[ "$fails" -ne 0 ]]; then
  exit 1
fi
exit 0
