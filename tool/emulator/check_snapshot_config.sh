#!/usr/bin/env bash
# Verifies, before a flow boot, that the boot will load the cached snapshot
# instead of cold-booting with "different AVD configuration".
#
#   check_snapshot_config.sh pre  [avd_dir]   before launch (prepare_avd.sh run,
#                                             and the warm-up job before saving)
#   check_snapshot_config.sh post [avd_dir]   after a boot: hardware-qemu.ini
#                                             against the snapshot's hardware.ini
#
# Run 41391038302 (shard 3, avdini3): the snapshot's hardware.ini said
# "disk.dataPartition.size = 6g", but every flow boot's hardware-qemu.ini
# said "2g", because "-partition-size 2048" in EMULATOR_OPTIONS overrides the
# pinned config.ini (6442450944) once userdata-qemu.img exists. So:
#   pre:  EMULATOR_OPTIONS must not carry -partition-size (or it must equal
#         the snapshot size), and config.ini's disk size, cores and RAM must
#         equal snapshots/default_boot/hardware.ini.
#   post: hardware-qemu.ini's disk size, cores, RAM, partition sizes and
#         disk.dataPartition.initPath must equal the snapshot's. run_shard.sh
#         fails the shard fast on a post mismatch (round 4.3.1).
# Prints "SNAPSHOT_CONFIG ok" or "SNAPSHOT_CONFIG mismatch: <keys>" and exits
# 0 or 1. A missing snapshot exits 2 (nothing to compare).
set -uo pipefail

mode="${1:-pre}"
avd_dir="${2:-${ANDROID_AVD_HOME:-${HOME}/.android/avd}/${EMULATOR_AVD_NAME:-emulator-app-test-30}.avd}"
snap="${EMULATOR_SNAPSHOT_HW:-${avd_dir}/snapshots/default_boot/hardware.ini}"

# "6g", "2048m", "66MB", "6442450944" -> bytes; anything else unchanged.
norm() {
  python3 - "$1" <<'PY'
import re, sys
v = sys.argv[1].strip()
m = re.fullmatch(r"([0-9]+)\s*([kmgt]?)b?", v.lower())
if not m:
    print(v)
else:
    print(int(m.group(1)) * {"": 1, "k": 1 << 10, "m": 1 << 20, "g": 1 << 30, "t": 1 << 40}[m.group(2)])
PY
}
ini_get() { # file key
  awk -v k="$2" '{ line = $0; i = index(line, "="); if (!i) next
    key = substr(line, 1, i - 1); gsub(/[[:space:]]/, "", key)
    val = substr(line, i + 1); sub(/^[[:space:]]+/, "", val); sub(/[[:space:]]+$/, "", val)
    if (key == k) v = val } END { print v }' "$1"
}

if [[ ! -s "$snap" ]]; then
  echo "SNAPSHOT_CONFIG none: no ${snap}"
  exit 2
fi
bad=""
snap_disk="$(norm "$(ini_get "$snap" disk.dataPartition.size)")"

case "$mode" in
  pre)
    opts=" ${EMULATOR_OPTIONS:-} "
    if [[ "$opts" =~ [[:space:]]-partition-size[[:space:]]+([0-9]+) ]]; then
      want_mb=$((snap_disk / 1048576))
      if [[ "${BASH_REMATCH[1]}" != "$want_mb" ]]; then
        bad+="EMULATOR_OPTIONS -partition-size ${BASH_REMATCH[1]} (snapshot ${want_mb}M) "
      fi
    fi
    cfg="${avd_dir}/config.ini"
    if [[ ! -s "$cfg" ]]; then
      bad+="config.ini missing "
    else
      for k in disk.dataPartition.size hw.cpu.ncore hw.ramSize; do
        a="$(norm "$(ini_get "$snap" "$k")")"; b="$(norm "$(ini_get "$cfg" "$k")")"
        [[ "$a" == "$b" ]] || bad+="${k} snapshot=${a} config.ini=${b} "
      done
    fi
    ;;
  post)
    hq="${avd_dir}/hardware-qemu.ini"
    [[ -s "${EMULATOR_RUN_HW:-$hq}" ]] && hq="${EMULATOR_RUN_HW:-$hq}"
    if [[ ! -s "$hq" ]]; then
      bad+="hardware-qemu.ini missing "
    else
      for k in disk.dataPartition.size hw.cpu.ncore hw.ramSize disk.systemPartition.size disk.vendorPartition.size disk.cachePartition.size; do
        a="$(norm "$(ini_get "$snap" "$k")")"; b="$(norm "$(ini_get "$hq" "$k")")"
        [[ "$a" == "$b" ]] || bad+="${k} snapshot=${a} boot=${b} "
      done
      # Round 4.3.1: the userdata image path is part of the snapshot's
      # config too (run 41391038302: the snapshot had it, the boot did not).
      a="$(ini_get "$snap" disk.dataPartition.initPath)"; b="$(ini_get "$hq" disk.dataPartition.initPath)"
      [[ "$a" == "$b" ]] || bad+="disk.dataPartition.initPath snapshot=${a:-<unset>} boot=${b:-<unset>} "
    fi
    ;;
  *)
    echo "usage: check_snapshot_config.sh pre|post [avd_dir]" >&2
    exit 64
    ;;
esac

if [[ -n "$bad" ]]; then
  echo "SNAPSHOT_CONFIG mismatch: ${bad% }"
  echo "::warning::AVD config differs from the cached snapshot (${mode}); the boot will cold-boot: ${bad% }"
  exit 1
fi
echo "SNAPSHOT_CONFIG ok (${mode}): disk=${snap_disk} cores=$(ini_get "$snap" hw.cpu.ncore) ram=$(ini_get "$snap" hw.ramSize)"
exit 0
