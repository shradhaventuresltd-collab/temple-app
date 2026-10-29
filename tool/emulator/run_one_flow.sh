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

# The GitHub step timeout kills this process, so the failure line below
# the flow never runs. timeout returns 124 to this parent instead.
# Boot is allowed EMULATOR_BOOT_TIMEOUT (600s) and happens before this
# script, inside the same job step. The flow budget stays 1140s. The step
# cap is 30 minutes: 600s boot + 1140s flow + 15s kill-after + about a
# minute to record FAIL. 30 flows cannot all spend 30 minutes inside the
# 180-minute job; that job limit stays the backstop for a streak of hangs.
FLOW_BUDGET=1140
if [[ "${EMULATOR_FLOW_TIMED:-}" != 1 ]]; then
  printf 'START %s\n' "$FLOW" >> "$RESULTS"
  set +e
  EMULATOR_FLOW_TIMED=1 timeout --kill-after=15 "$FLOW_BUDGET" bash "$0" "$@"
  flow_rc=$?
  if [[ "$flow_rc" -eq 124 || "$flow_rc" -eq 137 ]]; then
    # SIGKILL skips the inner EXIT trap. Record the log and put the network
    # back from this parent, which is the process timeout returns to.
    screenrecord_stop || true
    dump_logcat || true
    network_on || true
    record_fail "timeout" "flow exceeded ${FLOW_BUDGET}s"
  elif [[ "$flow_rc" -ne 0 ]]; then
    record_fail "script" "flow exited ${flow_rc}"
  else
    printf 'DONE %s\n' "$FLOW" >> "$RESULTS"
  fi
  exit 0
fi

# timeout just started this process. matrix_main runs later, after the APK
# install, so the 1140s budget is counted from here rather than from SECONDS
# at the first case.
export FLOW_START_EPOCH="$(date +%s)"

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

log_installed_version

# Keep the soft keyboard closed so `input text` is not rewritten by the IME.
adb_shell_capped 8 settings put secure show_ime_with_hard_keyboard 0 >/dev/null 2>&1 || true
adb_shell_capped 8 settings put secure spell_checker_enabled 0 >/dev/null 2>&1 || true

set +e
# shellcheck disable=SC1090
source "$EMULATOR_FLOW_SCRIPT"
flow_rc=$?

if [[ "$flow_rc" -ne 0 ]]; then
  record_fail "script" "flow exited ${flow_rc}"
fi

exit 0
