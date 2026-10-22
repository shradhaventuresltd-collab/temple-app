#!/usr/bin/env bash
# Delete the temp demo keystore and the generated key.properties.
# Refuses a keystore path outside the runner temp directory.
# $1 keystore path (optional). $2 properties path (optional).
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
keystore="${1:-}"
props="${2:-$root/android/key.properties}"

delete_keystore() {
  local path="$1"
  local allowed=false
  local dir
  case "$path" in
    *..*)
      echo "error: refusing to delete a keystore path outside the temp directory" >&2
      exit 1
      ;;
  esac
  for dir in "${RUNNER_TEMP:-}" "${TMPDIR:-}" /tmp; do
    dir="${dir%/}"
    if [[ -n "$dir" && "$path" == "$dir"/* ]]; then
      allowed=true
    fi
  done
  if [[ "$allowed" != true ]]; then
    echo "error: refusing to delete a keystore path outside the temp directory" >&2
    exit 1
  fi
  rm -f -- "$path"
}

if [[ -n "$keystore" ]]; then
  delete_keystore "$keystore"
fi
if [[ -n "${DEMO_KEYSTORE_PATH:-}" && "${DEMO_KEYSTORE_PATH}" != "$keystore" ]]; then
  delete_keystore "$DEMO_KEYSTORE_PATH"
fi
rm -f -- "$props"

# Backstop for a cancelled step. prepare and distribute create these names
# under RUNNER_TEMP. Only that directory is globbed.
if [[ -n "${RUNNER_TEMP:-}" && -d "${RUNNER_TEMP}" ]]; then
  runner_temp="${RUNNER_TEMP%/}"
  shopt -s nullglob
  runner_files=(
    "$runner_temp"/demo-keystore.*
    "$runner_temp"/ci-debug-keystore.*
    "$runner_temp"/firebase-app-distro-sa.*
    "$runner_temp"/demo-release-notes.*
    "$runner_temp"/key.properties.*
  )
  shopt -u nullglob
  if ((${#runner_files[@]})); then
    rm -f -- "${runner_files[@]}"
  fi
fi
