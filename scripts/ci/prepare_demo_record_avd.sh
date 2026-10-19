#!/usr/bin/env bash
# Runs after avdmanager creates the demo AVD and before the emulator starts.
# Same KVM fail-fast wrapper and userdata shrink as android-smoke. This
# image is google_apis (it has a launcher) rather than google_atd, so the
# userdata path is not the google_atd one prepare_atd_avd.sh requires.
set -euo pipefail

avd_name="${1:-temple-demo-34-apis}"
sdk="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
if [[ -z "$sdk" ]]; then
  echo "ANDROID_SDK_ROOT is unset" >&2
  exit 1
fi

bin="${sdk}/emulator/emulator"
if [[ ! -e "${bin}.real" ]]; then
  mv "$bin" "${bin}.real"
fi
install -m 0755 "${GITHUB_WORKSPACE}/scripts/ci/emulator_fail_fast.sh" "$bin"

cfg="${HOME}/.android/avd/${avd_name}.avd/config.ini"
if [[ ! -f "$cfg" ]]; then
  echo "AVD config missing: $cfg" >&2
  exit 1
fi

# Pixel 6 is 1080x2400 at 420 dpi. Pin it in case the profile skin differs.
# screenrecord is asked for that same size.
python3 - "$cfg" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
wanted = {
    "hw.lcd.width": "1080",
    "hw.lcd.height": "2400",
    "hw.lcd.density": "420",
    "hw.initialOrientation": "portrait",
    "hw.keyboard": "yes",
    "hw.ramSize": "2048",
    "disk.dataPartition.size": "2048M",
}
lines = []
seen = set()
for raw in path.read_text().splitlines():
    key = raw.split("=", 1)[0].strip()
    if key in wanted:
        lines.append(f"{key}={wanted[key]}")
        seen.add(key)
    else:
        lines.append(raw)
for key, value in wanted.items():
    if key not in seen:
        lines.append(f"{key}={value}")
path.write_text("\n".join(lines) + "\n")
print("pinned LCD to 1080x2400 portrait")
PY
grep -E '^(hw\.lcd\.(width|height|density)|disk\.dataPartition\.size)=' "$cfg"

qcfg="${HOME}/.android/avd/${avd_name}.avd/hardware-qemu.ini"
if [[ -f "$qcfg" ]]; then
  grep -v '^disk.dataPartition.size' "$qcfg" > "${qcfg}.tmp"
  printf 'disk.dataPartition.size = 2048M\n' >> "${qcfg}.tmp"
  mv "${qcfg}.tmp" "$qcfg"
  echo "hardware-qemu.ini userdata partition set to 2048M"
fi

# google_apis ships a multi-gigabyte userdata.img. disk.dataPartition.size
# does not shrink that file, and qemu still tries to allocate it. Replace
# an oversized or truncated image with a 512M ext4 filesystem.
img="$(find "$sdk/system-images" -type f -path '*/google_apis/*/userdata.img' -print -quit)"
if [[ -z "$img" ]]; then
  img="$(find "$sdk/system-images" -type f -name 'userdata.img' -print -quit)"
fi
if [[ -z "$img" ]]; then
  echo "userdata.img not found under ${sdk}/system-images" >&2
  exit 1
fi
bytes="$(stat -c %s "$img")"
cap=$((2048 * 1024 * 1024))
min=$((32 * 1024 * 1024))
echo "userdata.img ${img} apparent bytes ${bytes}"
if (( bytes > cap || bytes < min )); then
  echo "replacing userdata.img (${bytes} bytes) with a 512M ext4 image"
  rm -f "$img"
  truncate -s 512M "$img"
  mkfs.ext4 -F -L data "$img"
  echo "userdata.img now $(stat -c %s "$img") bytes"
fi

echo "===== df before the demo emulator ====="
df -h /
