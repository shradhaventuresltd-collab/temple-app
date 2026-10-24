#!/usr/bin/env bash
# Runs on the host before each emulator launch. Clears stale QEMU locks
# left when a previous step's emulator was killed, then frees port 5554.
set -u

if [[ -d "${HOME}/.android/avd" ]]; then
  find "${HOME}/.android/avd" \( -name '*.lock' -o -name 'hardware-qemu.ini.lock' \) \
    -exec rm -rf {} + 2>/dev/null || true
fi

adb emu kill >/dev/null 2>&1 || true
pkill -9 -f 'qemu-system' >/dev/null 2>&1 || true
sleep 1
exit 0
