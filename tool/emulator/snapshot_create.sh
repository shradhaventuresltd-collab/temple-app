#!/usr/bin/env bash
# Script of the "Create AVD snapshot" step, on the booted, app-free AVD.
# Both boots use the same EMULATOR_OPTIONS (with -no-snapshot-save), so the
# snapshot is saved here through the console instead of on exit.
# Before saving it sets a RAM-only property; a boot that restores the
# snapshot still has it, a cold boot does not (run_shard.sh boot check).
set -uo pipefail

# Round 4.4: save only a settled system. Wait (EMULATOR_SNAPSHOT_READY_S,
# default 60s since 4.4.4) for input/settings/package/activity, pm and boot_completed,
# then settle EMULATOR_SNAPSHOT_SETTLE_S (10s). Never ready: no save, the
# step fails, and Save AVD cache does not run (run 41461260068: saved 6.4s
# after boot, 5/14 shards then lacked the input/settings services).
# Round 4.4.4 (Satyavrat): the wait is 60s by default (the warm-up); a
# shard's own fallback snapshot passes 20s and settles 5s (workflow).
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=SCRIPTDIR/plan.sh
source "${here}/plan.sh"
if ! bash "${here}/services_ready.sh" "${EMULATOR_SNAPSHOT_READY_S:-60}"; then
  echo "::error::system services not ready; not saving a snapshot (the AVD is not cached)"
  exit 1
fi
# Animations off in the saved snapshot (one capped call; the action's
# disable-animations is off since 4.4.4). Not fatal: run_shard.sh repeats it.
timeout "${SHARD_ANIM_S:-5}" adb shell "$ANIM_OFF_CMD" </dev/null >/dev/null 2>&1 || echo "::warning::could not turn animations off before the snapshot"
sleep "${EMULATOR_SNAPSHOT_SETTLE_S:-10}"

# debug.* properties are writable by the adb shell user (uid shell) on
# google_apis images without root: property_contexts maps debug.* to
# debug_prop, which the shell domain may set. setprop keeps the value in
# memory only (no persist. prefix), so it survives a snapshot restore and
# is gone after a cold boot.
if ! adb shell setprop debug.temple.snapshot_marker 1; then
  echo "::error::could not set the boot marker property; not saving a snapshot"
  exit 1
fi
out="$(adb emu avd snapshot save default_boot 2>&1 | tr -d '\r')"
echo "snapshot save: ${out}"
# A failed save must fail the step: Save AVD cache runs only when this
# step succeeded, so a bad snapshot is never cached under the cfg5 key.
if [[ "$out" != *OK* ]]; then
  echo "::error::adb emu avd snapshot save default_boot did not report OK; failing so the AVD is not cached"
  exit 1
fi
avd_dir="${ANDROID_AVD_HOME:-${HOME}/.android/avd}/${EMULATOR_AVD_NAME:-emulator-app-test-30}.avd"
if [[ -n "${RUNNER_TEMP:-}" ]]; then
  dest="${RUNNER_TEMP}/avd-ini/create-booted"
  mkdir -p "$dest"
  cp -f "$avd_dir"/config.ini "$avd_dir"/hardware-qemu.ini "$dest"/ 2>/dev/null || true
  cp -f "$avd_dir"/snapshots/default_boot/hardware.ini "$dest"/snapshot-hardware.ini 2>/dev/null || true
fi
echo "Generated AVD snapshot for caching."
