#!/usr/bin/env bash
# Delete the temp CI debug keystore recorded for this job.
# Reads $RUNNER_TEMP/ci-debug-signing.path when no keystore path is given.
# Also deletes android/key.properties unless --keep-properties is set.
# Does not print passwords or keystore bytes.
#
#   cleanup_ci_debug_signing.sh [--keep-properties] [keystore-path]
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
keep_props=false
keystore=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep-properties)
      keep_props=true
      shift
      ;;
    *)
      if [[ -n "$keystore" ]]; then
        echo "error: unexpected argument" >&2
        exit 1
      fi
      keystore="$1"
      shift
      ;;
  esac
done

path_file=""
if [[ -n "${RUNNER_TEMP:-}" ]]; then
  path_file="${RUNNER_TEMP%/}/ci-debug-signing.path"
fi
if [[ -z "$keystore" && -n "$path_file" && -f "$path_file" ]]; then
  keystore="$(<"$path_file")"
fi

if [[ "$keep_props" == true ]]; then
  props="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
  props="${props%/}/ci-debug-unused.properties"
  bash "$root/scripts/ci/cleanup_demo_signing.sh" "$keystore" "$props"
else
  bash "$root/scripts/ci/cleanup_demo_signing.sh" "$keystore"
fi
if [[ -n "$path_file" ]]; then
  rm -f -- "$path_file"
fi
