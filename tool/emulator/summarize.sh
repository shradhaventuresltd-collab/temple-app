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
unstarted=()

for flow in "${flows[@]}"; do
  if grep -Eq "^(PASS|FAIL|XFAIL|SKIPPED|NA) ${flow}:" "$results"; then
    continue
  fi
  # Whole-flow "NOT RUN <flow>" or a skipped step "NOT RUN <flow>: <step>".
  if grep -Eq "^NOT RUN ${flow}(:|$)" "$results"; then
    continue
  fi
  # A planned flow with no line at all never started: NOT RUN, not FAIL
  # (run 41306793034 listed every unstarted flow as FAIL missing). A
  # skipped flow is SKIPPED even if run_shard.sh did not record it.
  if plan_is_skipped "$flow"; then
    printf 'SKIPPED %s: location-dependent, skipped on the emulator (EMULATOR_SKIP_FLOWS)\n' "$flow" | tee -a "$results"
  elif [[ "$resolve_outcome" == "failure" ]]; then
    printf 'NOT RUN %s\n' "$flow" | tee -a "$results"
  else
    printf 'NOT RUN %s: did not start\n' "$flow" | tee -a "$results"
    unstarted+=("$flow")
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
    # Counted once, as NOT RUN, above.
    if grep -Eq "^NOT RUN ${flow}: did not start$" "$results"; then
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
xpasses="$(grep -c '^XPASS ' "$results" || true)"
# NA (precondition proven absent) is neither a pass nor a failure here; it
# is listed on its own, and a flow with only NA steps still needs a PASS.
nas="$(grep -c '^NA ' "$results" || true)"
# Round 4.4.1: RETRY lines (the workflow's boot retry) are listed, never
# counted as a pass or a failure.
retries="$(grep -c '^RETRY ' "$results" || true)"

{
  echo "### Emulator app test (${tier}${EMULATOR_SHARD:+ shard ${EMULATOR_SHARD}})"
  echo
  echo "${passes} passed, ${fails} failed, ${xfails} expected failures, ${xpasses} unexpected passes, ${not_run} not run, ${skipped} skipped, ${nas} not applicable."
  echo
  if [[ "$retries" -gt 0 ]]; then
    echo "#### Boot retries (RETRY: ${retries}) - the emulator died before run_shard.sh and the shard ran again"
    echo
    grep '^RETRY ' "$results" | sed 's/^/- /'
    echo
  fi
  if [[ "$nas" -gt 0 ]]; then
    echo "#### Not applicable (NA: ${nas}) - not a pass; the strict release gate refuses unplanned NA"
    echo
    grep '^NA ' "$results" | sed 's/^/- /'
    echo
  fi
  if [[ "$xfails" -gt 0 ]]; then
    echo "#### Expected failures (XFAIL: ${xfails}) - known bugs, not a release gate"
    echo
    grep '^XFAIL ' "$results" | sed 's/^/- /'
    echo
  fi
  if [[ "$xpasses" -gt 0 ]]; then
    echo "#### Unexpected passes (XPASS: ${xpasses}) - remove the XFAIL mark"
    echo
    grep '^XPASS ' "$results" | sed 's/^/- /'
    echo
  fi
  echo '```'
  cat "$results"
  echo '```'
} >> "${GITHUB_STEP_SUMMARY:-/dev/null}"

echo "${passes} passed, ${fails} failed, ${xfails} expected failures, ${xpasses} unexpected passes, ${not_run} not run, ${skipped} skipped, ${nas} not applicable."
if [[ "$retries" -gt 0 ]]; then
  echo "RETRY (${retries}):"
  grep '^RETRY ' "$results" | sed 's/^/  /'
fi
if [[ "$nas" -gt 0 ]]; then
  echo "NA (${nas}):"
  grep '^NA ' "$results" | sed 's/^/  /'
fi
if [[ "$xfails" -gt 0 ]]; then
  echo "XFAIL (${xfails}):"
  grep '^XFAIL ' "$results" | sed 's/^/  /'
fi
if [[ "$xpasses" -gt 0 ]]; then
  grep '^XPASS ' "$results" | sed 's/^/::error::/'
  echo "summarize.sh: ${xpasses} XFAIL step(s) passed; remove their XFAIL marks" >&2
  exit 1
fi
if [[ "$fails" -ne 0 ]]; then
  exit 1
fi
# Planned flows that never started are not failures of the app, but the
# job is not green either: the runner lost them.
if [[ ${#unstarted[@]} -gt 0 ]]; then
  echo "summarize.sh: ${#unstarted[@]} planned flow(s) did not start: ${unstarted[*]}" >&2
  exit 1
fi
exit 0
