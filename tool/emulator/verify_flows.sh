#!/usr/bin/env bash
# Fail fast when the checked-out scripts are not the ones this workflow expects.
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

workflow=.github/workflows/emulator-app-test.yml
missing=0
for slice in 29a 29b 29c 29d 29e 29f 29g 29h 29i 29j 29k 29l 30a 30b 30c 30d; do
  matches=(tool/emulator/flows/${slice}_*.sh)
  if [[ ! -f "${matches[0]}" ]]; then
    echo "::error::missing flow file tool/emulator/flows/${slice}_*.sh" >&2
    missing=1
  fi
  if ! grep -q "^      - name: Flow ${slice} " "$workflow"; then
    echo "::error::workflow has no step 'Flow ${slice}'" >&2
    missing=1
  fi
done
if [[ -e tool/emulator/flows/29_filter_matrix.sh ]]; then
  echo "::error::old 29_filter_matrix.sh is present; scripts are from an old ref" >&2
  missing=1
fi
# Every flow script referenced by the workflow must exist.
while IFS= read -r f; do
  if [[ ! -f "$f" ]]; then
    echo "::error::workflow references missing ${f}" >&2
    missing=1
  fi
done < <(grep -oE 'tool/emulator/flows/[A-Za-z0-9_]+\.sh' "$workflow" | sort -u)
exit "$missing"
