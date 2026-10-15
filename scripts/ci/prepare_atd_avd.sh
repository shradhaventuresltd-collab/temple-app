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
