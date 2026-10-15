#!/usr/bin/env bash
# Installed over $ANDROID_SDK_ROOT/emulator/emulator.
# The emulator action backgrounds this file and then polls adb until
# emulator-boot-timeout. If qemu exits first (for example it cannot
# create the userdata image), stop that action instead of waiting.
set -u

here="$(cd "$(dirname "$0")" && pwd)"
real="${here}/emulator.real"
if [[ ! -x "$real" ]]; then
  echo "missing ${real}; cannot launch the emulator" >&2
  exit 1
fi

port=""
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
  if [[ "${args[$i]}" == "-port" && $((i + 1)) -lt ${#args[@]} ]]; then
    port="${args[$((i + 1))]}"
  fi
done

sdk="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
adb_bin="${sdk}/platform-tools/adb"
if [[ ! -x "$adb_bin" ]]; then
  adb_bin="adb"
fi

# A new session so this wrapper can exit after boot without SIGHUP'ing qemu.
setsid "$real" "$@" &
child=$!

fail_fast() {
  local status="$1"
  echo "Emulator process exited before boot (status ${status}). Failing the job." >&2
  pkill -f 'reactivecircus/android-emulator-runner/.*/lib/main.js' || true
  exit 1
}

# The action polls for up to 10 minutes. Leave as soon as qemu dies,
# or as soon as the guest reports boot, so a dead process does not sit
# out the boot timeout.
for _ in $(seq 1 300); do
  if ! kill -0 "$child" 2>/dev/null; then
    status=0
    wait "$child" || status=$?
    # qemu exits 0 when the action runs `adb emu kill` after a snapshot.
    # A non-zero exit before boot is the failure we must surface.
    if [[ "$status" -eq 0 ]]; then
      exit 0
    fi
    fail_fast "$status"
  fi
  if [[ -n "$port" ]]; then
    boot="$("$adb_bin" -s "emulator-${port}" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)"
    if [[ "$boot" == "1" ]]; then
      exit 0
    fi
  fi
  sleep 2
done

exit 0
