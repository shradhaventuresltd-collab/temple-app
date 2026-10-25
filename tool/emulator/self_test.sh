#!/usr/bin/env bash
# Host-side checks for the emulator checklist. No device required.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

while IFS= read -r script; do
  bash -n "$script"
done < <(find tool/emulator -name '*.sh' -type f | sort)

# shellcheck disable=SC1091
source tool/emulator/resolve_apk.sh

expect_mode() {
  local want="$1"
  shift
  local got
  if ! got="$(classify_inputs "$@" 2>/tmp/classify.err)"; then
    echo "expected mode ${want} but classify failed: $(cat /tmp/classify.err)" >&2
    exit 1
  fi
  if [[ "$got" != "$want" ]]; then
    echo "expected ${want} got ${got}" >&2
    exit 1
  fi
}

expect_fail() {
  if classify_inputs "$@" >/tmp/classify.out 2>/tmp/classify.err; then
    echo "expected failure for: $*" >&2
    exit 1
  fi
}

expect_mode url "https://example.com/app.apk" "" "" ""
expect_mode artifact "" "123" "apk" ""
expect_mode build "" "" "" "main"
expect_fail "" "" "" ""
expect_fail "http://example.com/app.apk" "" "" ""
expect_fail "https://user:pass@example.com/app.apk" "" "" ""
expect_fail "" "123" "" ""
expect_fail "" "" "apk" ""
expect_fail "" "abc" "apk" ""
expect_fail "" "" "" "bad ref"

fixture="$(mktemp)"
cat > "$fixture" <<'EOF'
<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>
<hierarchy rotation="0">
  <node text="Kerala" content-desc="" resource-id="" class="android.widget.TextView" package="com.example" clickable="true" bounds="[40,200][300,280]" />
  <node text="Kerala  12" content-desc="" resource-id="" class="android.widget.TextView" package="com.example" clickable="true" bounds="[40,900][400,980]" />
  <node text="" content-desc="Choose a state" resource-id="filter-chip-state" class="android.view.View" package="com.example" clickable="true" bounds="[10,300][220,380]">
    <node text="State" content-desc="" resource-id="" class="android.widget.TextView" package="com.example" clickable="false" bounds="[20,320][120,360]" />
  </node>
  <node text="Deity" content-desc="Choose a deity" resource-id="" class="android.view.View" package="com.example" clickable="true" bounds="[240,300][400,380]" />
</hierarchy>
EOF

lower="$(python3 tool/emulator/lib/ui.py find "$fixture" --text-regex '^Kerala( +[0-9]+)?$' --min-top 500 --prefer lower)"
case "$lower" in
  "220 940 40 900 400 980 Kerala 12") ;;
  *) echo "lower Kerala match was: ${lower}" >&2; exit 1 ;;
esac

chip="$(python3 tool/emulator/lib/ui.py find "$fixture" --resource-id filter-chip-state --text-contains State)"
case "$chip" in
  "115 340 10 300 220 380 "*) ;;
  *) echo "chip match was: ${chip}" >&2; exit 1 ;;
esac

ids="$(python3 tool/emulator/lib/ui.py resource-ids "$fixture" --prefix filter-chip-)"
[[ "$ids" == "filter-chip-state" ]]

if python3 tool/emulator/lib/ui.py find "$fixture" --text-regex '^Not there$' >/dev/null; then
  echo "missing text should fail" >&2
  exit 1
fi

rm -f "$fixture"

card_fixture="$(mktemp)"
cat > "$card_fixture" <<'EOF'
<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>
<hierarchy rotation="0">
  <node text="" content-desc="All Temples" resource-id="" class="android.view.View" package="com.example" clickable="true" bounds="[0,40][200,100]" />
  <node text="" content-desc="Meenakshi Amman
Temple
Madurai" resource-id="temple-browse-card" class="android.view.View" package="com.example" clickable="true" bounds="[16,400][300,560]" />
</hierarchy>
EOF

card="$(python3 tool/emulator/lib/ui.py find "$card_fixture" --resource-id temple-browse-card --text-contains "Meenakshi Amman Temple")"
case "$card" in
  "158 480 16 400 300 560 Meenakshi Amman Temple Madurai") ;;
  *) echo "card match was: ${card}" >&2; exit 1 ;;
esac
temple_bit="$(python3 tool/emulator/lib/ui.py find "$card_fixture" --resource-id temple-browse-card --text-contains "Temple")"
case "$temple_bit" in
  "158 480 16 400 300 560 Meenakshi Amman Temple Madurai") ;;
  *) echo "partial Temple match was: ${temple_bit}" >&2; exit 1 ;;
esac
if python3 tool/emulator/lib/ui.py find "$card_fixture" --resource-id temple-browse-card --text-regex '.+Temple$' >/dev/null; then
  echo "a multi-line card label should not have to end with Temple" >&2
  exit 1
fi
if python3 tool/emulator/lib/ui.py find "$card_fixture" --resource-id temple-browse-card --text-contains "All Temples" >/dev/null; then
  echo "app bar All Temples should not match a temple card" >&2
  exit 1
fi
rm -f "$card_fixture"

workflow=".github/workflows/emulator-app-test.yml"
if grep -Eq '<<:|&[A-Za-z]' "$workflow"; then
  echo "workflow uses a YAML anchor; GitHub Actions will not expand it" >&2
  exit 1
fi
if grep -Eq '^[[:space:]]*(push|pull_request|schedule):' "$workflow"; then
  echo "workflow must trigger only on workflow_dispatch" >&2
  exit 1
fi
runner_steps="$(grep -c 'uses: reactivecircus/android-emulator-runner@' "$workflow")"
if [[ "$runner_steps" -ne 21 ]]; then
  echo "expected 21 emulator steps (snapshot plus 20 flows), found ${runner_steps}" >&2
  exit 1
fi
if [[ "$(grep -F -c 'emulator-options: ${{ env.EMULATOR_OPTIONS }}' "$workflow")" -ne 20 ]]; then
  echo "each flow step should read EMULATOR_OPTIONS from env" >&2
  exit 1
fi
if [[ "$(grep -F -c 'emulator-options: ${{ env.EMULATOR_SNAPSHOT_OPTIONS }}' "$workflow")" -ne 1 ]]; then
  echo "snapshot generation should be the only step with EMULATOR_SNAPSHOT_OPTIONS" >&2
  exit 1
fi
options_line="$(grep -F 'EMULATOR_OPTIONS:' "$workflow")"
if [[ "$options_line" != *"-no-snapshot-save"* || "$options_line" != *"-wipe-data"* ]]; then
  echo "flow boots should pass -no-snapshot-save and -wipe-data" >&2
  exit 1
fi
if [[ "$options_line" == *" -no-snapshot "* || "$options_line" == *" -no-snapshot-load"* ]]; then
  echo "flow boots should still be allowed to load a clean snapshot" >&2
  exit 1
fi
snapshot_line="$(grep -F 'EMULATOR_SNAPSHOT_OPTIONS:' "$workflow")"
if [[ "$snapshot_line" == *"-no-snapshot"* || "$snapshot_line" == *"-wipe-data"* ]]; then
  echo "snapshot generation must be allowed to save a clean image" >&2
  exit 1
fi
if ! grep -Fq 'script: echo "Generated AVD snapshot for caching."' "$workflow"; then
  echo "snapshot step should boot without installing an app" >&2
  exit 1
fi
if ! grep -Fq "if: steps.create-avd.outcome == 'success'" "$workflow"; then
  echo "AVD cache should be saved only after the clean snapshot boot" >&2
  exit 1
fi
if grep -Eq '^[[:space:]]*EMULATOR_AVD_CACHE_KEY: avd-30-x86_64-google_apis-emulator-app-test$' "$workflow"; then
  echo "AVD cache key should not be the snapshot that already contains an app" >&2
  exit 1
fi
if ! grep -Fq 'EMULATOR_AVD_CACHE_KEY: avd-30-x86_64-google_apis-emulator-app-test-clean' "$workflow"; then
  echo "AVD cache key should name the clean snapshot" >&2
  exit 1
fi
if [[ "$(grep -F -c 'EMULATOR_AVD_CACHE_KEY' "$workflow")" -lt 3 ]]; then
  echo "restore and save should share EMULATOR_AVD_CACHE_KEY" >&2
  exit 1
fi
if ! grep -q 'actions: read' "$workflow"; then
  echo "workflow token should be actions: read" >&2
  exit 1
fi
if ! grep -Fq 'EMULATOR_RESOLVE_OUTCOME: ${{ steps.plan.outcome }}' "$workflow"; then
  echo "summary step should receive steps.plan.outcome" >&2
  exit 1
fi

flows=(
  01-first-launch
  02-policy-gate
  03-force-update
  04-home
  05-search
  06-filters
  07-district
  08-list-detail
  09-photos
  10-directions
  11-near-me
  12-ads
  13-licences
  14-back-relaunch
  15-offline
  16-home-browse
  17-entry-matrix
  18-home-reselect
  19-rotation-state
  20-empty-and-back
)
for flow in "${flows[@]}"; do
  if ! grep -q "run_one_flow.sh ${flow} " "$workflow"; then
    echo "workflow is missing ${flow}" >&2
    exit 1
  fi
  if ! grep -q "$flow" tool/emulator/summarize.sh; then
    echo "summarize.sh is missing ${flow}" >&2
    exit 1
  fi
done
for script in tool/emulator/flows/*.sh; do
  base="$(basename "$script")"
  if ! grep -q "$base" "$workflow"; then
    echo "workflow is missing ${base}" >&2
    exit 1
  fi
done

locate_dir="$(mktemp -d)"
mkdir -p \
  "${locate_dir}/emulator-apk-download" \
  "${locate_dir}/build/app/outputs/flutter-apk"
printf 'PK' > "${locate_dir}/emulator-apk-download/app.apk"
printf 'PK' > "${locate_dir}/build/app/outputs/flutter-apk/app-release.apk"
printf 'PK' > "${locate_dir}/build/app/outputs/flutter-apk/app-debug.apk"
locate_out="$(mktemp)"
if ! GITHUB_WORKSPACE="$locate_dir" GITHUB_OUTPUT="$locate_out" \
  GITHUB_ENV="${locate_dir}/env" \
  bash tool/emulator/locate_apk.sh >/dev/null; then
  echo "locate_apk.sh failed" >&2
  exit 1
fi
if ! grep -q "apk=${locate_dir}/build/app/outputs/flutter-apk/app-debug.apk" "$locate_out"; then
  echo "locate_apk.sh did not prefer app-debug.apk" >&2
  cat "$locate_out" >&2
  exit 1
fi
rm -rf "$locate_dir"
rm -f "$locate_out"

if ! grep -Fq 'run-as "$PKG" mkdir -p "$prefs"' tool/emulator/lib/common.sh; then
  echo "prefs seed should mkdir /data/data/<pkg>/shared_prefs via run-as" >&2
  exit 1
fi
if ! grep -Fq '/data/data/${PKG}/shared_prefs' tool/emulator/lib/common.sh; then
  echo "prefs path should be absolute" >&2
  exit 1
fi

# Granted near-me records open-granted once. Location is off and Pick a
# state are already destinations, so that path must not wait again for
# "Sort by distance". The denied path may still wait for the consent sheet.
granted_near="$(awk '
  /^if ! open_near_me; then$/ { capture = 1 }
  capture { print }
  capture && /^force_stop_app$/ { exit }
' tool/emulator/flows/11_near_me.sh)"
if grep -q 'ui_wait 12 --text-contains "Sort by distance"' <<<"$granted_near"; then
  echo "granted near-me path must not wait again for Sort by distance" >&2
  exit 1
fi
if ! grep -q 'if near_me_destination; then' <<<"$granted_near"; then
  echo "granted near-me path should decide open-granted from near_me_destination" >&2
  exit 1
fi
if ! grep -q 'SECONDS - granted_start < 60' tool/emulator/flows/11_near_me.sh; then
  echo "granted near-me should keep waiting after the geo fix" >&2
  exit 1
fi
if ! awk '
  /pm grant/ { grant = 1 }
  grant && /push_emulator_geo/ { found = 1 }
  grant && /open_near_me\(\)/ { exit }
  END { exit !found }
' tool/emulator/flows/11_near_me.sh; then
  echo "geo fix should be sent again after permission is granted" >&2
  exit 1
fi
if ! grep -q 'cksum "$DUMP"' tool/emulator/lib/common.sh; then
  echo "filter option scroll should stop when the dump stops changing" >&2
  exit 1
fi
if ! grep -q 'ui_wait 12 --text-contains "Sort by distance"' tool/emulator/flows/11_near_me.sh; then
  echo "denied near-me path should still wait for the location consent sheet" >&2
  exit 1
fi

summary_dir="$(mktemp -d)"
if EMULATOR_ARTIFACTS="$summary_dir" GITHUB_STEP_SUMMARY="${summary_dir}/summary.md" \
  bash tool/emulator/summarize.sh >"${summary_dir}/fail.out" 2>&1; then
  echo "summarize.sh should fail when flows never reported" >&2
  cat "${summary_dir}/fail.out" >&2
  exit 1
fi
missing="$(grep -c ': missing:' "${summary_dir}/results.txt")"
if [[ "$missing" -ne 20 ]]; then
  echo "expected 20 missing-flow lines, found ${missing}" >&2
  exit 1
fi
: > "${summary_dir}/results.txt"
for flow in "${flows[@]}"; do
  printf 'PASS %s: ok\n' "$flow" >> "${summary_dir}/results.txt"
done
if ! EMULATOR_ARTIFACTS="$summary_dir" GITHUB_STEP_SUMMARY="${summary_dir}/summary.md" \
  bash tool/emulator/summarize.sh; then
  echo "summarize.sh should pass once every flow has a PASS" >&2
  exit 1
fi

printf 'XFAIL 06-filters: force-stop-keeps-filter: filters live in memory and reset after force-stop\n' >> "${summary_dir}/results.txt"
if ! EMULATOR_ARTIFACTS="$summary_dir" GITHUB_STEP_SUMMARY="${summary_dir}/summary.md" \
  bash tool/emulator/summarize.sh >"${summary_dir}/xfail.out"; then
  echo "summarize.sh should pass when the only extra line is XFAIL" >&2
  cat "${summary_dir}/xfail.out" >&2
  exit 1
fi
if ! grep -q 'expected failures' "${summary_dir}/xfail.out"; then
  echo "summary should mention expected failures" >&2
  exit 1
fi

printf 'FAIL 05-search: krishna: typed text did not match\n' >> "${summary_dir}/results.txt"
if EMULATOR_ARTIFACTS="$summary_dir" GITHUB_STEP_SUMMARY="${summary_dir}/summary.md" \
  bash tool/emulator/summarize.sh >"${summary_dir}/real-fail.out" 2>&1; then
  echo "summarize.sh should fail when a FAIL line is present" >&2
  exit 1
fi
rm -rf "$summary_dir"

not_run_dir="$(mktemp -d)"
if ! EMULATOR_ARTIFACTS="$not_run_dir" EMULATOR_RESOLVE_OUTCOME=failure \
  GITHUB_STEP_SUMMARY="${not_run_dir}/summary.md" \
  bash tool/emulator/summarize.sh >"${not_run_dir}/out"; then
  echo "summarize.sh should exit 0 when APK resolution failed" >&2
  cat "${not_run_dir}/out" >&2
  exit 1
fi
not_run="$(grep -c '^NOT RUN ' "${not_run_dir}/results.txt")"
if [[ "$not_run" -ne 20 ]]; then
  echo "expected 20 NOT RUN lines, found ${not_run}" >&2
  exit 1
fi
if grep -q '^FAIL ' "${not_run_dir}/results.txt"; then
  echo "NOT RUN flows should stay out of the FAIL count" >&2
  exit 1
fi
if ! grep -qx 'NOT RUN 05-search' "${not_run_dir}/results.txt"; then
  echo "NOT RUN line should be 'NOT RUN <flow>'" >&2
  exit 1
fi
rm -rf "$not_run_dir"

step_dir="$(mktemp -d)"
: > "${step_dir}/results.txt"
for flow in "${flows[@]}"; do
  printf 'PASS %s: ok\n' "$flow" >> "${step_dir}/results.txt"
done
printf 'NOT RUN 06-filters: combined-state: state-select did not apply a state\n' >> "${step_dir}/results.txt"
if ! EMULATOR_ARTIFACTS="$step_dir" GITHUB_STEP_SUMMARY="${step_dir}/summary.md" \
  bash tool/emulator/summarize.sh >"${step_dir}/out"; then
  echo "a skipped step should not fail the summary" >&2
  cat "${step_dir}/out" >&2
  exit 1
fi
if grep -q 'FAIL 06-filters: missing' "${step_dir}/results.txt"; then
  echo "a skipped step should count as the flow reporting" >&2
  exit 1
fi
rm -rf "$step_dir"

only_skip_dir="$(mktemp -d)"
: > "${only_skip_dir}/results.txt"
for flow in "${flows[@]}"; do
  if [[ "$flow" == "06-filters" ]]; then
    printf 'NOT RUN 06-filters: combined-state: state-select did not apply a state\n' >> "${only_skip_dir}/results.txt"
  else
    printf 'PASS %s: ok\n' "$flow" >> "${only_skip_dir}/results.txt"
  fi
done
if EMULATOR_ARTIFACTS="$only_skip_dir" GITHUB_STEP_SUMMARY="${only_skip_dir}/summary.md" \
  bash tool/emulator/summarize.sh >"${only_skip_dir}/out" 2>&1; then
  echo "a flow with no PASS should fail the summary" >&2
  cat "${only_skip_dir}/out" >&2
  exit 1
fi
if ! grep -qx 'FAIL 06-filters: missing: flow did not pass any step' "${only_skip_dir}/results.txt"; then
  echo "a flow with only NOT RUN steps should be marked failed" >&2
  cat "${only_skip_dir}/results.txt" >&2
  exit 1
fi
if grep -q '^FAIL 05-search:' "${only_skip_dir}/results.txt"; then
  echo "flows that passed should stay green" >&2
  exit 1
fi
rm -rf "$only_skip_dir"

fail_only_dir="$(mktemp -d)"
: > "${fail_only_dir}/results.txt"
for flow in "${flows[@]}"; do
  if [[ "$flow" == "05-search" ]]; then
    printf 'FAIL 05-search: krishna: typed text did not match\n' >> "${fail_only_dir}/results.txt"
  else
    printf 'PASS %s: ok\n' "$flow" >> "${fail_only_dir}/results.txt"
  fi
done
if EMULATOR_ARTIFACTS="$fail_only_dir" GITHUB_STEP_SUMMARY="${fail_only_dir}/summary.md" \
  bash tool/emulator/summarize.sh >"${fail_only_dir}/out" 2>&1; then
  echo "summarize.sh should fail when a flow has FAIL and no PASS" >&2
  exit 1
fi
if grep -q 'did not pass any step' "${fail_only_dir}/results.txt"; then
  echo "a flow that already failed should not gain a second missing line" >&2
  exit 1
fi
rm -rf "$fail_only_dir"

skip_dir="$(mktemp -d)"
(
  set -euo pipefail
  export EMULATOR_FLOW=06-filters
  export EMULATOR_ARTIFACTS="$skip_dir"
  export EMULATOR_PACKAGE=com.shradhaventures.temple
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  step_shot() { :; }
  dismiss_blockers() { return 0; }
  eval "$(sed -n '/^skip_if_failed()/,/^}/p' tool/emulator/flows/06_filters.sh)"
  : > "$RESULTS"

  skip_step combined-state "state-select did not apply a state"
  grep -q '^FAIL 06-filters: combined-state: no failed prerequisite: state-select did not apply a state$' "$RESULTS"
  if grep -q '^NOT RUN ' "$RESULTS"; then
    echo "skip_step without a failed prerequisite must not record NOT RUN" >&2
    exit 1
  fi

  : > "$RESULTS"
  skip_if_failed combined-chips "no combined filter was applied" state-select
  grep -q '^FAIL 06-filters: combined-chips: no combined filter was applied$' "$RESULTS"
  if grep -q '^NOT RUN ' "$RESULTS"; then
    echo "skip_if_failed without a prerequisite FAIL must not record NOT RUN" >&2
    exit 1
  fi

  printf 'FAIL 06-filters: state-select: could not find Kerala\n' >> "$RESULTS"
  skip_if_failed combined-state "state-select did not apply a state" state-open state-reopen state-select
  grep -q '^NOT RUN 06-filters: combined-state: state-select did not apply a state$' "$RESULTS"
)
rm -rf "$skip_dir"

echo "emulator self-test ok"
