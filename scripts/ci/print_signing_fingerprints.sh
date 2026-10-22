#!/usr/bin/env bash
# Print the signing certificate SHA-1 and SHA-256. Fingerprints only.
# Does not print passwords, aliases, or keystore bytes.
#
#   print_signing_fingerprints.sh <keystore> <password-env-name> <alias-env-name>
#   print_signing_fingerprints.sh --apk <apk>
#
# The password and alias arguments are environment variable names, not values.
# keytool reads the store password with -storepass:env so it stays off argv.

set -euo pipefail

extract_fingerprints() {
  local input="$1"
  python3 - "$input" <<'PY'
import re
import sys

with open(sys.argv[1], encoding="utf-8", errors="replace") as handle:
    text = handle.read()

def grab(pattern: str) -> str:
    match = re.search(pattern, text)
    return match.group(1).strip() if match else ""

sha1 = grab(r"SHA-?1(?: digest)?:\s*([0-9A-Fa-f:]+)")
sha256 = grab(r"SHA-?256(?: digest)?:\s*([0-9A-Fa-f:]+)")
if not sha1 or not sha256:
    sys.exit(1)
sys.stdout.write(f"signing SHA-1: {sha1}\nsigning SHA-256: {sha256}\n")
PY
}

if [[ "${1:-}" == "--apk" ]]; then
  apk="${2:-}"
  if [[ -z "$apk" || ! -f "$apk" ]]; then
    echo "error: APK not found for signing fingerprints" >&2
    exit 1
  fi
  tmp="$(mktemp)"
  chmod 600 "$tmp"
  cleanup() {
    rm -f -- "$tmp"
  }
  trap cleanup EXIT
  if ! keytool -printcert -jarfile "$apk" >"$tmp" 2>/dev/null; then
    if ! command -v apksigner >/dev/null 2>&1 || ! apksigner verify --print-certs "$apk" >"$tmp" 2>/dev/null; then
      echo "error: could not read signing fingerprints from the APK" >&2
      exit 1
    fi
  fi
  if ! extract_fingerprints "$tmp"; then
    echo "error: could not read signing fingerprints from the APK" >&2
    exit 1
  fi
  exit 0
fi

keystore="${1:-}"
password_env="${2:-}"
alias_env="${3:-}"
if [[ -z "$keystore" || ! -f "$keystore" ]]; then
  echo "error: keystore not found for signing fingerprints" >&2
  exit 1
fi
if [[ ! "$password_env" =~ ^[A-Z][A-Z0-9_]*$ ]]; then
  echo "error: password env name is invalid" >&2
  exit 1
fi
if [[ ! "$alias_env" =~ ^[A-Z][A-Z0-9_]*$ ]]; then
  echo "error: alias env name is invalid" >&2
  exit 1
fi
if [[ -z "${!password_env:-}" ]]; then
  echo "error: ${password_env} is unavailable" >&2
  exit 1
fi
if [[ -z "${!alias_env:-}" ]]; then
  echo "error: ${alias_env} is unavailable" >&2
  exit 1
fi
export "${password_env?}"

tmp="$(mktemp)"
chmod 600 "$tmp"
cleanup() {
  rm -f -- "$tmp"
}
trap cleanup EXIT
alias_value="${!alias_env}"
if ! keytool -list -v \
  -keystore "$keystore" \
  -storepass:env "$password_env" \
  -alias "$alias_value" >"$tmp" 2>/dev/null; then
  echo "error: could not read signing fingerprints" >&2
  exit 1
fi
if ! extract_fingerprints "$tmp"; then
  echo "error: could not read signing fingerprints" >&2
  exit 1
fi
