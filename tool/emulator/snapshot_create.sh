#!/usr/bin/env bash
# Script of the "Create AVD snapshot" step, on the booted, app-free AVD.
# Both boots use the same EMULATOR_OPTIONS (with -no-snapshot-save), so the
# snapshot is saved here through the console instead of on exit.
# Before saving it sets a RAM-only property; a boot that restores the
# snapshot still has it, a cold boot does not (run_shard.sh boot check).
set -uo pipefail

adb shell setprop debug.temple.snapshot_marker 1 || true
out="$(adb emu avd snapshot save default_boot 2>&1 | tr -d '\r')"
echo "snapshot save: ${out}"
if [[ "$out" != *OK* ]]; then
  echo "::warning::adb emu avd snapshot save default_boot did not report OK"
fi
avd_dir="${ANDROID_AVD_HOME:-${HOME}/.android/avd}/${EMULATOR_AVD_NAME:-emulator-app-test-30}.avd"
if [[ -n "${RUNNER_TEMP:-}" ]]; then
  dest="${RUNNER_TEMP}/avd-ini/create-booted"
  mkdir -p "$dest"
  cp -f "$avd_dir"/config.ini "$avd_dir"/hardware-qemu.ini "$dest"/ 2>/dev/null || true
  cp -f "$avd_dir"/snapshots/default_boot/hardware.ini "$dest"/snapshot-hardware.ini 2>/dev/null || true
fi
echo "Generated AVD snapshot for caching."
