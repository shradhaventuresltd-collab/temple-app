#!/usr/bin/env bash
# Round 4.4.5 (Satyavrat): the shard's own "Create AVD snapshot" step
# (60s boot, 2 min cap) is continue-on-error; when it fails or times out
# this says so and exits 0, so the shard is never failed by it and its
# flows still run (cold boot, retry boot wait).
# Usage: create_warn.sh <create step outcome>
outcome="${1:-}"
shard="${EMULATOR_SHARD:-smoke}"
boot="${EMULATOR_SHARD_CREATE_BOOT_TIMEOUT:-60}"
if [[ "$outcome" == failure || "$outcome" == cancelled ]]; then
  echo "::warning::shard ${shard}: snapshot create boot exceeded ${boot} s or the create step failed (${outcome}); flows will cold-boot"
fi
exit 0
