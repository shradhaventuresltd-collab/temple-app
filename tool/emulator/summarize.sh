#!/usr/bin/env bash
# Write results to the job summary and fail if any flow failed.
# XFAIL is reported and does not fail the job by itself.
# A flow with no PASS is a failure, including one that only skipped steps.
# When Resolve APK source failed, a flow that never started is NOT RUN
# and is not required to have a PASS.
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
  16-home-browse
  17-entry-matrix
  18-home-reselect
  19-rotation-state
  20-empty-and-back
  21-district-close-then-other-chip
  22-filter-combos-reset
  23-near-me-settings-roundtrip
  24-gallery-autoadvance-viewer
  25-directions-edge
  26-drawer-nav-stack
  27-offline-cold-start
  28-small-screen-rotation-overflow
  29-filter-matrix
)

resolve_outcome="${EMULATOR_RESOLVE_OUTCOME:-success}"

for flow in "${flows[@]}"; do
  if grep -Eq "^(PASS|FAIL|XFAIL) ${flow}:" "$results"; then
    continue
  fi
  # Whole-flow "NOT RUN <flow>" or a skipped step "NOT RUN <flow>: <step>".
  if grep -Eq "^NOT RUN ${flow}(:|$)" "$results"; then
    continue
  fi
  if [[ "$resolve_outcome" == "failure" ]]; then
    printf 'NOT RUN %s\n' "$flow" | tee -a "$results"
  else
    printf 'FAIL %s: missing: flow did not report a result\n' "$flow" | tee -a "$results"
  fi
done

# Skipped steps do not make a flow green. Require a PASS unless the
# flow never started because APK resolution failed.
if [[ "$resolve_outcome" != "failure" ]]; then
  for flow in "${flows[@]}"; do
    if grep -Eq "^PASS ${flow}:" "$results"; then
      continue
    fi
    if grep -Eq "^FAIL ${flow}:" "$results"; then
      continue
    fi
    printf 'FAIL %s: missing: flow did not pass any step\n' "$flow" | tee -a "$results"
  done
fi

# START is written before the timed run. DONE is written only when that
# run exits 0. A kill after an early PASS still has to fail the flow.
for flow in "${flows[@]}"; do
  if ! grep -qx "START ${flow}" "$results"; then
    continue
  fi
  if grep -qx "DONE ${flow}" "$results"; then
    continue
  fi
  if grep -Eq "^FAIL ${flow}:" "$results"; then
    continue
  fi
  printf 'FAIL %s: timeout: started but did not finish\n' "$flow" | tee -a "$results"
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
