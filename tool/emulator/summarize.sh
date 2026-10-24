#!/usr/bin/env bash
# Write results to the job summary and fail if any flow failed or never reported.
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

for flow in "${flows[@]}"; do
  if ! grep -Eq "^(PASS|FAIL) ${flow}:" "$results"; then
    printf 'FAIL %s: missing: flow did not report a result\n' "$flow" | tee -a "$results"
  fi
done

passes="$(grep -c '^PASS ' "$results" || true)"
fails="$(grep -c '^FAIL ' "$results" || true)"

{
  echo "### Emulator app test"
  echo
  echo "${passes} passed, ${fails} failed."
  echo
  echo '```'
  cat "$results"
  echo '```'
} >> "${GITHUB_STEP_SUMMARY:-/dev/null}"

echo "${passes} passed, ${fails} failed."
if [[ "$fails" -ne 0 ]]; then
  exit 1
fi
exit 0
