#!/usr/bin/env bash
# Builds the AVD cache key from everything that shapes the AVD config, so a
# cached snapshot is only restored onto the config it was saved with.
#
#   avd_cache_key.sh          choose cores, install the system image the
#                             emulator steps will use, write EMULATOR_CORES,
#                             EMULATOR_SYSIMG_REVISION, EMULATOR_AVD_CACHE_KEY
#                             to $GITHUB_ENV.
#   avd_cache_key.sh --check  after the snapshot boot: write same=true to
#                             $GITHUB_OUTPUT only if the installed system
#                             image still has the revision in the key.
#
# The emulator runner action runs `sdkmanager --install <image> --channel=0`
# on every launch, which moves to the newest image revision. Running the
# same install here first means the action's install is a no-op and the
# revision read below is the one that boots. sdkmanager cannot pin an
# older revision, so the revision goes into the key instead.
set -uo pipefail

: "${EMULATOR_API_LEVEL:?}" "${EMULATOR_TARGET:?}" "${EMULATOR_ARCH:?}"
: "${EMULATOR_DISK_SIZE:?}" "${EMULATOR_BUILD:?}" "${EMULATOR_AVD_NAME:?}"
# Same SDK and sdkmanager as the runner action (a421e43: ANDROID_HOME).
sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-/usr/local/lib/android/sdk}}"
sdkmanager="${EMULATOR_SDKMANAGER:-${sdk}/cmdline-tools/latest/bin/sdkmanager}"
package="system-images;android-${EMULATOR_API_LEVEL};${EMULATOR_TARGET};${EMULATOR_ARCH}"
props="${sdk}/system-images/android-${EMULATOR_API_LEVEL}/${EMULATOR_TARGET}/${EMULATOR_ARCH}/source.properties"
out_env="${GITHUB_ENV:-/dev/stdout}"
out_put="${GITHUB_OUTPUT:-/dev/stdout}"

image_revision() {
  [[ -f "$props" ]] || return 1
  sed -n 's/^Pkg\.Revision=\([0-9][0-9.]*\)[[:space:]]*$/\1/p' "$props" | head -n 1 | grep .
}

if [[ "${1:-}" == "--check" ]]; then
  now="$(image_revision || echo missing)"
  if [[ "$now" == "${EMULATOR_SYSIMG_REVISION:-}" ]]; then
    echo "system image ${package} revision ${now} matches the AVD cache key"
    echo "same=true" >> "$out_put"
  else
    echo "::warning::system image ${package} is revision ${now}, the AVD cache key has ${EMULATOR_SYSIMG_REVISION:-none}; not saving the AVD cache"
    echo "same=false" >> "$out_put"
  fi
  exit 0
fi

if [[ "${EMULATOR_NPROC:-$(nproc)}" -ge 4 ]]; then cores=4; else cores=2; fi

if [[ -x "$sdkmanager" ]]; then
  # `yes` is not piped: under pipefail its SIGPIPE would fail the step.
  "$sdkmanager" --licenses > /dev/null < <(yes 2>/dev/null) || true
  "$sdkmanager" --install "$package" --channel=0 > /dev/null < <(yes 2>/dev/null) ||
    echo "::warning::sdkmanager --install ${package} failed; reading what is installed"
else
  echo "::warning::no sdkmanager at ${sdkmanager}"
fi

if rev="$(image_revision)"; then
  image="img${rev}"
else
  # Unknown revision: a key no other run shares, so a snapshot saved from a
  # different image can never be restored. This run still boots its own.
  rev="unknown"
  image="imgunknown-${GITHUB_RUN_ID:-local}-${GITHUB_RUN_ATTEMPT:-0}"
  echo "::warning::no Pkg.Revision in ${props}; using a one-run AVD cache key"
fi

# Round 4.4.9b (architect): the snapshot is CPU-specific (cpu_id.sh; run
# 41757362316 SIGILL on 6 of 15 shards). cfg5 -> cfg6-<cpu hash>. The
# restore steps have no restore-keys, so another CPU's snapshot is never
# restored. Unreadable cpuinfo: a one-run key, like an unknown image.
if cpu="$(bash "$(dirname "${BASH_SOURCE[0]}")/cpu_id.sh")"; then
  echo "host CPU: $(bash "$(dirname "${BASH_SOURCE[0]}")/cpu_id.sh" --describe)"
else
  cpu="cpuunknown-${GITHUB_RUN_ID:-local}-${GITHUB_RUN_ATTEMPT:-0}-${GITHUB_JOB:-job}-${RANDOM}"
  echo "::warning::could not read the host CPU (model name/flags); using a one-run AVD cache key"
fi
key="avd-${EMULATOR_API_LEVEL}-${EMULATOR_TARGET}-${EMULATOR_ARCH}-${image}-cores${cores}-disk${EMULATOR_DISK_SIZE}-emu${EMULATOR_BUILD}-${EMULATOR_AVD_NAME}-clean-cfg6-${cpu}"
{
  echo "EMULATOR_CORES=${cores}"
  echo "EMULATOR_SYSIMG_REVISION=${rev}"
  echo "EMULATOR_AVD_CACHE_KEY=${key}"
  echo "EMULATOR_CPU_ID=${cpu}"
} >> "$out_env"
echo "AVD cache key: ${key}"
