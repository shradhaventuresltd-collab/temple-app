#!/usr/bin/env bash
# Decode CI_DEBUG_KEYSTORE_BASE64 to a temp PKCS12 file.
# Prints only the keystore path on stdout. Does not print secret values.
#
# When none of the four CI_DEBUG_* variables are set, prints nothing and
# exits 0 so a local debug or profile build keeps the Android debug key.
# --require fails instead (release CI builds cannot use that debug key).
# --key-properties PATH writes storeFile, passwords, alias, and
# storeType=PKCS12 for the existing release signing config. The Play
# upload key does not use this script.
#
# Java Properties.load reads ISO-8859-1, so values are written with
# \\ and \\uXXXX escapes.

set -euo pipefail

require=false
props=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --require)
      require=true
      shift
      ;;
    --key-properties)
      if [[ $# -lt 2 || -z "${2:-}" ]]; then
        echo "error: --key-properties needs a path" >&2
        exit 1
      fi
      props="$2"
      shift 2
      ;;
    *)
      echo "error: unknown argument" >&2
      exit 1
      ;;
  esac
done

names=(
  CI_DEBUG_KEYSTORE_BASE64
  CI_DEBUG_KEYSTORE_PASSWORD
  CI_DEBUG_KEY_ALIAS
  CI_DEBUG_KEY_PASSWORD
)
missing=()
present=0
for name in "${names[@]}"; do
  if [[ -z "${!name:-}" ]]; then
    missing+=("$name")
  else
    present=$((present + 1))
  fi
done

if [[ "$present" -eq 0 && "$require" == false ]]; then
  echo "CI debug keystore secrets are absent. Using the default debug keystore." >&2
  exit 0
fi

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "error: CI debug signing needs ${names[*]}. Missing: ${missing[*]}. See docs/ci-signing.md." >&2
  if [[ "$require" == true ]]; then
    echo "error: this release build cannot fall back to the default debug keystore." >&2
  fi
  exit 1
fi

umask 077
base="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
base="${base%/}"
mkdir -p -- "$base"
keystore="$(mktemp "$base/ci-debug-keystore.XXXXXX.p12")"
tmp_props=""
wrote_props=false
success=false

cleanup() {
  local status=$?
  if [[ "$success" == true ]]; then
    if [[ -n "$tmp_props" ]]; then
      rm -f -- "$tmp_props"
    fi
  else
    rm -f -- "$keystore"
    if [[ -n "$tmp_props" ]]; then
      rm -f -- "$tmp_props"
    fi
    if [[ "$wrote_props" == true ]]; then
      rm -f -- "$props"
    fi
  fi
  exit "$status"
}
trap cleanup EXIT

if ! printf '%s' "$CI_DEBUG_KEYSTORE_BASE64" | base64 --decode > "$keystore" 2>/dev/null; then
  echo "error: could not decode the CI debug keystore" >&2
  exit 1
fi
if [[ ! -s "$keystore" ]]; then
  echo "error: decoded keystore is empty" >&2
  exit 1
fi
chmod 600 "$keystore"

if [[ -n "$props" ]]; then
  tmp_props="$(mktemp "$base/key.properties.XXXXXX")"
  # shellcheck disable=SC2016 # python reads the process environment
  python3 - "$tmp_props" "$keystore" <<'PY'
import os
import sys

props_path, store_file = sys.argv[1], sys.argv[2]

def esc(value: str) -> str:
    out = []
    for ch in value:
        code = ord(ch)
        if ch == "\\":
            out.append("\\\\")
        elif ch == "\n":
            out.append("\\n")
        elif ch == "\r":
            out.append("\\r")
        elif ch == "\t":
            out.append("\\t")
        elif code < 0x20 or code > 0x7E:
            out.append("\\u%04x" % code)
        else:
            out.append(ch)
    return "".join(out)

try:
    text = (
        f"storePassword={esc(os.environ['CI_DEBUG_KEYSTORE_PASSWORD'])}\n"
        f"keyPassword={esc(os.environ['CI_DEBUG_KEY_PASSWORD'])}\n"
        f"keyAlias={esc(os.environ['CI_DEBUG_KEY_ALIAS'])}\n"
        f"storeFile={esc(store_file)}\n"
        "storeType=PKCS12\n"
    )
    with open(props_path, "w", encoding="ascii", newline="\n") as handle:
        handle.write(text)
except Exception:
    sys.stderr.write("error: could not write key.properties\n")
    sys.exit(1)
PY
  mv "$tmp_props" "$props"
  tmp_props=""
  wrote_props=true
  chmod 600 "$props" "$keystore"
fi

printf '%s\n' "$keystore"
success=true
