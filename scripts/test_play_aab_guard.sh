#!/usr/bin/env bash
# Proves scripts/build_play_aab.sh refuses admin/demo defines and a
# debug-signed bundle. Does not run flutter or produce a Play AAB.
# CI has no upload key; this is the KAN-86/KAN-89 check in analyze-test.

set -euo pipefail

cd "$(dirname "$0")/.."

unset ENABLE_ADMIN_TOOLS || true
unset DEMO_BUILD || true

expect_fail() {
  local desc="$1"
  local needle="$2"
  shift 2
  local out status
  set +e
  out="$(timeout 20 "$@" 2>&1)"
  status=$?
  set -e
  if [[ "$status" -eq 0 ]]; then
    echo "FAIL: $desc exited 0" >&2
    printf '%s\n' "$out" >&2
    exit 1
  fi
  if [[ "$status" -eq 124 ]]; then
    echo "FAIL: $desc timed out (guard did not refuse before a build)" >&2
    exit 1
  fi
  if ! grep -q "$needle" <<<"$out"; then
    echo "FAIL: $desc output did not contain: $needle" >&2
    printf '%s\n' "$out" >&2
    exit 1
  fi
  echo "ok: $desc"
}

expect_fail "dart-define equals form" \
  "ENABLE_ADMIN_TOOLS" \
  ./scripts/build_play_aab.sh --dart-define=ENABLE_ADMIN_TOOLS=true

expect_fail "dart-define space form" \
  "ENABLE_ADMIN_TOOLS" \
  ./scripts/build_play_aab.sh --dart-define ENABLE_ADMIN_TOOLS=true

expect_fail "ENABLE_ADMIN_TOOLS env" \
  "ENABLE_ADMIN_TOOLS" \
  env ENABLE_ADMIN_TOOLS=true ./scripts/build_play_aab.sh

defines_dir="$(mktemp -d)"
trap 'rm -rf "$defines_dir"' EXIT
printf '%s\n' '{"ENABLE_ADMIN_TOOLS": true}' >"$defines_dir/admin.json"

expect_fail "dart-define-from-file equals form" \
  "ENABLE_ADMIN_TOOLS" \
  ./scripts/build_play_aab.sh --dart-define-from-file="$defines_dir/admin.json"

expect_fail "dart-define-from-file space form" \
  "ENABLE_ADMIN_TOOLS" \
  ./scripts/build_play_aab.sh --dart-define-from-file "$defines_dir/admin.json"

expect_fail "DEMO_BUILD equals form" \
  "DEMO_BUILD" \
  ./scripts/build_play_aab.sh --dart-define=DEMO_BUILD=true

expect_fail "DEMO_BUILD space form" \
  "DEMO_BUILD" \
  ./scripts/build_play_aab.sh --dart-define DEMO_BUILD=true

expect_fail "DEMO_BUILD env" \
  "DEMO_BUILD" \
  env DEMO_BUILD=true ./scripts/build_play_aab.sh

printf '%s\n' 'DEMO_BUILD=true' >"$defines_dir/demo.env"
expect_fail "dart-define-from-file DEMO_BUILD" \
  "DEMO_BUILD" \
  ./scripts/build_play_aab.sh --dart-define-from-file="$defines_dir/demo.env"

printf '%s\n' 'not a bundle' >"$defines_dir/readme.txt"
(
  cd "$defines_dir"
  zip -q bundle.zip readme.txt
)

keytool -genkeypair \
  -keystore "$defines_dir/debug.jks" \
  -storepass secret \
  -keypass secret \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 1 \
  -dname "CN=Android Debug, OU=Android, O=Android, L=Unknown, ST=Unknown, C=US" \
  >/dev/null

keytool -genkeypair \
  -keystore "$defines_dir/upload.jks" \
  -storepass secret \
  -keypass secret \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 1 \
  -dname "CN=Temple Upload, OU=Release, O=Shradha Ventures, L=Bengaluru, ST=KA, C=IN" \
  >/dev/null

cp "$defines_dir/bundle.zip" "$defines_dir/debug-signed.aab"
jarsigner \
  -keystore "$defines_dir/debug.jks" \
  -storepass secret \
  -keypass secret \
  "$defines_dir/debug-signed.aab" \
  upload \
  >/dev/null

cp "$defines_dir/bundle.zip" "$defines_dir/upload-signed.aab"
jarsigner \
  -keystore "$defines_dir/upload.jks" \
  -storepass secret \
  -keypass secret \
  "$defines_dir/upload-signed.aab" \
  upload \
  >/dev/null

expect_fail "debug-signed bundle" \
  "CN=Android Debug" \
  ./scripts/build_play_aab.sh --verify-signing "$defines_dir/debug-signed.aab"

./scripts/build_play_aab.sh --verify-signing "$defines_dir/upload-signed.aab"
echo "ok: upload cert is not the Android debug cert"

expect_fail "unreadable signing cert" \
  "could not read a signing certificate" \
  ./scripts/build_play_aab.sh --verify-signing "$defines_dir/bundle.zip"

echo "Play AAB guard checks passed."
