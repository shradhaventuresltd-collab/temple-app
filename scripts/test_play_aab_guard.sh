#!/usr/bin/env bash
# Proves scripts/build_play_aab.sh refuses admin/demo defines and a
# debug-signed bundle. Does not run flutter or produce a Play AAB.
# CI has no upload key; this is the KAN-86/KAN-89 check in analyze-test.

set -euo pipefail

cd "$(dirname "$0")/.."

unset ENABLE_ADMIN_TOOLS || true
unset DEMO_BUILD || true
unset DEMO_APP_ID_SUFFIX || true
unset ORG_GRADLE_PROJECT_demo_suffix || true
unset SMOKE_GATE_OVERRIDE || true

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
trap 'rm -rf "$defines_dir" "${isolated_home:-}" scripts/ci/SMOKE_GATE_DIRTY_TEST' EXIT
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

expect_fail "DEMO_APP_ID_SUFFIX equals form" \
  "DEMO_APP_ID_SUFFIX" \
  ./scripts/build_play_aab.sh --dart-define=DEMO_APP_ID_SUFFIX=true

expect_fail "DEMO_APP_ID_SUFFIX space form" \
  "DEMO_APP_ID_SUFFIX" \
  ./scripts/build_play_aab.sh --dart-define DEMO_APP_ID_SUFFIX=true

expect_fail "DEMO_APP_ID_SUFFIX env" \
  "DEMO_APP_ID_SUFFIX" \
  env DEMO_APP_ID_SUFFIX=true ./scripts/build_play_aab.sh

expect_fail "ORG_GRADLE_PROJECT_demo_suffix env" \
  "demo_suffix" \
  env ORG_GRADLE_PROJECT_demo_suffix=true ./scripts/build_play_aab.sh

expect_fail "gradle -Pdemo_suffix" \
  "demo_suffix" \
  ./scripts/build_play_aab.sh -Pdemo_suffix=true

expect_fail "ORG_GRADLE_PROJECT_ciTesterChecks env" \
  "integration_test" \
  env ORG_GRADLE_PROJECT_ciTesterChecks=true ./scripts/build_play_aab.sh

expect_fail "gradle -PciTesterChecks" \
  "integration_test" \
  ./scripts/build_play_aab.sh -PciTesterChecks=true

printf '%s\n' 'DEMO_APP_ID_SUFFIX=true' >"$defines_dir/suffix.env"
expect_fail "dart-define-from-file DEMO_APP_ID_SUFFIX" \
  "DEMO_APP_ID_SUFFIX" \
  ./scripts/build_play_aab.sh --dart-define-from-file="$defines_dir/suffix.env"

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

isolated_home="$(mktemp -d)"
expect_fail "smoke gate without a token" \
  "android-smoke gate" \
  env -u GH_TOKEN -u GITHUB_TOKEN -u SMOKE_GATE_OVERRIDE \
    HOME="$isolated_home" \
    GH_CONFIG_DIR="$isolated_home" \
    XDG_CONFIG_HOME="$isolated_home" \
    ./scripts/build_play_aab.sh

override_status=0
override_out="$(env -u GH_TOKEN -u GITHUB_TOKEN \
  HOME="$isolated_home" \
  GH_CONFIG_DIR="$isolated_home" \
  SMOKE_GATE_OVERRIDE=1 \
  ./scripts/check_android_smoke_gate.sh 2>&1)" || override_status=$?
if [[ "$override_status" -ne 0 ]]; then
  echo "FAIL: SMOKE_GATE_OVERRIDE=1 exited ${override_status}" >&2
  printf '%s\n' "$override_out" >&2
  exit 1
fi
if ! grep -q 'SMOKE_GATE_OVERRIDE=1 is set' <<<"$override_out"; then
  echo "FAIL: SMOKE_GATE_OVERRIDE=1 did not print the loud warning" >&2
  printf '%s\n' "$override_out" >&2
  exit 1
fi
echo "ok: SMOKE_GATE_OVERRIDE=1 bypasses the smoke gate loudly"

expect_not_bypass() {
  local desc="$1"
  local value="$2"
  local out status
  set +e
  out="$(env -u GH_TOKEN -u GITHUB_TOKEN \
    HOME="$isolated_home" \
    GH_CONFIG_DIR="$isolated_home" \
    XDG_CONFIG_HOME="$isolated_home" \
    SMOKE_GATE_OVERRIDE="$value" \
    ./scripts/check_android_smoke_gate.sh 2>&1)"
  status=$?
  set -e
  if [[ "$status" -eq 0 ]]; then
    echo "FAIL: $desc exited 0" >&2
    printf '%s\n' "$out" >&2
    exit 1
  fi
  if grep -q 'SMOKE_GATE_OVERRIDE=1 is set' <<<"$out"; then
    echo "FAIL: $desc printed the override bypass" >&2
    printf '%s\n' "$out" >&2
    exit 1
  fi
  if ! grep -q 'android-smoke gate' <<<"$out"; then
    echo "FAIL: $desc output did not contain: android-smoke gate" >&2
    printf '%s\n' "$out" >&2
    exit 1
  fi
  echo "ok: $desc"
}

expect_not_bypass "empty SMOKE_GATE_OVERRIDE is not a bypass" ""
expect_not_bypass "SMOKE_GATE_OVERRIDE=0 is not a bypass" "0"
expect_not_bypass "SMOKE_GATE_OVERRIDE=yes is not a bypass" "yes"

printf 'dirty\n' > scripts/ci/SMOKE_GATE_DIRTY_TEST
expect_fail "dirty tree is refused" \
  "working tree is dirty" \
  env -u GH_TOKEN -u GITHUB_TOKEN \
    HOME="$isolated_home" \
    GH_CONFIG_DIR="$isolated_home" \
    SMOKE_GATE_OVERRIDE=1 \
    ./scripts/check_android_smoke_gate.sh
rm -f scripts/ci/SMOKE_GATE_DIRTY_TEST
echo "ok: dirty tree removed"

printf '%s\n' 'plain bundle' >"$defines_dir/clean.txt"
(
  cd "$defines_dir"
  rm -f clean.aab plugin.aab
  zip -q clean.aab clean.txt
)
printf '%s\n' 'Ldev/flutter/plugins/integration_test/IntegrationTestPlugin;' >"$defines_dir/classes.dex.txt"
(
  cd "$defines_dir"
  zip -q plugin.aab classes.dex.txt
)
./scripts/build_play_aab.sh --verify-no-integration-test "$defines_dir/clean.aab"
echo "ok: bundle without integration_test plugin class"
expect_fail "bundle contains integration_test plugin class" \
  "integration_test" \
  ./scripts/build_play_aab.sh --verify-no-integration-test "$defines_dir/plugin.aab"

echo "Play AAB guard checks passed."
