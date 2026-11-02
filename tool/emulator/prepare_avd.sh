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
#    Run phase: the emulator grows disk.dataPartition.size to the size of
#    the image's userdata (run 41373837994: config.ini said 2048M before the
#    create boot and 6442450944 after it; the snapshot's hardware.ini said
#    "disk.dataPartition.size = 6g"). Forcing 2048M back on the flow boot
#    made hardware-qemu.ini say 2g, and every shard logged "The emulator
#    hardware cannot load snapshot: default_boot" and cold-booted. When a
#    saved snapshot exists, the run phase pins disk size, cores and RAM to
#    the values in snapshots/default_boot/hardware.ini instead.
# 2. Copies config.ini and hardware-qemu.ini to $RUNNER_TEMP/avd-ini/<phase>
#    for the on-failure diagnostics artifact.
# 3. Clears stale QEMU locks and frees port 5554.
set -u

phase="${1:-run}"
avd_dir="${ANDROID_AVD_HOME:-${HOME}/.android/avd}/${EMULATOR_AVD_NAME:-emulator-app-test-30}.avd"
config="${avd_dir}/config.ini"

# hardware.ini size ("6g", "2048m", "512 MB", bytes) -> bytes.
ini_size_bytes() {
  python3 - "$1" <<'PY'
import re, sys
m = re.fullmatch(r"\s*([0-9]+)\s*([kmgt]?)b?\s*", sys.argv[1].lower())
if not m:
    sys.exit(1)
mult = {"": 1, "k": 1 << 10, "m": 1 << 20, "g": 1 << 30, "t": 1 << 40}[m.group(2)]
print(int(m.group(1)) * mult)
PY
}

# Pin EMULATOR_DISK_SIZE / EMULATOR_CORES / EMULATOR_RAM_MB to a snapshot's
# hardware.ini so the flow boot's hardware-qemu.ini matches it.
pin_to_snapshot() {
  local hw="$1" v
  [[ -f "$hw" ]] || return 1
  v="$(awk -F' *= *' '$1 == "disk.dataPartition.size" { print $2 }' "$hw")"
  if [[ -n "$v" ]] && v="$(ini_size_bytes "$v")"; then EMULATOR_DISK_SIZE="$v"; fi
  v="$(awk -F' *= *' '$1 == "hw.cpu.ncore" { print $2 }' "$hw")"
  [[ "$v" =~ ^[0-9]+$ ]] && EMULATOR_CORES="$v"
  v="$(awk -F' *= *' '$1 == "hw.ramSize" { print $2 }' "$hw")"
  [[ "$v" =~ ^[0-9]+$ ]] && EMULATOR_RAM_MB="$v"
  echo "prepare_avd (${phase}): pinned to snapshot hardware.ini: disk=${EMULATOR_DISK_SIZE:-} cores=${EMULATOR_CORES:-} ram=${EMULATOR_RAM_MB:-}"
  return 0
}

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

if [[ "$phase" == run ]]; then
  pin_to_snapshot "${avd_dir}/snapshots/default_boot/hardware.ini" || true
fi

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
