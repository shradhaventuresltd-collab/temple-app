#!/usr/bin/env bash
# Runs after avdmanager creates the AVD and before the emulator starts.
# Pixel 6's default userdata image is about 7GB. The hosted runner does
# not have that free after the APK build, so the only userdata size is 2048M.
# Also install the fail-fast emulator wrapper for this step.
set -euo pipefail

avd_name="${1:-temple-smoke-34-atd}"
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
grep -v '^disk.dataPartition.size=' "$cfg" > "${cfg}.tmp"
printf 'disk.dataPartition.size=2048M\n' >> "${cfg}.tmp"
mv "${cfg}.tmp" "$cfg"
echo "userdata partition set to 2048M"
grep '^disk.dataPartition.size=' "$cfg"

# The emulator reads hardware-qemu.ini when avdmanager already wrote it.
# A smaller config.ini line does not override that file.
qcfg="${HOME}/.android/avd/${avd_name}.avd/hardware-qemu.ini"
if [[ -f "$qcfg" ]]; then
  grep -v '^disk.dataPartition.size' "$qcfg" > "${qcfg}.tmp"
  printf 'disk.dataPartition.size = 2048M\n' >> "${qcfg}.tmp"
  mv "${qcfg}.tmp" "$qcfg"
  echo "hardware-qemu.ini userdata partition set to 2048M"
fi

# google_atd ships userdata.img at about 7372.80 MB. disk.dataPartition.size
# does not shrink that image, and qemu still tries to allocate it. Replace an
# oversized image with a 512M ext4 filesystem. -partition-size 2048 can then
# grow the AVD copy, which fits in the space left after the APK build.
img="$(find "$sdk/system-images" -type f -path '*/google_atd/*/userdata.img' -print -quit)"
if [[ -z "$img" ]]; then
  echo "google_atd userdata.img not found under ${sdk}/system-images" >&2
  exit 1
fi
bytes="$(stat -c %s "$img")"
cap=$((2048 * 1024 * 1024))
echo "userdata.img ${img} apparent bytes ${bytes}"
if (( bytes > cap )); then
  echo "replacing oversized userdata.img with a 512M ext4 image"
  rm -f "$img"
  truncate -s 512M "$img"
  mkfs.ext4 -F -L data "$img"
  echo "userdata.img now $(stat -c %s "$img") bytes"
fi
