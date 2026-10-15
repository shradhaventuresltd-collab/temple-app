#!/usr/bin/env bash
# Decode DEMO_KEYSTORE_B64 to a temp PKCS12 file and write key.properties.
# Prints only the keystore path on stdout. Does not print secret values.
#
# The properties file defaults to android/key.properties (gitignored).
# Pass another path as $1 in tests. storeType is PKCS12.
# Java Properties.load reads ISO-8859-1, so values are written with
# \\ and \\uXXXX escapes. The Play upload key does not use this script.

set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
props="${1:-$root/android/key.properties}"

for name in DEMO_KEYSTORE_B64 DEMO_KEYSTORE_PASSWORD DEMO_KEY_ALIAS DEMO_KEY_PASSWORD; do
  if [[ -z "${!name:-}" ]]; then
    echo "error: $name is unavailable" >&2
    exit 1
  fi
done

umask 077
base="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
keystore="$(mktemp "$base/demo-keystore.XXXXXX.p12")"
tmp_props="$(mktemp "$base/key.properties.XXXXXX")"
wrote_props=false
success=false

cleanup() {
  local status=$?
  if [[ "$success" == true ]]; then
    rm -f -- "$tmp_props"
  else
    rm -f -- "$keystore" "$tmp_props"
    if [[ "$wrote_props" == true ]]; then
      rm -f -- "$props"
    fi
  fi
  exit "$status"
}
trap cleanup EXIT

printf '%s' "$DEMO_KEYSTORE_B64" | base64 --decode > "$keystore"
if [[ ! -s "$keystore" ]]; then
  echo "error: decoded keystore is empty" >&2
  exit 1
fi

# Java Properties.load reads ISO-8859-1. Write ASCII with \\ and \\uXXXX
# so a backslash, newline, or non-ASCII password round-trips. The python
# failure text does not include the secret values.
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
        f"storePassword={esc(os.environ['DEMO_KEYSTORE_PASSWORD'])}\n"
        f"keyPassword={esc(os.environ['DEMO_KEY_PASSWORD'])}\n"
        f"keyAlias={esc(os.environ['DEMO_KEY_ALIAS'])}\n"
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
wrote_props=true
chmod 600 "$props" "$keystore"

printf '%s\n' "$keystore"
success=true
