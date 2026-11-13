#!/usr/bin/env bash
# Fail fast when the checked-out scripts are not the ones this tree expects.
# After merging main into PR 124: CI is sharded (run_shard.sh + plan.sh),
# the KAN-198 matrix lives in 29_filter_matrix.sh, and PR 124's 29a–29m /
# 30a–30d wrappers remain as entry points into that matrix.
# Logs the resolved scripts SHA and the dispatched ref so a run log shows both.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

scripts_sha="$(git rev-parse HEAD 2>/dev/null || echo unknown)"
echo "scripts SHA: ${scripts_sha}"
echo "dispatched ref: ${DISPATCH_REF:-unset} (${DISPATCH_SHA:-unset})"
echo "input ref: ${INPUT_REF:-<none>}"

if [[ -n "${INPUT_REF:-}" ]]; then
  want="$(git rev-parse --verify --quiet "${INPUT_REF}^{commit}" 2>/dev/null || true)"
  if [[ -n "$want" && "$want" != "$scripts_sha" ]]; then
    echo "::error::scripts SHA ${scripts_sha} != input ref ${INPUT_REF} (${want})" >&2
    exit 1
  fi
fi

missing=0

if [[ ! -f tool/emulator/flows/29_filter_matrix.sh ]]; then
  echo "::error::missing tool/emulator/flows/29_filter_matrix.sh (KAN-198 matrix)" >&2
  missing=1
fi
if [[ ! -f tool/emulator/plan.sh || ! -f tool/emulator/run_shard.sh ]]; then
  echo "::error::missing plan.sh or run_shard.sh (shard tooling from main)" >&2
  missing=1
fi
if ! grep -q 'run_shard.sh' .github/workflows/emulator-app-test.yml; then
  echo "::error::workflow does not invoke run_shard.sh" >&2
  missing=1
fi

for slice in 29a 29b 29c 29d 29e 29f 29g 29h 29i 29j 29k 29l 29m 30a 30b 30c 30d; do
  matches=(tool/emulator/flows/${slice}_*.sh)
  if [[ ! -f "${matches[0]}" ]]; then
    echo "::error::missing flow file tool/emulator/flows/${slice}_*.sh" >&2
    missing=1
  fi
done

if ! grep -q 'MATRIX_ACTIONS="select pick-close dismiss-empty"' tool/emulator/flows/29h_search_district.sh; then
  echo "::error::29h must run the first three search x district actions" >&2
  missing=1
fi
if ! grep -q 'MATRIX_ACTIONS="back-empty outside-empty clear"' tool/emulator/flows/29m_search_district_rest.sh; then
  echo "::error::29m must run the last three search x district actions" >&2
  missing=1
fi
if ! grep -q 'search:district:2' tool/emulator/plan.sh; then
  echo "::error::plan.sh must include search x district half 2 (30f2 / 29m)" >&2
  missing=1
fi

# Every flow script referenced by plan.sh must exist.
# shellcheck source=plan.sh
source tool/emulator/plan.sh
for row in "${PLAN_ROWS[@]}"; do
  IFS='|' read -r id script part sh cap <<<"$row"
  if [[ ! -f "$script" ]]; then
    echo "::error::plan.sh references missing ${script} (flow ${id})" >&2
    missing=1
  fi
done

exit "$missing"
