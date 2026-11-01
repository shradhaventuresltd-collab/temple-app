#!/usr/bin/env bash
# Runs on the host before each emulator launch (snapshot creation and the
# flow run): prepare_avd.sh <create|run>.
#
# 1. Normalises the AVD's config.ini so both boots see the same file.
#    reactivecircus/android-emulator-runner (a421e43, createAvd) appends
#    "hw.cpu.ncore=<cores>" and "disk.dataPartition.size=<disk>" to
#    config.ini on EVERY launch, not only when it creates the AVD. Run
#    41314245431 logged that append in "Create AVD snapshot" and again in
#    "Run emulator flows", so the flow boot saw a config.ini with each key
#    twice, and every flow boot then said "cannot load snapshot ...
#    different AVD configuration". Here every key is kept once (last value
#    wins, first position kept), and the values the cache key is built from
#    are written explicitly, plus hw.ramSize=2048 (the emulator raised RAM
#    to 2048MB at runtime on both boots anyway).
# 2. Copies config.ini and hardware-qemu.ini to $RUNNER_TEMP/avd-ini/<phase>
#    for the on-failure diagnostics artifact.
# 3. Clears stale QEMU locks and frees port 5554.
set -u

phase="${1:-run}"
avd_dir="${ANDROID_AVD_HOME:-${HOME}/.android/avd}/${EMULATOR_AVD_NAME:-emulator-app-test-30}.avd"
config="${avd_dir}/config.ini"

normalize_config() {
  local file="$1" tmp
  tmp="$(mktemp)"
  awk -F= -v cores="${EMULATOR_CORES:-}" -v disk="${EMULATOR_DISK_SIZE:-}" -v ram="${EMULATOR_RAM_MB:-2048}" '
    BEGIN {
      if (cores != "") force["hw.cpu.ncore"] = cores
      if (disk != "") force["disk.dataPartition.size"] = disk
      if (ram != "") force["hw.ramSize"] = ram
    }
    /^[[:space:]]*$/ { next }
    {
      key = $1; sub(/[[:space:]]+$/, "", key)
      val = substr($0, index($0, "=") + 1); sub(/^[[:space:]]+/, "", val)
      if (!(key in seen)) { order[++n] = key; seen[key] = 1 }
      value[key] = val
    }
    END {
      for (k in force) { if (!(k in seen)) order[++n] = k; value[k] = force[k] }
      for (i = 1; i <= n; i++) print order[i] "=" value[order[i]]
    }' "$file" > "$tmp" && cat "$tmp" > "$file"
  rm -f "$tmp"
}

if [[ -f "$config" ]]; then
  normalize_config "$config"
  echo "prepare_avd (${phase}): config.ini sha256 $(sha256sum "$config" | cut -c1-16)"
  grep -E '^(hw\.cpu\.ncore|hw\.ramSize|disk\.dataPartition\.size)=' "$config" | sed 's/^/  /'
fi

if [[ -n "${RUNNER_TEMP:-}" && -d "$avd_dir" ]]; then
  dest="${RUNNER_TEMP}/avd-ini/${phase}-prelaunch"
  mkdir -p "$dest"
  cp -f "$avd_dir"/config.ini "$avd_dir"/hardware-qemu.ini "$dest"/ 2>/dev/null || true
fi

if [[ -d "${HOME}/.android/avd" ]]; then
  find "${HOME}/.android/avd" \( -name '*.lock' -o -name 'hardware-qemu.ini.lock' \) \
    -exec rm -rf {} + 2>/dev/null || true
fi

adb emu kill >/dev/null 2>&1 || true
pkill -9 -f 'qemu-system' >/dev/null 2>&1 || true
sleep 1
exit 0
