#!/usr/bin/env bash
# Checks for the demo App Distribution workflow.
# Does not run flutter, does not call Firebase, and does not print secrets.
set -euo pipefail

cd "$(dirname "$0")/../.."
unset RUNNER_TEMP

expect_eq() {
  local desc="$1" got="$2" want="$3"
  if [[ "$got" != "$want" ]]; then
    echo "FAIL: ${desc}: got '${got}', want '${want}'" >&2
    exit 1
  fi
  echo "ok: ${desc}"
}

expect_file() {
  local desc="$1" path="$2"
  if [[ ! -f "$path" ]]; then
    echo "FAIL: ${desc}: missing ${path}" >&2
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

require() {
  local desc="$1" pattern="$2" file="$3"
  if ! grep -E -q -- "$pattern" "$file"; then
    echo "FAIL: ${desc}" >&2
    exit 1
  fi
  echo "ok: ${desc}"
}

workflow=.github/workflows/demo-app-distribution.yml
expect_file "demo distribution workflow exists" "$workflow"

on_block="$(awk '
  /^on:$/ { capture=1; next }
  capture && /^[^ ]/ { exit }
  capture { print }
' "$workflow")"
if ! grep -q 'workflow_dispatch:' <<<"$on_block"; then
  echo "FAIL: workflow_dispatch trigger missing" >&2
  exit 1
fi
echo "ok: workflow_dispatch trigger"
if ! grep -q -- '- main' <<<"$on_block"; then
  echo "FAIL: push to main trigger missing" >&2
  exit 1
fi
echo "ok: push to main trigger"
for path_filter in \
  'lib/**' \
  'android/**' \
  'assets/**' \
  'pubspec.*' \
  '.github/workflows/demo-app-distribution.yml'
do
  if ! grep -F -q "$path_filter" <<<"$on_block"; then
    echo "FAIL: push paths filter missing ${path_filter}" >&2
    exit 1
  fi
done
echo "ok: push paths filter"
if grep -q 'pull_request' <<<"$on_block"; then
  echo "FAIL: pull_request must not trigger this workflow" >&2
  exit 1
fi
echo "ok: pull_request is not a trigger"

expect_eq "contents: read is set on the workflow and the job" \
  "$(grep -c 'contents: read' "$workflow")" 2
if grep -E -q '^[[:space:]]+[A-Za-z0-9_-]+: write$' "$workflow"; then
  echo "FAIL: workflow grants a write permission" >&2
  exit 1
fi
echo "ok: no write permission"

require "concurrency cancels superseded runs" \
  'cancel-in-progress: true' "$workflow"
# shellcheck disable=SC2016 # workflow expression is literal text
if ! grep -F -q 'group: ${{ github.workflow }}-${{ github.ref }}' "$workflow"; then
  echo "FAIL: concurrency group is not the workflow and ref" >&2
  exit 1
fi
echo "ok: concurrency group is the workflow and ref"

timeout="$(awk '/^    timeout-minutes:/ { print $2; exit }' "$workflow")"
if [[ -z "$timeout" || "$timeout" -gt 30 ]]; then
  echo "FAIL: job timeout must be 30 minutes or less (got '${timeout}')" >&2
  exit 1
fi
echo "ok: job timeout is ${timeout} minutes"

require "APK artifact is kept for 7 days" 'retention-days: 7' "$workflow"
require "APK artifact name" 'name: demo-apk' "$workflow"

expect_eq "both apk builds pass DEMO_BUILD" \
  "$(grep -c -- '--dart-define=DEMO_BUILD=true' "$workflow")" 2
expect_eq "both apk builds pass ENABLE_ADMIN_TOOLS" \
  "$(grep -c -- '--dart-define=ENABLE_ADMIN_TOOLS=true' "$workflow")" 2
expect_eq "both apk builds pass DEMO_APP_ID_SUFFIX" \
  "$(grep -c -- '--dart-define=DEMO_APP_ID_SUFFIX=true' "$workflow")" 2
expect_eq "both apk builds request arm, arm64, and x86_64" \
  "$(grep -c -- '--target-platform android-arm,android-arm64,android-x64' "$workflow")" 2
expect_eq "split-per-abi is only the over-60MiB fallback" \
  "$(grep -c -- '--split-per-abi' "$workflow")" 1

forbid "workflow does not build a Play bundle" 'build_play_aab|appbundle' "$workflow"
forbid "workflow does not run Seed or Firestore writes" \
  'seed_service|firebase deploy|firestore' "$workflow"
forbid "workflow does not trace commands" 'set -x' "$workflow"
forbid "workflow does not echo secrets" \
  'echo .*(secrets\.|\$\{?DEMO_KEYSTORE_|\$\{?DEMO_KEY_|\$\{?FIREBASE_)' "$workflow"

require "workflow decodes the demo keystore" \
  'prepare_demo_keystore.sh' "$workflow"
require "workflow deletes the demo keystore" \
  'cleanup_demo_signing.sh' "$workflow"
require "workflow chooses universal vs split from the file size" \
  'demo_apk_layout.sh' "$workflow"
require "workflow distributes with the helper script" \
  'distribute_demo_apk.sh' "$workflow"
require "workflow checks the demo google-services client" \
  'check_demo_google_services.sh' "$workflow"
require "workflow checks the registered Firebase app id" \
  'check_firebase_android_app_id.sh' "$workflow"
require "workflow installs the pinned CLI with npm ci" 'npm ci' "$workflow"
forbid "workflow does not use npx" 'npx' "$workflow"
if ! grep -F -q 'if: always()' "$workflow"; then
  echo "FAIL: cleanup step must use if: always()" >&2
  exit 1
fi
echo "ok: cleanup step uses if: always()"
if grep -F -q 'always() &&' "$workflow"; then
  echo "FAIL: cleanup must not be gated on another condition" >&2
  exit 1
fi
echo "ok: cleanup is not gated on the plan result"

plan_step="$(awk '
  /^      - name: Plan signing and distribution$/ { capture=1 }
  capture && /^      - name:/ && !/^      - name: Plan signing/ { exit }
  capture { print }
' "$workflow")"
for secret_name in \
  DEMO_KEYSTORE_B64 \
  DEMO_KEYSTORE_PASSWORD \
  DEMO_KEY_ALIAS \
  DEMO_KEY_PASSWORD \
  FIREBASE_ANDROID_APP_ID \
  FIREBASE_APP_DISTRIBUTION_SA_JSON
do
  if ! grep -F -q "secrets.${secret_name} != ''" <<<"$plan_step"; then
    echo "FAIL: plan step does not pass a presence flag for ${secret_name}" >&2
    exit 1
  fi
done
echo "ok: plan step receives secret presence flags"
if grep -E -q "secrets\\.[A-Z0-9_]+[[:space:]]*}}" <<<"$plan_step"; then
  echo "FAIL: plan step receives a secret value" >&2
  exit 1
fi
echo "ok: plan step does not receive secret values"

require "demo builds use the .demo application id suffix" \
  'applicationIdSuffix = "\.demo"' android/app/build.gradle.kts
require "Play application id stays the base id" \
  'applicationId = "com.shradhaventures.temple"' android/app/build.gradle.kts
require "demo label includes Demo" \
  'Temple Directory India Demo' android/app/build.gradle.kts
require "manifest label is the gradle placeholder" \
  'android:label="\$\{appLabel\}"' android/app/src/main/AndroidManifest.xml
if awk '
  /if \(demoBuild\)/ { demo=1; next }
  demo && /applicationIdSuffix/ { found=1 }
  demo && /^        \}/ { demo=0 }
  END { exit found ? 0 : 1 }
' android/app/build.gradle.kts; then
  echo "FAIL: applicationIdSuffix must not follow DEMO_BUILD" >&2
  exit 1
fi
echo "ok: DEMO_BUILD does not change the application id"
if ! awk '
  /if \(demoAppIdSuffix\)/ { suffix=1; next }
  suffix && /applicationIdSuffix/ { found=1 }
  suffix && /^        \}/ { suffix=0 }
  END { exit found ? 0 : 1 }
' android/app/build.gradle.kts; then
  echo "FAIL: applicationIdSuffix is not inside the demoAppIdSuffix branch" >&2
  exit 1
fi
echo "ok: applicationIdSuffix is only applied for DEMO_APP_ID_SUFFIX"
if ! awk '
  /if \(demoAppIdSuffix\)/ { suffix=1; next }
  suffix && /Temple Directory India Demo/ { found=1 }
  suffix && /^    buildTypes/ { suffix=0 }
  END { exit found ? 0 : 1 }
' android/app/build.gradle.kts; then
  echo "FAIL: Demo label is not tied to demoAppIdSuffix" >&2
  exit 1
fi
echo "ok: Demo label is only applied with the application id suffix"
for untouched in \
  .github/workflows/android-smoke.yml \
  .github/workflows/demo-seed-launch.yml \
  .github/workflows/tester-checks.yml
do
  if grep -q 'DEMO_APP_ID_SUFFIX\|demo_suffix' "$untouched"; then
    echo "FAIL: ${untouched} sets the demo application id suffix" >&2
    exit 1
  fi
done
echo "ok: smoke, seed-launch, and tester-checks do not set the suffix"
require "Play script refuses the demo application id suffix" \
  'refuse_demo_suffix' scripts/build_play_aab.sh
require "Play script refuses ORG_GRADLE_PROJECT_demo_suffix" \
  'ORG_GRADLE_PROJECT_demo_suffix' scripts/build_play_aab.sh
require "Play bundle task rejects the demo application id" \
  'playBundleRequested && demoAppIdSuffix' android/app/build.gradle.kts
forbid "committed Gradle properties do not set demo_suffix" \
  'demo_suffix|DEMO_APP_ID_SUFFIX' android/gradle.properties
require "smoke still launches the Play package" \
  'PKG=com.shradhaventures.temple' scripts/ci/run_android_smoke.sh
require "seed-launch still launches the Play package" \
  'PKG=com.shradhaventures.temple' scripts/ci/run_demo_seed_launch.sh
require "read-only Maestro flow still uses the Play package" \
  'appId: com.shradhaventures.temple' .maestro/read_only_smoke.yaml
require "screenshot Maestro flow still uses the Play package" \
  'appId: com.shradhaventures.temple' .maestro/screenshots.yaml
for smoke_workflow in \
  .github/workflows/android-smoke.yml \
  .github/workflows/demo-seed-launch.yml
do
  require "smoke workflow frees disk" \
    'scripts/ci/free_runner_disk.sh' "$smoke_workflow"
  if grep -E -q 'npm ci|firebase-cli|firebase-tools|setup-node' "$smoke_workflow"; then
    echo "FAIL: ${smoke_workflow} installs npm or firebase-tools" >&2
    exit 1
  fi
done
echo "ok: smoke workflows free disk and do not install firebase-tools"
require "distribution workflow frees disk" \
  'scripts/ci/free_runner_disk.sh' "$workflow"
if grep -q 'setup-node' "$workflow"; then
  echo "FAIL: distribution workflow must keep the image Node" >&2
  exit 1
fi
echo "ok: distribution workflow keeps the image Node"
require "disk script prints df before" '===== disk before =====' scripts/ci/free_runner_disk.sh
require "disk script prints df after" '===== disk after =====' scripts/ci/free_runner_disk.sh
require "disk script removes dotnet" '/usr/share/dotnet' scripts/ci/free_runner_disk.sh
require "disk script removes ghc" '/opt/ghc' scripts/ci/free_runner_disk.sh
require "disk script removes the preinstalled NDK" \
  '/usr/local/lib/android/sdk/ndk' scripts/ci/free_runner_disk.sh
if grep -q 'hostedtoolcache' scripts/ci/free_runner_disk.sh; then
  echo "FAIL: disk script must leave the image tool directory in place" >&2
  exit 1
fi
echo "ok: disk script leaves the image tool directory"
for ndk_workflow in \
  .github/workflows/android-smoke.yml \
  .github/workflows/demo-seed-launch.yml \
  "$workflow"
do
  require "workflow caches NDK 28.2.13676358" \
    '/usr/local/lib/android/sdk/ndk/28.2.13676358' "$ndk_workflow"
  require "workflow restores a previous Gradle cache" \
    'restore-keys: gradle-' "$ndk_workflow"
done
if grep -q 'timeout-minutes: 30' .github/workflows/android-smoke.yml; then
  echo "FAIL: android-smoke emulator job must stay at 15 minutes" >&2
  exit 1
fi
require "android-smoke job limit stays 15 minutes" \
  'timeout-minutes: 15' .github/workflows/android-smoke.yml
require "committed Gradle heap stays 8G for local builds" \
  '^org\.gradle\.jvmargs=-Xmx8G ' android/gradle.properties
require "seed-launch caps the hosted Gradle heap" \
  'org.gradle.jvmargs=-Xmx3g' .github/workflows/demo-seed-launch.yml
require "seed-launch caps the Kotlin daemon" \
  'kotlin.daemon.jvmargs=-Xmx1g' .github/workflows/demo-seed-launch.yml
if grep -q 'org.gradle.jvmargs=-Xmx3g' .github/workflows/android-smoke.yml; then
  echo "FAIL: android-smoke must keep the committed Gradle heap" >&2
  exit 1
fi
echo "ok: android-smoke keeps the committed Gradle heap"
require "smoke keeps dismissing the system ANR until Terms is visible" \
  'notVisible:' .maestro/read_only_smoke.yaml
if ! grep -F -q 'labels=$'"'"'Wait'"'"'' scripts/ci/run_android_smoke.sh; then
  echo "FAIL: smoke must tap Wait only on the system ANR dialog" >&2
  exit 1
fi
echo "ok: smoke taps Wait only on the system ANR dialog"
require "seed launch taps Wait on the system ANR" \
  'tap_needle "Wait"' scripts/ci/run_demo_seed_launch.sh
require "seed launch dismisses the Pixel Launcher ANR" \
  'Pixel Launcher isn'"'"'t responding' scripts/ci/run_demo_seed_launch.sh
require "seed launch dismisses the System UI ANR" \
  'System UI isn'"'"'t responding' scripts/ci/run_demo_seed_launch.sh
require "seed launch dismisses a Google Play services ANR" \
  'Google Play services isn'"'"'t responding' scripts/ci/run_demo_seed_launch.sh
require "seed launch dismisses a GMS process ANR" \
  'com.google.android.gms' scripts/ci/run_demo_seed_launch.sh
require "seed launch fails an app ANR" \
  'App ANR:' scripts/ci/run_demo_seed_launch.sh
require "seed launch screenshots an app ANR" \
  'screenshot app-anr' scripts/ci/run_demo_seed_launch.sh
forbid "seed launch does not tap Close app" 'Close app' \
  scripts/ci/run_demo_seed_launch.sh
require "Maestro smoke dismisses the system ANR with Wait" \
  'Process system isn'"'"'t responding' .maestro/read_only_smoke.yaml
require "Maestro smoke dismisses the System UI ANR with Wait" \
  'System UI isn'"'"'t responding' .maestro/read_only_smoke.yaml
require "Maestro smoke dismisses a Google Play services ANR with Wait" \
  'Google Play services isn'"'"'t responding' .maestro/read_only_smoke.yaml
require "Maestro smoke dismisses a GMS process ANR with Wait" \
  'com\\\\\.google\\\\\.android\\\\\.gms' .maestro/read_only_smoke.yaml
require "smoke shell dismisses a Google Play services ANR" \
  'Google Play services isn'"'"'t responding' scripts/ci/run_android_smoke.sh
require "Maestro smoke fails an app ANR" \
  'App ANR: Temple Directory India isn'"'"'t responding' \
  .maestro/read_only_smoke.yaml
forbid "Maestro smoke does not tap Close app" 'Close app' \
  .maestro/read_only_smoke.yaml
forbid "smoke shell does not tap Close app" 'Close app' \
  scripts/ci/run_android_smoke.sh
if grep -q '/usr/local/lib/android/sdk/system-images' scripts/ci/free_runner_disk.sh; then
  echo "FAIL: disk script must not delete the emulator system images" >&2
  exit 1
fi
echo "ok: disk script leaves the emulator system images"
for emulator_workflow in \
  .github/workflows/android-smoke.yml \
  .github/workflows/demo-seed-launch.yml
do
  require "workflow uses the google_atd system image" \
    'target: google_atd' "$emulator_workflow"
  require "workflow caches the google_atd system image" \
    'system-image-android-34-google_atd-x86_64' "$emulator_workflow"
  require "workflow caches the google_atd AVD snapshot" \
    'avd-34-x86_64-google_atd-pixel6-snapshot' "$emulator_workflow"
  require "workflow sets emulator cores from nproc" \
    'cores: \$\{' "$emulator_workflow"
  require "workflow caps AVD userdata at 2048M" \
    'disk-size: 2048M' "$emulator_workflow"
  require "workflow installs the fail-fast emulator wrapper" \
    'scripts/ci/prepare_atd_avd.sh' "$emulator_workflow"
  require "workflow prints df before the emulator" \
    '===== df before emulator =====' "$emulator_workflow"
  require "workflow disables emulator audio" \
    '-no-audio' "$emulator_workflow"
  if ! awk '
    /free_runner_disk.sh/ { freed = 1 }
    /flutter build apk/ && !freed { exit 1 }
    END { if (!freed) exit 1 }
  ' "$emulator_workflow"; then
    echo "FAIL: ${emulator_workflow} must free disk before the APK build" >&2
    exit 1
  fi
  if grep -q 'target: google_apis' "$emulator_workflow"; then
    echo "FAIL: ${emulator_workflow} must not boot the google_apis image" >&2
    exit 1
  fi
  if grep -q -- '-noaudio' "$emulator_workflow"; then
    echo "FAIL: ${emulator_workflow} must use -no-audio" >&2
    exit 1
  fi
done
echo "ok: emulator jobs use google_atd, nproc cores, 2048M userdata, and -no-audio"
require "fail-fast wrapper reports a dead emulator" \
  'Emulator process exited before boot' scripts/ci/emulator_fail_fast.sh
require "AVD prep forces a 2048M userdata image" \
  'disk.dataPartition.size=2048M' scripts/ci/prepare_atd_avd.sh
require "AVD prep replaces an oversized userdata.img" \
  'mkfs.ext4 -F -L data' scripts/ci/prepare_atd_avd.sh
require "AVD prep drops the NDK only after a cache hit" \
  'removed NDK after a cache hit' scripts/ci/prepare_atd_avd.sh
require "smoke passes -partition-size 2048" \
  '-partition-size 2048' .github/workflows/android-smoke.yml
require "seed-launch passes -partition-size 2048" \
  '-partition-size 2048' .github/workflows/demo-seed-launch.yml
forbid "disk script does not install npm" 'npm |firebase-tools|firebase-cli' \
  scripts/ci/free_runner_disk.sh
if grep -F -q 'applicationIdSuffix' scripts/build_play_aab.sh; then
  echo "FAIL: Play script must not set an application id suffix" >&2
  exit 1
fi
echo "ok: Play script does not set an application id suffix"

require "Play signing still does not require storeType" \
  'val missingSigningKeys = listOf\("storeFile", "storePassword", "keyAlias", "keyPassword"\)' \
  android/app/build.gradle.kts
require "storeType is applied only when key.properties sets it" \
  'if \(releaseStoreType != null\)' android/app/build.gradle.kts

forbid "Play script does not distribute the demo APK" \
  'appdistribution|DEMO_KEYSTORE|FIREBASE_APP_DISTRIBUTION' scripts/build_play_aab.sh
require "analyze-test runs this guard" \
  'scripts/ci/test_demo_distribution_guard.sh' .github/workflows/ci.yml

require "keystore is PKCS12" 'storeType=PKCS12' scripts/ci/prepare_demo_keystore.sh
require "keystore is base64-decoded" 'base64 --decode' scripts/ci/prepare_demo_keystore.sh
forbid "keystore script does not echo secrets" \
  'echo .*(DEMO_KEYSTORE_|DEMO_KEY_)' scripts/ci/prepare_demo_keystore.sh
forbid "keystore script does not trace commands" 'set -x' scripts/ci/prepare_demo_keystore.sh

require "distribute uses the Firebase CLI" \
  'appdistribution:distribute' scripts/ci/distribute_demo_apk.sh
require "distribute targets core-testers" \
  '--groups core-testers' scripts/ci/distribute_demo_apk.sh
require "distribute uses GOOGLE_APPLICATION_CREDENTIALS" \
  'GOOGLE_APPLICATION_CREDENTIALS=' scripts/ci/distribute_demo_apk.sh
require "firebase-tools is pinned in package.json" \
  '"firebase-tools": "15.34.0"' scripts/ci/firebase-cli/package.json
require "firebase-tools lockfile exists" \
  '"node_modules/firebase-tools"' scripts/ci/firebase-cli/package-lock.json
forbid "distribute script does not use npx" 'npx' scripts/ci/distribute_demo_apk.sh
forbid "distribute script does not trace commands" 'set -x' scripts/ci/distribute_demo_apk.sh
# shellcheck disable=SC2016 # grep pattern, not a shell expansion
forbid "distribute script does not echo the service account" \
  'echo .*(\$FIREBASE_APP_DISTRIBUTION_SA_JSON|\$FIREBASE_ANDROID_APP_ID|private_key)' \
  scripts/ci/distribute_demo_apk.sh
forbid "distribute script does not run Seed or Firestore writes" \
  'seed_service|firebase deploy|firestore' scripts/ci/distribute_demo_apk.sh

expect_eq "60 MiB stays universal" \
  "$(bash scripts/ci/demo_apk_layout.sh 62914560)" universal
expect_eq "one byte over 60 MiB splits per ABI" \
  "$(bash scripts/ci/demo_apk_layout.sh 62914561)" split
expect_eq "a small APK stays universal" \
  "$(bash scripts/ci/demo_apk_layout.sh 0)" universal

fill_signing() {
  export HAS_DEMO_KEYSTORE_B64=true
  export HAS_DEMO_KEYSTORE_PASSWORD=true
  export HAS_DEMO_KEY_ALIAS=true
  export HAS_DEMO_KEY_PASSWORD=true
}

fill_firebase() {
  export HAS_FIREBASE_ANDROID_APP_ID=true
  export HAS_FIREBASE_APP_DISTRIBUTION_SA_JSON=true
}

clear_demo_env() {
  unset HAS_DEMO_KEYSTORE_B64 HAS_DEMO_KEYSTORE_PASSWORD HAS_DEMO_KEY_ALIAS HAS_DEMO_KEY_PASSWORD
  unset HAS_FIREBASE_ANDROID_APP_ID HAS_FIREBASE_APP_DISTRIBUTION_SA_JSON
  unset DEMO_KEYSTORE_B64 DEMO_KEYSTORE_PASSWORD DEMO_KEY_ALIAS DEMO_KEY_PASSWORD
  unset FIREBASE_ANDROID_APP_ID FIREBASE_APP_DISTRIBUTION_SA_JSON
  unset DEMO_KEYSTORE_PATH GOOGLE_APPLICATION_CREDENTIALS RUNNER_TEMP
}

run_plan() {
  local event="$1"
  shift
  GITHUB_EVENT_NAME="$event" bash scripts/ci/demo_distribution_plan.sh
}

clear_demo_env
fill_signing
fill_firebase
export DEMO_KEYSTORE_PASSWORD=store-secret
plan="$(run_plan push)"
expect_eq "push with secrets signs" "$(grep '^sign=' <<<"$plan" | cut -d= -f2-)" true
expect_eq "push with secrets distributes" "$(grep '^distribute=' <<<"$plan" | cut -d= -f2-)" true
if ! grep -q 'core-testers' <<<"$plan"; then
  echo "FAIL: a ready run should name the tester group" >&2
  exit 1
fi
echo "ok: a ready run names core-testers"
if grep -q 'store-secret' <<<"$plan"; then
  echo "FAIL: plan output included a signing secret" >&2
  exit 1
fi
echo "ok: plan output does not include signing secrets"

plan="$(run_plan workflow_dispatch)"
expect_eq "workflow_dispatch with secrets distributes" \
  "$(grep '^distribute=' <<<"$plan" | cut -d= -f2-)" true

plan="$(run_plan pull_request)"
expect_eq "pull_request still signs when the keystore secrets exist" \
  "$(grep '^sign=' <<<"$plan" | cut -d= -f2-)" true
expect_eq "pull_request skips distribution" \
  "$(grep '^distribute=' <<<"$plan" | cut -d= -f2-)" false
if ! grep -q 'Skipping distribution on a pull_request run.' <<<"$plan"; then
  echo "FAIL: pull_request skip was not reported" >&2
  exit 1
fi
echo "ok: pull_request skip is reported"

clear_demo_env
fill_signing
export HAS_FIREBASE_ANDROID_APP_ID=false
export HAS_FIREBASE_APP_DISTRIBUTION_SA_JSON=true
export FIREBASE_ANDROID_APP_ID="should-not-be-read"
plan="$(run_plan push)"
expect_eq "missing app id still signs" "$(grep '^sign=' <<<"$plan" | cut -d= -f2-)" true
expect_eq "missing app id skips distribution" \
  "$(grep '^distribute=' <<<"$plan" | cut -d= -f2-)" false
if ! grep -q 'FIREBASE_ANDROID_APP_ID' <<<"$plan"; then
  echo "FAIL: missing app id was not named" >&2
  exit 1
fi
if grep -q 'should-not-be-read' <<<"$plan"; then
  echo "FAIL: plan output included a secret value" >&2
  exit 1
fi
echo "ok: missing app id is named"

clear_demo_env
fill_firebase
export HAS_DEMO_KEYSTORE_B64=false
export HAS_DEMO_KEYSTORE_PASSWORD=true
export HAS_DEMO_KEY_ALIAS=true
export HAS_DEMO_KEY_PASSWORD=true
export DEMO_KEYSTORE_PASSWORD="store-secret"
plan="$(run_plan push)"
expect_eq "missing keystore skips signing" "$(grep '^sign=' <<<"$plan" | cut -d= -f2-)" false
expect_eq "missing keystore skips distribution" \
  "$(grep '^distribute=' <<<"$plan" | cut -d= -f2-)" false
if grep -q 'store-secret' <<<"$plan"; then
  echo "FAIL: missing-keystore plan included a password" >&2
  exit 1
fi
echo "ok: missing-keystore plan does not include a password"

output_file="$(mktemp)"
clear_demo_env
fill_signing
fill_firebase
GITHUB_OUTPUT="$output_file" GITHUB_EVENT_NAME=push \
  bash scripts/ci/demo_distribution_plan.sh >/dev/null
expect_eq "GITHUB_OUTPUT sign" "$(grep '^sign=' "$output_file" | cut -d= -f2-)" true
expect_eq "GITHUB_OUTPUT distribute" "$(grep '^distribute=' "$output_file" | cut -d= -f2-)" true
rm -f "$output_file"

# Keystore round-trip. Fixture passwords are not real secrets.
tmp="$(mktemp -d)"
props="$tmp/key.properties"
printf 'storePassword=keep-me\n' >"$props"
payload='demo-keystore-bytes'
store_password='p\a=b'
key_password="$(printf 'k\303\251y')"
alias='demo key'
clear_demo_env
DEMO_KEYSTORE_B64="$(printf '%s' "$payload" | base64 -w0)"
export DEMO_KEYSTORE_B64
export DEMO_KEYSTORE_PASSWORD="$store_password"
export DEMO_KEY_PASSWORD="$key_password"
export DEMO_KEY_ALIAS="$alias"
export TMPDIR="$tmp"
set +e
prepare_out="$(bash scripts/ci/prepare_demo_keystore.sh "$props" 2>"$tmp/prepare.err")"
prepare_status=$?
set -e
if [[ "$prepare_status" -ne 0 ]]; then
  echo "FAIL: prepare_demo_keystore.sh exited ${prepare_status}" >&2
  exit 1
fi
echo "ok: prepare_demo_keystore.sh exits 0"
if grep -q -F "$store_password" "$tmp/prepare.err" || grep -q -F "$store_password" <<<"$prepare_out"; then
  echo "FAIL: prepare output included the store password" >&2
  exit 1
fi
if grep -q -F "$key_password" "$tmp/prepare.err" || grep -q -F "$key_password" <<<"$prepare_out"; then
  echo "FAIL: prepare output included the key password" >&2
  exit 1
fi
echo "ok: prepare output does not include passwords"
if [[ ! -f "$prepare_out" ]]; then
  echo "FAIL: prepare did not print a keystore path" >&2
  exit 1
fi
if [[ "$prepare_out" != "$tmp"/* ]]; then
  echo "FAIL: keystore was not written under TMPDIR" >&2
  exit 1
fi
expect_eq "decoded keystore bytes" "$(cat "$prepare_out")" "$payload"
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

bash scripts/ci/cleanup_demo_signing.sh "$prepare_out" "$props"
if [[ -e "$prepare_out" || -e "$props" ]]; then
  echo "FAIL: cleanup left the keystore or key.properties" >&2
  exit 1
fi
echo "ok: cleanup deletes the keystore and key.properties"

if bash scripts/ci/cleanup_demo_signing.sh /etc/passwd "$tmp/unused.properties" 2>/dev/null; then
  echo "FAIL: cleanup deleted or accepted a path outside temp" >&2
  exit 1
fi
if [[ ! -f /etc/passwd ]]; then
  echo "FAIL: cleanup removed /etc/passwd" >&2
  exit 1
fi
echo "ok: cleanup refuses a path outside temp"
if bash scripts/ci/cleanup_demo_signing.sh /tmp/../etc/passwd "$tmp/unused.properties" 2>/dev/null; then
  echo "FAIL: cleanup accepted a path that leaves temp" >&2
  exit 1
fi
echo "ok: cleanup refuses .. in the keystore path"

# A bad keystore must not replace an existing properties file.
printf 'storePassword=keep-me\n' >"$props"
export DEMO_KEYSTORE_B64='@@@'
set +e
bash scripts/ci/prepare_demo_keystore.sh "$props" >"$tmp/bad.out" 2>"$tmp/bad.err"
bad_status=$?
set -e
if [[ "$bad_status" -eq 0 ]]; then
  echo "FAIL: invalid keystore base64 exited 0" >&2
  exit 1
fi
expect_eq "failed prepare keeps the previous properties file" \
  "$(cat "$props")" "storePassword=keep-me"
if grep -q -F '@@@' "$tmp/bad.err" || grep -q -F '@@@' "$tmp/bad.out"; then
  echo "FAIL: invalid base64 was echoed" >&2
  exit 1
fi
echo "ok: invalid keystore base64 fails without echoing it"
if find "$tmp" -name 'demo-keystore.*.p12' | grep -q .; then
  echo "FAIL: invalid prepare left a keystore file" >&2
  exit 1
fi
echo "ok: invalid prepare deletes the partial keystore"

# Distribution. A fake npx records the CLI args and must not be required
# when the run skips.
fake_bin="$(mktemp -d)"
record="$tmp/npx-record"
mkdir -p "$record"
cat >"$fake_bin/firebase" <<'EOF'
#!/bin/bash
set -euo pipefail
printf '%s\n' "$@" >"$FAKE_RECORD/args"
prev=""
notes=""
for arg in "$@"; do
  if [[ "$prev" == "--release-notes-file" ]]; then
    notes="$arg"
  fi
  if [[ "$prev" == "--app" ]]; then
    printf '%s' "$arg" >"$FAKE_RECORD/app"
  fi
  prev="$arg"
done
if [[ -n "$notes" ]]; then
  cp "$notes" "$FAKE_RECORD/notes"
fi
if [[ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" || ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
  echo "credentials file missing" >"$FAKE_RECORD/error"
  exit 4
fi
python3 - "$GOOGLE_APPLICATION_CREDENTIALS" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
assert data.get("type") == "service_account"
assert "private_key" in data
PY
printf '%s\n' "$GOOGLE_APPLICATION_CREDENTIALS" >"$FAKE_RECORD/gac"
if [[ "${FAKE_NPX_STATUS:-0}" -ne 0 ]]; then
  exit "$FAKE_NPX_STATUS"
fi
exit 0
EOF
chmod +x "$fake_bin/firebase"

apk="$tmp/app-release.apk"
printf 'apk-bytes' >"$apk"
subject="$(git log -1 --format=%s)"
sa_json='{"type":"service_account","private_key":"fake-key","client_email":"distro@example.iam.gserviceaccount.com"}'

run_distribute() {
  PATH="$fake_bin:$PATH" \
    DEMO_FIREBASE_CLI="$fake_bin/firebase" \
    TMPDIR="$tmp/distro" \
    FAKE_RECORD="$record" \
    GITHUB_SHA="abcdef1234567890abcdef1234567890abcdef12" \
    GITHUB_SERVER_URL="https://github.com" \
    GITHUB_REPOSITORY="example/repo" \
    GITHUB_RUN_ID="4242" \
    FIREBASE_ANDROID_APP_ID="1:123:android:abc" \
    FIREBASE_APP_DISTRIBUTION_SA_JSON="$sa_json" \
    bash scripts/ci/distribute_demo_apk.sh "$@"
}

rm -rf "$tmp/distro" "$record"
mkdir -p "$tmp/distro" "$record"
set +e
dist_out="$(GITHUB_EVENT_NAME=pull_request run_distribute "$apk" 2>&1)"
dist_status=$?
set -e
expect_eq "pull_request distribute exits 0" "$dist_status" 0
if ! grep -q 'Skipping distribution on a pull_request run.' <<<"$dist_out"; then
  echo "FAIL: distribute did not report the pull_request skip" >&2
  exit 1
fi
if [[ -f "$record/args" ]]; then
  echo "FAIL: pull_request called the firebase CLI" >&2
  exit 1
fi
echo "ok: pull_request distribute skips before the CLI"
if find "$tmp/distro" -type f | grep -q .; then
  echo "FAIL: pull_request skip left a temp file" >&2
  exit 1
fi
echo "ok: pull_request skip leaves no credentials file"

rm -rf "$record"
mkdir -p "$record"
set +e
dist_out="$(
  PATH="$fake_bin:$PATH" \
    TMPDIR="$tmp/distro" \
    FAKE_RECORD="$record" \
    GITHUB_EVENT_NAME=push \
    GITHUB_SHA="abcdef1234567890abcdef1234567890abcdef12" \
    GITHUB_SERVER_URL="https://github.com" \
    GITHUB_REPOSITORY="example/repo" \
    GITHUB_RUN_ID="4242" \
    FIREBASE_ANDROID_APP_ID="" \
    FIREBASE_APP_DISTRIBUTION_SA_JSON="$sa_json" \
    bash scripts/ci/distribute_demo_apk.sh "$apk" 2>&1
)"
dist_status=$?
set -e
expect_eq "missing app id distribute exits 0" "$dist_status" 0
if ! grep -q 'FIREBASE_ANDROID_APP_ID' <<<"$dist_out"; then
  echo "FAIL: missing app id skip did not name the secret" >&2
  exit 1
fi
if [[ -f "$record/args" ]]; then
  echo "FAIL: missing app id called the firebase CLI" >&2
  exit 1
fi
echo "ok: missing Firebase secret skips distribution"

rm -rf "$tmp/distro" "$record"
mkdir -p "$tmp/distro" "$record"
set +e
dist_out="$(GITHUB_EVENT_NAME=push run_distribute "$apk" 2>"$tmp/dist.err")"
dist_status=$?
set -e
expect_eq "distribute exits 0" "$dist_status" 0
if grep -q 'fake-key' "$tmp/dist.err" || grep -q 'fake-key' <<<"$dist_out"; then
  echo "FAIL: distribute output included the service account key" >&2
  exit 1
fi
echo "ok: distribute output does not include the service account key"
expect_eq "CLI command" "$(sed -n '1p' "$record/args")" "appdistribution:distribute"
expect_eq "distributed APK" "$(sed -n '2p' "$record/args")" "$apk"
if ! grep -q -- '--groups' "$record/args" || ! grep -q -- 'core-testers' "$record/args"; then
  echo "FAIL: distribute args missed --groups core-testers" >&2
  exit 1
fi
echo "ok: distribute args include --groups core-testers"
if ! grep -q -- '--app' "$record/args" || ! grep -q -- '--release-notes-file' "$record/args"; then
  echo "FAIL: distribute args missed --app or --release-notes-file" >&2
  exit 1
fi
echo "ok: distribute args include --app and --release-notes-file"
expect_eq "release notes" "$(cat "$record/notes")" \
  "$(printf '%s %s\n%s\n' "abcdef1" "$subject" "https://github.com/example/repo/actions/runs/4242")"
gac_path="$(cat "$record/gac")"
if [[ -e "$gac_path" ]]; then
  echo "FAIL: service account file was not deleted" >&2
  exit 1
fi
echo "ok: service account file is deleted after distribution"
if find "$tmp/distro" -type f | grep -q .; then
  echo "FAIL: distribute left a temp file" >&2
  exit 1
fi
echo "ok: distribute leaves no temp files"

rm -rf "$tmp/distro" "$record"
mkdir -p "$tmp/distro" "$record"
set +e
FAKE_NPX_STATUS=9 GITHUB_EVENT_NAME=push run_distribute "$apk" >"$tmp/fail.out" 2>"$tmp/fail.err"
fail_status=$?
set -e
expect_eq "firebase CLI failure fails the script" "$fail_status" 9
if [[ ! -f "$record/gac" ]]; then
  echo "FAIL: failing CLI call did not record the credentials path" >&2
  exit 1
fi
if [[ -e "$(cat "$record/gac")" ]]; then
  echo "FAIL: service account file survived a CLI failure" >&2
  exit 1
fi
echo "ok: service account file is deleted when the CLI fails"
if grep -q 'fake-key' "$tmp/fail.err" || grep -q 'fake-key' "$tmp/fail.out"; then
  echo "FAIL: CLI failure output included the service account key" >&2
  exit 1
fi
echo "ok: CLI failure output does not include the service account key"

rm -rf "$tmp/distro"
mkdir -p "$tmp/distro"
set +e
bad_json_out="$(
  PATH="$fake_bin:$PATH" \
    TMPDIR="$tmp/distro" \
    FAKE_RECORD="$record" \
    GITHUB_EVENT_NAME=push \
    GITHUB_SHA="abcdef1234567890abcdef1234567890abcdef12" \
    GITHUB_SERVER_URL="https://github.com" \
    GITHUB_REPOSITORY="example/repo" \
    GITHUB_RUN_ID="4242" \
    FIREBASE_ANDROID_APP_ID="1:123:android:abc" \
    FIREBASE_APP_DISTRIBUTION_SA_JSON='not-json' \
    bash scripts/ci/distribute_demo_apk.sh "$apk" 2>&1
)"
bad_json_status=$?
set -e
if [[ "$bad_json_status" -eq 0 ]]; then
  echo "FAIL: invalid service account JSON exited 0" >&2
  exit 1
fi
if ! grep -q 'not JSON' <<<"$bad_json_out"; then
  echo "FAIL: invalid service account JSON was not reported" >&2
  exit 1
fi
if grep -q 'not-json' <<<"$bad_json_out"; then
  echo "FAIL: invalid service account JSON was echoed" >&2
  exit 1
fi
echo "ok: invalid service account JSON fails without echoing it"
if find "$tmp/distro" -type f | grep -q .; then
  echo "FAIL: invalid service account JSON left a temp file" >&2
  exit 1
fi
echo "ok: invalid service account JSON leaves no temp file"

# FIREBASE_ANDROID_APP_ID must match the registered demo app. The secret
# value is never printed.
app_id="1:109314154382:android:856cbde1eb92ba234ccedf"
wrong_app_id="wrong-firebase-app-id-should-stay-hidden"
set +e
bad_app_out="$(FIREBASE_ANDROID_APP_ID="$wrong_app_id" bash scripts/ci/check_firebase_android_app_id.sh 2>&1)"
bad_app_status=$?
set -e
if [[ "$bad_app_status" -eq 0 ]]; then
  echo "FAIL: wrong FIREBASE_ANDROID_APP_ID exited 0" >&2
  exit 1
fi
if ! grep -q "$app_id" <<<"$bad_app_out"; then
  echo "FAIL: wrong app id did not name the registered demo app" >&2
  exit 1
fi
if grep -q "$wrong_app_id" <<<"$bad_app_out"; then
  echo "FAIL: wrong app id check printed the secret" >&2
  exit 1
fi
echo "ok: wrong Firebase app id fails without printing the secret"
good_app_out="$(FIREBASE_ANDROID_APP_ID="$app_id" bash scripts/ci/check_firebase_android_app_id.sh 2>&1)"
if ! grep -q 'registered demo Android app' <<<"$good_app_out"; then
  echo "FAIL: registered Firebase app id was rejected" >&2
  exit 1
fi
if grep -q "$app_id" <<<"$good_app_out"; then
  echo "FAIL: matching app id check printed the secret" >&2
  exit 1
fi
echo "ok: registered Firebase app id passes without printing the secret"
# shellcheck disable=SC2016
forbid "app id check does not echo the secret" \
  'echo .*\$FIREBASE_ANDROID_APP_ID|printf .*\$FIREBASE_ANDROID_APP_ID' \
  scripts/ci/check_firebase_android_app_id.sh

# google-services.json: Play and legacy clients stay. The .demo client
# is the registered Firebase app; a placeholder must not be committed.
python3 - <<'PY'
import json
import sys

data = json.load(open("android/app/google-services.json", encoding="utf-8"))
packages = []
demo_app_id = ""
for client in data["client"]:
    package = client["client_info"]["android_client_info"]["package_name"]
    packages.append(package)
    if package != "com.shradhaventures.temple.demo":
        continue
    demo_app_id = (client["client_info"].get("mobilesdk_app_id") or "").strip()
    key = ((client.get("api_key") or [{}])[0].get("current_key") or "").strip()
    if not demo_app_id or not key or demo_app_id.startswith(("REPLACE", "TODO", "CHANGEME", "your-")) or key.startswith(("REPLACE", "TODO", "CHANGEME", "your-")):
        sys.stderr.write("demo client is a placeholder\n")
        sys.exit(1)
if "com.shradhaventures.temple" not in packages:
    sys.stderr.write("Play client missing\n")
    sys.exit(1)
if "com.example.temple_app" not in packages:
    sys.stderr.write("legacy client missing\n")
    sys.exit(1)
if demo_app_id != "1:109314154382:android:856cbde1eb92ba234ccedf":
    sys.stderr.write("demo client app id does not match the registered app\n")
    sys.exit(1)
PY
echo "ok: Play google-services client remains"
echo "ok: demo google-services client is the registered app"

missing_json="$tmp/services-missing.json"
python3 - "$missing_json" <<'PY'
import json, sys
json.dump({"client": [{
    "client_info": {"mobilesdk_app_id": "play-app", "android_client_info": {"package_name": "com.shradhaventures.temple"}},
    "api_key": [{"current_key": "play-key"}],
}]}, open(sys.argv[1], "w"))
PY
set +e
missing_out="$(bash scripts/ci/check_demo_google_services.sh "$missing_json" 2>&1)"
missing_status=$?
set -e
if [[ "$missing_status" -eq 0 ]]; then
  echo "FAIL: missing demo client exited 0" >&2
  exit 1
fi
if ! grep -q 'com.shradhaventures.temple.demo' <<<"$missing_out"; then
  echo "FAIL: missing demo client did not name the package" >&2
  exit 1
fi
if ! grep -q 'mobilesdk_app_id' <<<"$missing_out" || ! grep -q 'current_key' <<<"$missing_out"; then
  echo "FAIL: missing demo client did not name the console fields" >&2
  exit 1
fi
if grep -q 'play-key' <<<"$missing_out" || grep -q 'play-app' <<<"$missing_out"; then
  echo "FAIL: google-services check printed an app id or key" >&2
  exit 1
fi
echo "ok: missing demo client fails without printing ids or keys"

present_json="$tmp/services-present.json"
python3 - "$present_json" <<'PY'
import json, sys
json.dump({"client": [
    {"client_info": {"mobilesdk_app_id": "play-app", "android_client_info": {"package_name": "com.shradhaventures.temple"}}, "api_key": [{"current_key": "play-key"}]},
    {"client_info": {"mobilesdk_app_id": "demo-app", "android_client_info": {"package_name": "com.shradhaventures.temple.demo"}}, "api_key": [{"current_key": "demo-key"}]},
]}, open(sys.argv[1], "w"))
PY
present_out="$(bash scripts/ci/check_demo_google_services.sh "$present_json" 2>&1)"
if ! grep -q 'demo google-services client is present' <<<"$present_out"; then
  echo "FAIL: present demo client was rejected" >&2
  exit 1
fi
if grep -q 'demo-key' <<<"$present_out" || grep -q 'demo-app' <<<"$present_out"; then
  echo "FAIL: present demo client printed an app id or key" >&2
  exit 1
fi
echo "ok: a real demo client passes without printing ids or keys"

runner="$(mktemp -d)"
printf 'store' >"$runner/demo-keystore.abc.p12"
printf 'sa' >"$runner/firebase-app-distro-sa.abc.json"
printf 'notes' >"$runner/demo-release-notes.abc.txt"
props_keep="$tmp/keep.properties"
printf 'keep\n' >"$props_keep"
RUNNER_TEMP="$runner" bash scripts/ci/cleanup_demo_signing.sh "" "$props_keep"
if [[ -e "$runner/demo-keystore.abc.p12" || -e "$runner/firebase-app-distro-sa.abc.json" || -e "$runner/demo-release-notes.abc.txt" ]]; then
  echo "FAIL: always-cleanup left a keystore or service account file" >&2
  exit 1
fi
if [[ -e "$props_keep" ]]; then
  echo "FAIL: cleanup left key.properties" >&2
  exit 1
fi
echo "ok: cleanup deletes keystore and service account files under RUNNER_TEMP"
rm -rf "$runner"

rm -rf "$tmp" "$fake_bin"
echo "Demo distribution guard checks passed."
