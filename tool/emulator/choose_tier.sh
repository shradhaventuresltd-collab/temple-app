#!/usr/bin/env bash
# Pick the emulator tier for this workflow event and write tier= and
# matrix= to GITHUB_OUTPUT.
#   pull_request        smoke (6 flows, one job)
#   push to main        full (6 shards)
#   schedule (nightly)  full
#   release prereleased full
#   workflow_dispatch   the tier input, default full
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
event="${GITHUB_EVENT_NAME:-}"
input="${INPUT_TIER:-}"

case "$event" in
  pull_request) tier=smoke ;;
  push | schedule | release) tier=full ;;
  workflow_dispatch)
    tier="${input:-full}"
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
