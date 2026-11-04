#!/usr/bin/env bash
# Pick the emulator tier for this workflow event and write tier= and
# matrix= to GITHUB_OUTPUT.
#   pull_request        smoke (6 flows, one job)
#   release published   full (15 shards); covers pre-releases
#   workflow_dispatch   the tier input, default full; release_gate=true
#                       forces full (smoke, apk_url or artifact_run_id with
#                       release_gate is an error)
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
event="${GITHUB_EVENT_NAME:-}"
input="${INPUT_TIER:-}"

case "$event" in
  pull_request) tier=smoke ;;
  release) tier=full ;;
  workflow_dispatch)
    tier="${input:-full}"
    if [[ "${INPUT_RELEASE_GATE:-false}" == true ]]; then
      if [[ "$tier" != full ]]; then
        echo "choose_tier.sh: release_gate runs the full tier, not '${tier}'" >&2
        exit 1
      fi
      # Fail fast: the gate must test the APK built from the ref's SHA.
      if [[ -n "${INPUT_APK_URL:-}" || -n "${INPUT_ARTIFACT_RUN_ID:-}" ]]; then
        echo "choose_tier.sh: release_gate builds from the ref; drop apk_url / artifact_run_id" >&2
        exit 1
      fi
    fi
    ;;
  *)
    echo "choose_tier.sh: unexpected event '${event}'" >&2
    exit 1
    ;;
esac
if [[ "$tier" != smoke && "$tier" != full ]]; then
  echo "choose_tier.sh: tier must be smoke or full, got '${tier}'" >&2
  exit 1
fi

matrix="$(bash "${root}/tool/emulator/plan.sh" matrix "$tier")"
echo "Emulator tier ${tier}, matrix ${matrix}"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  printf 'tier=%s\nmatrix=%s\n' "$tier" "$matrix" >> "$GITHUB_OUTPUT"
fi
