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

# The expected flows come from plan.sh: EMULATOR_TIER (smoke, full, all;
# default all) and, for full, EMULATOR_SHARD.
# shellcheck source=SCRIPTDIR/plan.sh
source "${root}/tool/emulator/plan.sh"
tier="${EMULATOR_TIER:-all}"
if ! mapfile -t flows < <(plan_ids "$tier" "${EMULATOR_SHARD:-}"); then
  exit 1
fi
if [[ ${#flows[@]} -eq 0 ]]; then
  echo "summarize.sh: no flows planned for tier ${tier}" >&2
  exit 1
fi

resolve_outcome="${EMULATOR_RESOLVE_OUTCOME:-success}"

for flow in "${flows[@]}"; do
  if grep -Eq "^(PASS|FAIL|XFAIL|SKIPPED) ${flow}:" "$results"; then
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
    # A skipped location-dependent flow reports SKIPPED and needs no PASS.
    if grep -Eq "^SKIPPED ${flow}:" "$results"; then
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
skipped="$(grep -c '^SKIPPED ' "$results" || true)"

{
  echo "### Emulator app test (${tier}${EMULATOR_SHARD:+ shard ${EMULATOR_SHARD}})"
  echo
  echo "${passes} passed, ${fails} failed, ${xfails} expected failures, ${not_run} not run, ${skipped} skipped."
  echo
  echo '```'
  cat "$results"
  echo '```'
} >> "${GITHUB_STEP_SUMMARY:-/dev/null}"

echo "${passes} passed, ${fails} failed, ${xfails} expected failures, ${not_run} not run, ${skipped} skipped."
if [[ "$fails" -ne 0 ]]; then
  exit 1
fi
exit 0
