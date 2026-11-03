#!/usr/bin/env bash
# Round 4.4.5/4.4.6 (Manu): install adb_shim in place of the real adb in a
# platform-tools dir (the action's own PATH entry, which wins over
# GITHUB_PATH): <dir>/adb -> <dir>/adb.real, shim -> <dir>/adb.
#
#   install.sh [--reinstall] <platform-tools dir>
#
# Every action call runs "sdkmanager --install platform-tools"
# (sdk-installer.ts:52) before its pre-emulator-launch-script, and an
# update puts a fresh real adb over the shim. prepare_avd.sh (the
# pre-launch script of every action call) therefore runs this again with
# --reinstall: a <dir>/adb that is not the shim is a new real adb and is
# moved over adb.real (never skipped because an old adb.real exists).
# mv, not cp: a running adb (the adb server is a fork of it) can be renamed,
# but writing onto it fails with "Text file busy" (ETXTBSY; self_test).
# It also resets the per-boot getprop budget (adb_shim/adb, plan.sh
# SHARD_GETPROP_BUDGET_S): a new boot id under $RUNNER_TEMP/adb_shim.
set -uo pipefail
reinstall=0
[[ "${1:-}" == --reinstall ]] && { reinstall=1; shift; }
dir="${1:?usage: install.sh [--reinstall] <platform-tools dir>}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -e "$dir/adb" ]] && ! cmp -s "$here/adb" "$dir/adb"; then
  # A real adb (first install, or sdkmanager just replaced the shim).
  (( reinstall )) && echo "::warning::adb_shim: $dir/adb was replaced (platform-tools reinstalled); moving the new adb over adb.real"
  mv -f "$dir/adb" "$dir/adb.real" || { echo "::warning::adb_shim: could not move $dir/adb to adb.real" >&2; exit 1; }
fi
if [[ ! -x "$dir/adb.real" ]]; then
  echo "::warning::adb_shim: no real adb ($dir/adb.real missing); the action's adb calls are not capped"
  exit 1
fi
if ! cmp -s "$here/adb" "$dir/adb"; then
  cp "$here/adb" "$dir/adb.new.$$" && chmod +x "$dir/adb.new.$$" && mv -f "$dir/adb.new.$$" "$dir/adb" ||
    { echo "::warning::adb_shim: could not install the shim as $dir/adb" >&2; exit 1; }
fi
state="${ADB_SHIM_STATE_DIR:-${RUNNER_TEMP:-/tmp}/adb_shim}"
mkdir -p "$state" && date +%s%N > "$state/boot_id" && rm -f "$state"/getprop.*
echo "adb_shim: $dir/adb is the shim, real adb is $dir/adb.real (boot id $(cat "$state/boot_id" 2>/dev/null))"
