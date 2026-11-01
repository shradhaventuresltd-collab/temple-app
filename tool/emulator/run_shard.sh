#!/usr/bin/env bash
# Run one tier or shard of emulator flows on the emulator that is already
# booted (one snapshot boot per job). Each flow goes through
# run_one_flow.sh, which caps it at FLOW_BUDGET (600s), skips the
# location-dependent flows, and clears app data (pm clear) before every
# flow after the first.
#
# Usage: run_shard.sh smoke
#        run_shard.sh full <shard 1-6>
#        run_shard.sh all
# EMULATOR_SHARD_DRY_RUN=1 prints the plan and runs nothing.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT" || exit 1
# shellcheck source=SCRIPTDIR/plan.sh
source "${ROOT}/tool/emulator/plan.sh"

tier="${1:-}"
shard="${2:-}"
if [[ "$tier" == full && -z "$shard" ]]; then
  echo "run_shard.sh: full needs a shard number 1-${SHARD_COUNT}" >&2
  exit 1
fi
if ! rows="$(plan_flows "$tier" "$shard")"; then
  exit 1
fi

export EMULATOR_REUSE_INSTALL=1
artifacts="${EMULATOR_ARTIFACTS:-${ROOT}/emulator-app-test-artifacts}"
mkdir -p "$artifacts"
echo "Emulator ${tier}${shard:+ shard ${shard}}: $(printf '%s\n' "$rows" | wc -l) flows, cap ${FLOW_CAP_S}s each, worst case $(plan_need_s "$tier" "$shard")s"

# Outer guard: run_one_flow.sh enforces FLOW_BUDGET itself. This only stops
# a wrapper that wedges outside the flow (pm clear, logcat pull).
guard=$((FLOW_CAP_S + FLOW_KILL_AFTER_S + FLOW_RESET_S))
# The self-test swaps in a stub runner. CI always uses run_one_flow.sh.
runner="${EMULATOR_FLOW_RUNNER:-tool/emulator/run_one_flow.sh}"

# The plan rows are read on fd 3, and each flow runs with stdin from
# /dev/null. A flow's adb shell (or any command that reads stdin) would
# otherwise read the remaining rows, and only the first flow would run
# (PR #126 run 41306793034: shards 4, 5, 6 ran one flow each).
while read -r id script part <&3; do
  [[ -n "$id" ]] || continue
  if [[ "$part" == - ]]; then part=""; fi
  if [[ "${EMULATOR_SHARD_DRY_RUN:-}" == 1 ]]; then
    printf 'PLAN %s %s %s\n' "$id" "$script" "${part:--}"
    continue
  fi
  echo "::group::Flow ${id}"
  started=$SECONDS
  FILTER_MATRIX_PART="${part:-all}" timeout --kill-after=10 "$guard" \
    bash "$runner" "$id" "$script" </dev/null
  rc=$?
  if [[ "$rc" -eq 124 || "$rc" -eq 137 ]]; then
    printf 'FAIL %s: timeout: wrapper exceeded %ss\n' "$id" "$guard" >> "${artifacts}/results.txt"
  fi
  printf 'TIME %s %ss\n' "$id" "$((SECONDS - started))" >> "${artifacts}/results.txt"
  echo "::endgroup::"
done 3<<<"$rows"
exit 0
