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
cd "$ROOT" || exit 1
# shellcheck disable=SC1091
source "${ROOT}/tool/emulator/lib/common.sh"
# shellcheck source=SCRIPTDIR/plan.sh
source "${ROOT}/tool/emulator/plan.sh"

# The GitHub step timeout kills this process, so the failure line below
# the flow never runs. timeout returns 124 to this parent instead.
# Each flow is capped at 600s (Confluence 12353537, option A). The
# emulator boots once per job before the first flow (run_shard.sh), so the
# cap covers the flow alone. The shard step timeout is sized in plan.sh
# from this cap, the kill-after, and the per-flow reset overhead.
FLOW_BUDGET=600
if [[ "${EMULATOR_FLOW_TIMED:-}" != 1 ]]; then
  if plan_is_skipped "$FLOW"; then
    printf 'SKIPPED %s: location-dependent, skipped on the emulator (EMULATOR_SKIP_FLOWS)\n' "$FLOW" >> "$RESULTS"
    echo "SKIPPED ${FLOW}"
    exit 0
  fi
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

# shellcheck disable=SC2329 # invoked by the EXIT trap
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

# run_shard.sh boots one emulator for many flows and sets
# EMULATOR_REUSE_INSTALL=1. The APK is installed by the first flow; later
# flows put the device back to defaults and clear app data (pm clear)
# instead of reinstalling. A standalone run still reinstalls.
if [[ "${EMULATOR_REUSE_INSTALL:-}" == 1 ]] && app_installed; then
  reset_device_state
  if ! clear_app_data; then
    exit 0
  fi
elif ! install_apk; then
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
