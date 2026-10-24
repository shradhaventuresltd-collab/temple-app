#!/usr/bin/env bash
# Boot-time wrapper for one emulator-app-test flow.
# Usage: run_one_flow.sh <flow-id> <flow-script>
set -uo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: run_one_flow.sh <flow-id> <flow-script>" >&2
  exit 1
fi

export EMULATOR_FLOW="$1"
export EMULATOR_FLOW_SCRIPT="$2"
export EMULATOR_FLOW_SOURCED=1

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
# shellcheck disable=SC1091
source "${ROOT}/tool/emulator/lib/common.sh"

cleanup() {
  screenrecord_stop || true
  dump_logcat || true
  network_on || true
}
trap cleanup EXIT

if ! resolve_package; then
  exit 0
fi

screenrecord_start

if ! install_apk; then
  exit 0
fi

# Keep the soft keyboard closed so `input text` is not rewritten by the IME.
adb shell settings put secure show_ime_with_hard_keyboard 0 >/dev/null 2>&1 || true
adb shell settings put secure spell_checker_enabled 0 >/dev/null 2>&1 || true

set +e
# shellcheck disable=SC1090
source "$EMULATOR_FLOW_SCRIPT"
flow_rc=$?
set -e

if [[ "$flow_rc" -ne 0 ]]; then
  record_fail "script" "flow exited ${flow_rc}"
fi

exit 0
