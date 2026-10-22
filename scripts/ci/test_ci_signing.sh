#!/usr/bin/env bash
# Guards for the fixed CI debug keystore.
# Does not run flutter or Gradle, does not call GitHub, and does not print secrets.
set -euo pipefail

cd "$(dirname "$0")/../.."

expect_eq() {
  local desc="$1" got="$2" want="$3"
  if [[ "$got" != "$want" ]]; then
    echo "FAIL: ${desc}: got '${got}', want '${want}'" >&2
    exit 1
  fi
  echo "ok: ${desc}"
}

require() {
  local desc="$1" pattern="$2" file="$3"
  if ! grep -E -q -- "$pattern" "$file"; then
    echo "FAIL: ${desc}" >&2
    exit 1
  fi
  echo "ok: ${desc}"
}

forbid() {
  local desc="$1" pattern="$2" file="$3"
  if grep -E -q -- "$pattern" "$file"; then
    echo "FAIL: ${desc}" >&2
    exit 1
  fi
  echo "ok: ${desc}"
}

# Same directory choice as scripts/ci/prepare_ci_debug_keystore.sh.
signing_temp_base() {
  local base="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
  printf '%s\n' "${base%/}"
}

# True when the file is inside the directory. Follows symlinks so a
# RUNNER_TEMP path and the path mktemp prints still match.
path_is_inside() {
  local path="$1" base="$2" real_path real_base
  base="${base%/}"
  [[ -n "$path" && -n "$base" && "$path" != *".."* ]] || return 1
  if [[ "$path" == "$base"/* ]]; then
    return 0
  fi
  [[ -d "$base" && -e "$path" ]] || return 1
  real_base="$(cd "$base" && pwd -P)"
  real_path="$(cd "$(dirname "$path")" && pwd -P)/$(basename "$path")"
  [[ "$real_path" == "$real_base"/* ]]
}

for secret in \
  CI_DEBUG_KEYSTORE_BASE64 \
  CI_DEBUG_KEYSTORE_PASSWORD \
  CI_DEBUG_KEY_ALIAS \
  CI_DEBUG_KEY_PASSWORD
do
  require "android-smoke references ${secret}" \
    "secrets\\.${secret}" .github/workflows/android-smoke.yml
  require "demo-seed references ${secret}" \
    "secrets\\.${secret}" .github/workflows/demo-seed-launch.yml
  require "tester-checks references ${secret}" \
    "secrets\\.${secret}" .github/workflows/tester-checks.yml
  require "ci-signing docs name ${secret}" \
    "${secret}" docs/ci-signing.md
done

require "smoke decodes the CI keystore" \
  'scripts/ci/prepare_ci_debug_keystore.sh' .github/workflows/android-smoke.yml
require "smoke points Gradle at the temp keystore" \
  'export CI_DEBUG_KEYSTORE_FILE=' .github/workflows/android-smoke.yml
require "smoke prints fingerprints" \
  'scripts/ci/print_signing_fingerprints.sh' .github/workflows/android-smoke.yml
require "smoke deletes the CI keystore without key.properties" \
  'cleanup_ci_debug_signing.sh --keep-properties' .github/workflows/android-smoke.yml
forbid "smoke profile build falls back when the CI keystore is absent" \
  'prepare_ci_debug_keystore.sh --require' .github/workflows/android-smoke.yml
forbid "smoke does not write release key.properties" \
  --key-properties .github/workflows/android-smoke.yml

require "seed-launch requires the CI keystore" \
  'prepare_ci_debug_keystore.sh --require --key-properties android/key.properties' \
  .github/workflows/demo-seed-launch.yml
require "tester-checks requires the CI keystore" \
  'prepare_ci_debug_keystore.sh --require --key-properties android/key.properties' \
  .github/workflows/tester-checks.yml
require "demo distribution prints fingerprints" \
  'print_signing_fingerprints.sh' .github/workflows/demo-app-distribution.yml
require "smoke masks the key alias" \
  '::add-mask::\$\{CI_DEBUG_KEY_ALIAS\}' .github/workflows/android-smoke.yml
require "seed-launch masks the key alias" \
  '::add-mask::\$\{CI_DEBUG_KEY_ALIAS\}' .github/workflows/demo-seed-launch.yml
require "tester-checks masks the key alias" \
  '::add-mask::\$\{CI_DEBUG_KEY_ALIAS\}' .github/workflows/tester-checks.yml
require "demo distribution masks the key alias" \
  '::add-mask::\$\{DEMO_KEY_ALIAS\}' .github/workflows/demo-app-distribution.yml
require "docs explain the hard-coded PKCS12 storeType" \
  'storeType` is hard-coded to PKCS12' docs/ci-signing.md
require "gradle comment explains the hard-coded PKCS12 storeType" \
  'Hard-coded PKCS12' android/app/build.gradle.kts

for workflow in \
  .github/workflows/android-smoke.yml \
  .github/workflows/demo-seed-launch.yml \
  .github/workflows/tester-checks.yml \
  .github/workflows/demo-app-distribution.yml
do
  forbid "workflow does not generate a keystore" 'keytool -genkeypair' "$workflow"
  forbid "workflow does not embed a store password" '-storepass' "$workflow"
  forbid "workflow does not trace commands" 'set -x' "$workflow"
done

forbid "seed-launch does not pass the keystore path through Gradle env" \
  'CI_DEBUG_KEYSTORE_FILE' .github/workflows/demo-seed-launch.yml
forbid "tester-checks does not pass the keystore path through Gradle env" \
  'CI_DEBUG_KEYSTORE_FILE' .github/workflows/tester-checks.yml

tester_build="$(awk '
  /- name: Build release APK$/ { capture=1 }
  capture && /- name: Build instrumentation APK$/ { exit }
  capture { print }
' .github/workflows/tester-checks.yml)"
if grep -q 'DEMO_BUILD\|ENABLE_ADMIN_TOOLS' <<<"$tester_build"; then
  echo "FAIL: tester-checks release APK must not pass DEMO_BUILD or ENABLE_ADMIN_TOOLS" >&2
  exit 1
fi
echo "ok: tester-checks release APK has neither demo define"

require "smoke profile command is unchanged" \
  'flutter build apk --profile --target-platform android-x64 --dart-define=DEMO_BUILD=true' \
  .github/workflows/android-smoke.yml
require "Play package id is unchanged" \
  'applicationId = "com.shradhaventures.temple"' android/app/build.gradle.kts
require "namespace is unchanged" \
  'namespace = "com.shradhaventures.temple"' android/app/build.gradle.kts
require "Gradle reads the CI keystore path from the environment" \
  'System.getenv\("CI_DEBUG_KEYSTORE_FILE"\)' android/app/build.gradle.kts
require "Gradle still refuses to sign release with the debug key" \
  'Refusing to sign a release build with the debug keystore' android/app/build.gradle.kts
require "Play signing still does not require storeType" \
  'val missingSigningKeys = listOf\("storeFile", "storePassword", "keyAlias", "keyPassword"\)' \
  android/app/build.gradle.kts
require "release builds still select the release signing config" \
  'signingConfig = signingConfigs.getByName\("release"\)' android/app/build.gradle.kts

release_block="$(awk '
  /create\("release"\)/ { capture=1 }
  capture { print }
  capture && /storeType = releaseStoreType/ { exit }
' android/app/build.gradle.kts)"
if grep -q 'CI_DEBUG' <<<"$release_block"; then
  echo "FAIL: Play release signingConfig references the CI debug keystore" >&2
  exit 1
fi
echo "ok: Play release signingConfig does not reference the CI debug keystore"

require "Play script still refuses ENABLE_ADMIN_TOOLS" \
  'ENABLE_ADMIN_TOOLS' scripts/build_play_aab.sh
require "Play script still refuses DEMO_BUILD" \
  'DEMO_BUILD' scripts/build_play_aab.sh
require "analyze-test runs this guard" \
  'scripts/ci/test_ci_signing.sh' .github/workflows/ci.yml

require "docs show the keytool command" 'keytool -genkeypair' docs/ci-signing.md
require "docs show how to base64 the keystore" 'base64 -w0' docs/ci-signing.md
forbid "docs do not embed a keystore blob" \
  'CI_DEBUG_KEYSTORE_BASE64=.+[A-Za-z0-9+/]{40}' docs/ci-signing.md

for script in \
  scripts/ci/prepare_ci_debug_keystore.sh \
  scripts/ci/print_signing_fingerprints.sh \
  scripts/ci/cleanup_ci_debug_signing.sh
do
  forbid "script does not trace commands" 'set -x' "$script"
  forbid "script does not echo CI debug secrets" \
    'echo .*(CI_DEBUG_KEYSTORE_|CI_DEBUG_KEY_)' "$script"
done
forbid "fingerprint script does not echo demo secrets" \
  'echo .*(DEMO_KEYSTORE_|DEMO_KEY_)' scripts/ci/print_signing_fingerprints.sh

if git ls-files '*.jks' '*.keystore' '*.p12' | grep -q .; then
  echo "FAIL: a keystore is tracked" >&2
  exit 1
fi
echo "ok: no keystore is tracked"

unset CI_DEBUG_KEYSTORE_BASE64 CI_DEBUG_KEYSTORE_PASSWORD CI_DEBUG_KEY_ALIAS CI_DEBUG_KEY_PASSWORD

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"; rm -f android/key.properties' EXIT
if [[ -e android/key.properties ]]; then
  echo "FAIL: android/key.properties already exists; refusing to touch it" >&2
  exit 1
fi

absent_out="$(
  CI_DEBUG_KEYSTORE_BASE64='' \
  CI_DEBUG_KEYSTORE_PASSWORD='' \
  CI_DEBUG_KEY_ALIAS='' \
  CI_DEBUG_KEY_PASSWORD='' \
  bash scripts/ci/prepare_ci_debug_keystore.sh 2>"$tmp/absent.err"
)"
expect_eq "absent secrets print no keystore path" "$absent_out" ""
if ! grep -q 'default debug keystore' "$tmp/absent.err"; then
  echo "FAIL: absent secrets did not say they fall back to the debug keystore" >&2
  exit 1
fi
echo "ok: absent secrets fall back"

set +e
bash scripts/ci/prepare_ci_debug_keystore.sh --require >"$tmp/require.out" 2>"$tmp/require.err"
require_status=$?
set -e
if [[ "$require_status" -eq 0 ]]; then
  echo "FAIL: --require exited 0 without secrets" >&2
  exit 1
fi
if ! grep -q 'cannot fall back' "$tmp/require.err"; then
  echo "FAIL: --require did not refuse the debug-key fallback" >&2
  exit 1
fi
echo "ok: --require refuses the debug-key fallback"

set +e
CI_DEBUG_KEYSTORE_PASSWORD='super-secret-password' \
  bash scripts/ci/prepare_ci_debug_keystore.sh >"$tmp/partial.out" 2>"$tmp/partial.err"
partial_status=$?
set -e
if [[ "$partial_status" -eq 0 ]]; then
  echo "FAIL: partial secrets exited 0" >&2
  exit 1
fi
if grep -q -F 'super-secret-password' "$tmp/partial.err" || grep -q -F 'super-secret-password' "$tmp/partial.out"; then
  echo "FAIL: partial-secret error included the password" >&2
  exit 1
fi
echo "ok: partial secrets fail without echoing the password"
unset CI_DEBUG_KEYSTORE_PASSWORD

export CI_DEBUG_KEYSTORE_PASSWORD='store-secret'
export CI_DEBUG_KEY_ALIAS='ci-debug'
export CI_DEBUG_KEY_PASSWORD='key-secret'
export CI_DEBUG_KEYSTORE_BASE64='@@@'
export TMPDIR="$tmp"
set +e
bash scripts/ci/prepare_ci_debug_keystore.sh >"$tmp/bad.out" 2>"$tmp/bad.err"
bad_status=$?
set -e
if [[ "$bad_status" -eq 0 ]]; then
  echo "FAIL: invalid base64 exited 0" >&2
  exit 1
fi
if grep -q -F '@@@' "$tmp/bad.err" || grep -q -F '@@@' "$tmp/bad.out"; then
  echo "FAIL: invalid base64 was echoed" >&2
  exit 1
fi
leftover_roots=("$tmp")
if [[ -n "${RUNNER_TEMP:-}" ]]; then
  leftover_roots+=("${RUNNER_TEMP%/}")
fi
if find "${leftover_roots[@]}" -name 'ci-debug-keystore.*.p12' 2>/dev/null | grep -q .; then
  echo "FAIL: invalid prepare left a keystore file" >&2
  exit 1
fi
echo "ok: invalid base64 fails without echoing it or leaving a file"

props="$tmp/key.properties"
store_password='p\a=b'
key_password="$(printf 'k\303\251y')"
alias='ci debug'
payload='ci-keystore-bytes'
export CI_DEBUG_KEYSTORE_B64_UNUSED=1
CI_DEBUG_KEYSTORE_B64="$(printf '%s' "$payload" | base64 -w0)"
export CI_DEBUG_KEYSTORE_BASE64="$CI_DEBUG_KEYSTORE_B64"
export CI_DEBUG_KEYSTORE_PASSWORD="$store_password"
export CI_DEBUG_KEY_PASSWORD="$key_password"
export CI_DEBUG_KEY_ALIAS="$alias"
unset CI_DEBUG_KEYSTORE_B64 CI_DEBUG_KEYSTORE_B64_UNUSED
prepare_out="$(bash scripts/ci/prepare_ci_debug_keystore.sh --key-properties "$props" 2>"$tmp/prepare.err")"
if grep -q -F "$store_password" "$tmp/prepare.err" || grep -q -F "$store_password" <<<"$prepare_out"; then
  echo "FAIL: prepare output included the store password" >&2
  exit 1
fi
if grep -q -F "$key_password" "$tmp/prepare.err" || grep -q -F "$key_password" <<<"$prepare_out"; then
  echo "FAIL: prepare output included the key password" >&2
  exit 1
fi
echo "ok: prepare output does not include passwords"
expect_eq "decoded keystore bytes" "$(cat "$prepare_out")" "$payload"
signing_base="$(signing_temp_base)"
if ! path_is_inside "$prepare_out" "$signing_base"; then
  echo "FAIL: keystore was not written under the signing temp dir (${signing_base})" >&2
  exit 1
fi
# Prefer RUNNER_TEMP. A keystore that only matches TMPDIR is the GitHub
# failure. Skip this when RUNNER_TEMP itself lives inside TMPDIR.
if [[ -n "${RUNNER_TEMP:-}" ]]; then
  runner_real="$(cd "${RUNNER_TEMP%/}" && pwd -P)"
  tmp_real="$(cd "${TMPDIR:-/tmp}" && pwd -P)"
  if [[ "$runner_real" != "$tmp_real" && "$runner_real" != "$tmp_real"/* ]]; then
    if path_is_inside "$prepare_out" "${TMPDIR:-/tmp}"; then
      echo "FAIL: keystore was written under TMPDIR while RUNNER_TEMP is set" >&2
      exit 1
    fi
  fi
fi
echo "ok: keystore is under the signing temp dir"
python3 - "$props" "$prepare_out" "$store_password" "$key_password" "$alias" <<'PY'
import sys

path, store_file, store_password, key_password, alias = sys.argv[1:]

def unescape(value: str) -> str:
    out = []
    i = 0
    while i < len(value):
        if value[i] == "\\" and i + 1 < len(value):
            nxt = value[i + 1]
            if nxt == "\\":
                out.append("\\")
                i += 2
            elif nxt == "n":
                out.append("\n")
                i += 2
            elif nxt == "r":
                out.append("\r")
                i += 2
            elif nxt == "t":
                out.append("\t")
                i += 2
            elif nxt == "u" and i + 6 <= len(value):
                out.append(chr(int(value[i + 2 : i + 6], 16)))
                i += 6
            else:
                out.append(nxt)
                i += 2
        else:
            out.append(value[i])
            i += 1
    return "".join(out)

found = {}
with open(path, encoding="ascii") as handle:
    for line in handle:
        key, sep, raw = line.rstrip("\n").partition("=")
        if not sep:
            sys.exit("missing separator")
        found[key] = unescape(raw)
expected = {
    "storePassword": store_password,
    "keyPassword": key_password,
    "keyAlias": alias,
    "storeFile": store_file,
    "storeType": "PKCS12",
}
if found != expected:
    sys.stderr.write("key.properties round-trip mismatch\n")
    sys.exit(1)
PY
echo "ok: key.properties round-trips PKCS12 signing values"
mode="$(stat -c '%a' "$prepare_out")"
expect_eq "decoded keystore is mode 600" "$mode" "600"
rm -f -- "$prepare_out" "$props"

# Sibling directories, so a RUNNER_TEMP that happens to live under TMPDIR
# cannot hide a wrong choice. The symlink case is the path GitHub prints
# versus the path mktemp creates.
split_parent="$tmp/split"
dir_runner="$split_parent/runner"
dir_tmp="$split_parent/tmpdir"
dir_link="$split_parent/runner-link"
mkdir -p -- "$dir_runner" "$dir_tmp"
ln -s -- "$dir_runner" "$dir_link"
runner_out="$(
  env RUNNER_TEMP="$dir_link" TMPDIR="$dir_tmp" \
    bash scripts/ci/prepare_ci_debug_keystore.sh 2>"$tmp/split-link.err"
)"
if ! path_is_inside "$runner_out" "$dir_link"; then
  echo "FAIL: keystore was not written under symlink RUNNER_TEMP (${runner_out})" >&2
  exit 1
fi
if path_is_inside "$runner_out" "$dir_tmp"; then
  echo "FAIL: symlink RUNNER_TEMP wrote the keystore under TMPDIR" >&2
  exit 1
fi
expect_eq "symlink RUNNER_TEMP keystore is mode 600" "$(stat -c '%a' "$runner_out")" "600"
rm -f -- "$runner_out"
plain_out="$(
  env RUNNER_TEMP="$dir_runner" TMPDIR="$dir_tmp" \
    bash scripts/ci/prepare_ci_debug_keystore.sh 2>"$tmp/split-plain.err"
)"
if ! path_is_inside "$plain_out" "$dir_runner"; then
  echo "FAIL: keystore was not written under RUNNER_TEMP (${plain_out})" >&2
  exit 1
fi
if path_is_inside "$plain_out" "$dir_tmp"; then
  echo "FAIL: RUNNER_TEMP wrote the keystore under TMPDIR" >&2
  exit 1
fi
rm -f -- "$plain_out"
tmpdir_out="$(
  env -u RUNNER_TEMP TMPDIR="$dir_tmp" \
    bash scripts/ci/prepare_ci_debug_keystore.sh 2>"$tmp/split-tmp.err"
)"
if ! path_is_inside "$tmpdir_out" "$dir_tmp"; then
  echo "FAIL: keystore was not written under TMPDIR when RUNNER_TEMP is unset (${tmpdir_out})" >&2
  exit 1
fi
rm -f -- "$tmpdir_out"
echo "ok: RUNNER_TEMP wins over a different TMPDIR"

# Real keystore stays under mktemp. It is not committed.
real="$tmp/real.p12"
real_pass='store-secret-value'
real_alias='ci-debug'
keytool -genkeypair -keystore "$real" -storetype PKCS12 \
  -storepass "$real_pass" -keypass "$real_pass" -alias "$real_alias" \
  -keyalg RSA -keysize 2048 -validity 1 \
  -dname "CN=Temple Directory CI, OU=CI, O=Test, C=IN" >/dev/null 2>&1
export CI_DEBUG_KEYSTORE_PASSWORD="$real_pass"
export CI_DEBUG_KEY_PASSWORD="$real_pass"
export CI_DEBUG_KEY_ALIAS="$real_alias"
export CI_DEBUG_KEYSTORE_BASE64="$(base64 -w0 "$real")"
decoded="$(bash scripts/ci/prepare_ci_debug_keystore.sh --require 2>"$tmp/real.err")"
if ! cmp -s "$real" "$decoded"; then
  echo "FAIL: decoded CI keystore bytes did not match" >&2
  exit 1
fi
echo "ok: --require decodes the keystore bytes"
fingerprints="$(bash scripts/ci/print_signing_fingerprints.sh "$decoded" CI_DEBUG_KEYSTORE_PASSWORD CI_DEBUG_KEY_ALIAS 2>"$tmp/fp.err")"
if grep -q -F "$real_pass" <<<"$fingerprints" || grep -q -F "$real_pass" "$tmp/fp.err"; then
  echo "FAIL: fingerprint output included the store password" >&2
  exit 1
fi
want_sha1="$(keytool -list -v -keystore "$real" -storepass:env CI_DEBUG_KEYSTORE_PASSWORD -alias "$real_alias" | sed -n 's/^[[:space:]]*SHA1: //p')"
want_sha256="$(keytool -list -v -keystore "$real" -storepass:env CI_DEBUG_KEYSTORE_PASSWORD -alias "$real_alias" | sed -n 's/^[[:space:]]*SHA256: //p')"
expect_eq "printed SHA-1" "$(sed -n 's/^signing SHA-1: //p' <<<"$fingerprints")" "$want_sha1"
expect_eq "printed SHA-256" "$(sed -n 's/^signing SHA-256: //p' <<<"$fingerprints")" "$want_sha256"
if [[ "$(printf '%s\n' "$fingerprints" | wc -l)" -ne 2 ]]; then
  echo "FAIL: fingerprint output was not exactly two lines" >&2
  exit 1
fi
echo "ok: fingerprint output is two lines"

jar="$tmp/sample.jar"
printf 'hi\n' >"$tmp/sample.txt"
jar cf "$jar" -C "$tmp" sample.txt
jarsigner -keystore "$real" -storepass:env CI_DEBUG_KEYSTORE_PASSWORD "$jar" "$real_alias" >/dev/null
apk_fingerprints="$(bash scripts/ci/print_signing_fingerprints.sh --apk "$jar" 2>"$tmp/apk.err")"
expect_eq "APK SHA-1" "$(sed -n 's/^signing SHA-1: //p' <<<"$apk_fingerprints")" "$want_sha1"
expect_eq "APK SHA-256" "$(sed -n 's/^signing SHA-256: //p' <<<"$apk_fingerprints")" "$want_sha256"

runner="$tmp/runner"
mkdir -p "$runner"
printf 'bytes' >"$runner/ci-debug-keystore.abc.p12"
printf '%s\n' "$runner/ci-debug-keystore.abc.p12" >"$runner/ci-debug-signing.path"
printf 'storePassword=do-not-keep\n' > android/key.properties
RUNNER_TEMP="$runner" bash scripts/ci/cleanup_ci_debug_signing.sh --keep-properties
if [[ ! -f android/key.properties ]]; then
  echo "FAIL: --keep-properties deleted android/key.properties" >&2
  exit 1
fi
if [[ -e "$runner/ci-debug-keystore.abc.p12" || -e "$runner/ci-debug-signing.path" ]]; then
  echo "FAIL: --keep-properties left the CI keystore" >&2
  exit 1
fi
echo "ok: --keep-properties leaves key.properties and deletes the keystore"
RUNNER_TEMP="$runner" bash scripts/ci/cleanup_ci_debug_signing.sh
if [[ -e android/key.properties ]]; then
  echo "FAIL: cleanup left key.properties" >&2
  exit 1
fi
echo "ok: cleanup deletes key.properties"

printf 'bytes' >"$runner/ci-debug-keystore.zzz.p12"
printf '%s\n' "$runner/ci-debug-keystore.zzz.p12" >"$runner/ci-debug-signing.path"
RUNNER_TEMP="$runner" bash scripts/ci/cleanup_ci_debug_signing.sh --keep-properties
if [[ -e "$runner/ci-debug-keystore.zzz.p12" || -e "$runner/ci-debug-signing.path" ]]; then
  echo "FAIL: path-file cleanup left the CI keystore" >&2
  exit 1
fi
echo "ok: path-file cleanup deletes the CI keystore"

if RUNNER_TEMP="$runner" bash scripts/ci/cleanup_ci_debug_signing.sh /etc/passwd 2>/dev/null; then
  echo "FAIL: cleanup accepted a path outside temp" >&2
  exit 1
fi
if [[ ! -f /etc/passwd ]]; then
  echo "FAIL: cleanup removed /etc/passwd" >&2
  exit 1
fi
echo "ok: cleanup refuses a path outside temp"
rm -f -- "$decoded" "$real" "$jar"
echo "ok: ci signing guards"
