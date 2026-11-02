#!/usr/bin/env bash
# Round 4.4.5 (Manu): install adb_shim in place of the real adb in a
# platform-tools dir (the action's own PATH entry, which wins over
# GITHUB_PATH): <dir>/adb -> <dir>/adb.real, shim -> <dir>/adb.
# Idempotent: a dir that already holds adb.real keeps it.
set -euo pipefail
dir="${1:?usage: install.sh <platform-tools dir>}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -x "$dir/adb.real" ]] || { [[ -x "$dir/adb" ]] || { echo "adb_shim: no adb in $dir" >&2; exit 1; }; mv "$dir/adb" "$dir/adb.real"; }
cp "$here/adb" "$dir/adb"
chmod +x "$dir/adb"
echo "adb_shim: $dir/adb is the shim, real adb is $dir/adb.real"
