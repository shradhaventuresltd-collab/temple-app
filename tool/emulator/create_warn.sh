#!/usr/bin/env bash
# Round 4.4.5 (Satyavrat): the shard's own "Create AVD snapshot" step
# (50s boot, 90s deadline) is continue-on-error; when it fails or times out
# this says so and exits 0, so the shard is never failed by it and its
# flows still run (cold boot, retry boot wait).
# Round 4.4.6 (Manu nit 1): it also stops what the failed create left
# running, bounded (5s, plan.sh E2E_WARN_S 6), and drops the AVD locks, so
# the flows boot does not collide with it and burn its one retry.
# Usage: create_warn.sh <create step outcome>
outcome="${1:-}"
shard="${EMULATOR_SHARD:-smoke}"
boot="${EMULATOR_SHARD_CREATE_BOOT_TIMEOUT:-50}"
if [[ "$outcome" == failure || "$outcome" == cancelled ]]; then
  echo "::warning::shard ${shard}: snapshot create boot exceeded ${boot} s or the create step failed (${outcome}); flows will cold-boot"
  timeout --kill-after=1 4 adb emu kill </dev/null >/dev/null 2>&1 || pkill -f qemu-system >/dev/null 2>&1 || true
  rm -f "${HOME}"/.android/avd/*.avd/*.lock 2>/dev/null || true
fi
exit 0
