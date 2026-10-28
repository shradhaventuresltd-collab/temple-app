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
all_temples="$(mktemp)"
cat > "$all_temples" <<'EOF'
<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>
<hierarchy rotation="0">
  <node text="" content-desc="All Temples
992" resource-id="" class="android.view.View" package="com.example" clickable="true" bounds="[16,180][400,260]" />
  <node text="Home" content-desc="Home" resource-id="" class="android.view.View" package="com.example" clickable="true" bounds="[16,80][400,160]" />
</hierarchy>
EOF
if python3 tool/emulator/lib/ui.py find "$all_temples" --text-regex '^All Temples$' >/dev/null; then
  echo "All Temples with a count must not match a trailing anchor" >&2
  exit 1
fi
counted="$(python3 tool/emulator/lib/ui.py find "$all_temples" --text-regex '^All Temples')"
case "$counted" in
  "208 220 16 180 400 260 All Temples 992") ;;
  *) echo "All Temples count match was: ${counted}" >&2; exit 1 ;;
esac
rm -f "$all_temples"
rm -f "$card_fixture"

workflow=".github/workflows/emulator-app-test.yml"
if grep -Eq '<<:|&[A-Za-z]' "$workflow"; then
  echo "workflow uses a YAML anchor; GitHub Actions will not expand it" >&2
  exit 1
fi
# Full flows get 30 minutes; the flow-29 slices (<= 8 min each) get 20.
if [[ "$(grep -cE '^[[:space:]]*timeout-minutes: (20|30)$' "$workflow")" -ne "$(grep -c "run_one_flow.sh " "$workflow")" ]]; then
  echo "each flow step needs timeout-minutes: 20 or 30" >&2
  exit 1
fi
if [[ "$(grep -c '!cancelled() && steps.resolve-apk.outcome' "$workflow")" -ne "$(grep -c 'run_one_flow.sh ' "$workflow")" ]]; then
  echo "each flow step should use !cancelled() so a real cancellation skips it" >&2
  exit 1
fi
if grep -Eq 'if:.*always\(\).*resolve-apk' "$workflow"; then
  echo "flow steps must not use always(); a contained hang exits the step" >&2
  exit 1
fi
if ! grep -q 'select_labeled: gave up' tool/emulator/lib/common.sh; then
  echo "select_labeled must say when it hits its cap" >&2
  exit 1
fi
if ! grep -q 'picker scroll gave up' tool/emulator/flows/22_filter_combos_reset.sh; then
  echo "flow 22 should fail when the picker scroll hits its cap" >&2
  exit 1
fi
if grep -Eq '^[[:space:]]*(push|pull_request|schedule):' "$workflow"; then
  echo "workflow must trigger only on workflow_dispatch" >&2
  exit 1
fi
runner_steps="$(grep -c 'uses: reactivecircus/android-emulator-runner@' "$workflow")"
if [[ "$runner_steps" -ne $(( $(grep -c "run_one_flow.sh " "$workflow") + 1 )) ]]; then
  echo "expected $(( $(grep -c 'run_one_flow.sh ' "$workflow") + 1 )) emulator steps (snapshot plus one per flow), found ${runner_steps}" >&2
  exit 1
fi
if [[ "$(grep -F -c 'emulator-options: ${{ env.EMULATOR_OPTIONS }}' "$workflow")" -ne "$(grep -c 'run_one_flow.sh ' "$workflow")" ]]; then
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
  21-district-close-then-other-chip
  22-filter-combos-reset
  23-near-me-settings-roundtrip
  24-gallery-autoadvance-viewer
  25-directions-edge
  26-drawer-nav-stack
  27-offline-cold-start
  28-small-screen-rotation-overflow
  29a-home-browse-state
  29b-home-browse-district
  29c-home-browse-deity
  29d-drawer-all-state
  29e-drawer-all-district
  29f-drawer-all-deity
  29g-search-state
  29h-search-district
  29i-search-deity
  29j-sequences
  30a-drawer-bar-state
  30b-drawer-bar-district
  30c-drawer-bar-deity
  30d-near-me
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
if ! grep -q 'dump_scroll_sig' tool/emulator/lib/common.sh; then
  echo "filter option scroll should stop when the option text stops changing" >&2
  exit 1
fi
if grep -q 'cksum "$DUMP"' tool/emulator/lib/common.sh; then
  echo "picker scroll must not checksum the raw dump" >&2
  exit 1
fi
if ! grep -q 'FLOW_BUDGET=1140' tool/emulator/run_one_flow.sh; then
  echo "each flow should run under timeout 1140" >&2
  exit 1
fi
if ! grep -q 'timeout --kill-after=15 "$FLOW_BUDGET"' tool/emulator/run_one_flow.sh; then
  echo "the flow budget should be the timeout duration" >&2
  exit 1
fi
if ! awk '
  /flow_rc. -eq 124/ { block = 1 }
  block && failed == 0 && $0 ~ /screenrecord_stop/ { stopped = 1 }
  block && stopped && failed == 0 && $0 ~ /dump_logcat/ { dumped = 1 }
  block && dumped && failed == 0 && $0 ~ /network_on/ { restored = 1 }
  block && $0 ~ /record_fail "timeout"/ { failed = 1 }
  END { exit !(stopped && dumped && restored && failed) }
' tool/emulator/run_one_flow.sh; then
  echo "exit 124/137 must stop the recording, dump logcat, and restore the network from the wrapper" >&2
  exit 1
fi
if grep -q '^[[:space:]]*set -e$' tool/emulator/run_one_flow.sh; then
  echo "run_one_flow should not turn set -e back on around the timeout" >&2
  exit 1
fi
if ! grep -q 'log_installed_version' tool/emulator/run_one_flow.sh; then
  echo "each run should log the installed versionCode" >&2
  exit 1
fi
if ! grep -q "text-regex '\\^All Temples'" tool/emulator/lib/common.sh; then
  echo "open_browse should match All Temples without a trailing anchor" >&2
  exit 1
fi
if grep -q "text-regex '\\^All Temples\\$'" tool/emulator/lib/common.sh; then
  echo "open_browse must not require All Temples to be the whole content-desc" >&2
  exit 1
fi
if ! grep -q 'scroll_drawer_top' tool/emulator/lib/common.sh; then
  echo "a missed All Temples search should scroll the drawer back to the top" >&2
  exit 1
fi
# Content-desc audit. A trailing $ fails when that node's content-desc is
# "label\n<extra>" (flattened to "label extra").
# - All Temples is the only drawer tile with a trailing count.
# - Home and Licences have no count, so '^Home$' and '^Licences$' stay.
# - State / Deity / All districts are one Text. Option chips are "Name  N"
#   and the pickers allow "( +[0-9]+)?$". Show/Browse labels are one line.
if grep -n -E "text-regex ['\"]\\^All Temples\\$" \
  tool/emulator/lib/common.sh tool/emulator/flows/*.sh; then
  echo "a trailing \$ does not match All Temples content-desc" >&2
  exit 1
fi
if ! grep -q "text-regex '\\^Home\\$'" tool/emulator/flows/18_home_reselect.sh; then
  echo "Home has no trailing count; its anchor should stay" >&2
  exit 1
fi
if ! grep -q "text-regex '\\^Licences\\$'" tool/emulator/flows/13_licences.sh; then
  echo "Licences has no trailing count; its anchor should stay" >&2
  exit 1
fi
if ! awk '
  /open_browse\(\)/ { fn = 1 }
  fn && $0 ~ /scroll_drawer_until --text-regex/ { search = 1 }
  fn && search && $0 ~ /scroll_drawer_top/ { reset = 1 }
  fn && reset && $0 ~ /ui_find --text-regex '\''\^All Temples'\''/ { retry = 1 }
  fn && retry && $0 ~ /ui_back/ { closed = 1 }
  fn && $0 ~ /^}/ { exit }
  END { exit !(search && reset && retry && closed) }
' tool/emulator/lib/common.sh; then
  echo "open_browse must reset the drawer, retry All Temples, and close it" >&2
  exit 1
fi
if ! awk '
  /double tap/ { block = 1 }
  block && $0 ~ /scroll_drawer_top/ { top = 1 }
  block && top && $0 ~ /text-regex '\''\^Home\$'\''/ { wait = 1 }
  END { exit !(top && wait) }
' tool/emulator/flows/18_home_reselect.sh; then
  echo "flow 18 should bring the drawer back to Home before the double-tap" >&2
  exit 1
fi
if ! grep -q -- '-eq 124' tool/emulator/run_one_flow.sh; then
  echo "a timed-out flow should record FAIL on exit 124" >&2
  exit 1
fi
if ! grep -q "printf 'START %s" tool/emulator/run_one_flow.sh; then
  echo "run_one_flow should write a START marker" >&2
  exit 1
fi
if ! grep -q "printf 'DONE %s" tool/emulator/run_one_flow.sh; then
  echo "run_one_flow should write a DONE marker only after the flow exits" >&2
  exit 1
fi
if ! grep -q 'geo fix 78.1193 9.9195 0 8' tool/emulator/lib/common.sh; then
  echo "geo fix should include altitude and satellites" >&2
  exit 1
fi
if grep -q 'ui_back; ui_back' tool/emulator/flows/20_empty_and_back.sh; then
  echo "flow 20 must not send two backs after search" >&2
  exit 1
fi
if ! grep -qF "select_labeled '^Kerala( +[0-9]+)?$' STATE" tool/emulator/flows/19_rotation_state.sh; then
  echo "flow 19 should select Kerala in the STATE section and check the result" >&2
  exit 1
fi
if grep -q 'adb shell input tap' tool/emulator/flows/18_home_reselect.sh; then
  echo "flow 18 double-tap should use adb_shell_capped" >&2
  exit 1
fi
if ! grep -q 'adb_shell_capped 8 input tap' tool/emulator/flows/18_home_reselect.sh; then
  echo "flow 18 should cap the Home double-tap" >&2
  exit 1
fi
if ! grep -q 'adb_shell_capped 8 input tap' tool/emulator/flows/17_entry_matrix.sh; then
  echo "flow 17 double-tap should use adb_shell_capped" >&2
  exit 1
fi
if ! grep -q 'kerala_applied' tool/emulator/flows/17_entry_matrix.sh; then
  echo "flow 17 should check the State reset only after Kerala applies" >&2
  exit 1
fi
if ! grep -q 'adb_shell_capped 8 settings put secure show_ime_with_hard_keyboard' tool/emulator/run_one_flow.sh; then
  echo "IME settings should use the step cap" >&2
  exit 1
fi
if ! grep -q 'scroll_drawer_until --resource-id temple-list-search-field' tool/emulator/flows/17_entry_matrix.sh; then
  echo "flow 17 should scroll the drawer to the search field" >&2
  exit 1
fi
# Flow 29/30 slices: District is generated only after a State (by design),
# every case relaunches, and the district loader is waited out.
for lib in tool/emulator/flows/lib/filter_matrix.sh tool/emulator/flows/lib/filter_matrix_b.sh; do
  if ! grep -A3 '^fresh_home()' "$lib" | grep -q 'force_stop_app'; then
    echo "${lib} should relaunch the app for every case" >&2
    exit 1
  fi
  if grep -q 'xfail_step' "$lib"; then
    echo "${lib} must not xfail; hidden-by-design cases are not generated" >&2
    exit 1
  fi
done
if ! grep -q 'state:select "district:\$action"' tool/emulator/flows/lib/filter_matrix.sh; then
  echo "flow 29 district cases must start with state:select" >&2
  exit 1
fi
if ! grep -q 'wait_out_district_loader' tool/emulator/flows/lib/filter_matrix.sh; then
  echo "flow 29 should wait out the district loader" >&2
  exit 1
fi
if ! python3 - <<'PY'
from pathlib import Path
text = Path("tool/emulator/flows/28_small_screen_rotation_overflow.sh").read_text()
resize = text.find("wm size 720x1280")
browse = text.find("reach_browse")
accept = text.find("accept_policy_if_shown")
missing = text.find("no accept button")
if browse < 0 or resize < 0 or browse > resize:
    raise SystemExit("flow 28 should reach browse before resizing")
if accept < 0 or accept < resize:
    raise SystemExit("flow 28 should accept the policy after resizing")
if missing < 0:
    raise SystemExit("flow 28 should fail when no accept button is found")
PY
then
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
if [[ "$missing" -ne "${#flows[@]}" ]]; then
  echo "expected ${#flows[@]} missing-flow lines, found ${missing}" >&2
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
if [[ "$not_run" -ne "${#flows[@]}" ]]; then
  echo "expected ${#flows[@]} NOT RUN lines, found ${not_run}" >&2
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

started_dir="$(mktemp -d)"
: > "${started_dir}/results.txt"
for flow in "${flows[@]}"; do
  printf 'START %s\n' "$flow" >> "${started_dir}/results.txt"
  printf 'PASS %s: ok\n' "$flow" >> "${started_dir}/results.txt"
  if [[ "$flow" != "06-filters" ]]; then
    printf 'DONE %s\n' "$flow" >> "${started_dir}/results.txt"
  fi
done
if EMULATOR_ARTIFACTS="$started_dir" GITHUB_STEP_SUMMARY="${started_dir}/summary.md" \
  bash tool/emulator/summarize.sh >"${started_dir}/out" 2>&1; then
  echo "summarize.sh should fail a flow that has START and no DONE" >&2
  cat "${started_dir}/out" >&2
  exit 1
fi
if ! grep -qx 'FAIL 06-filters: timeout: started but did not finish' "${started_dir}/results.txt"; then
  echo "a flow with START and no DONE should be marked failed" >&2
  cat "${started_dir}/results.txt" >&2
  exit 1
fi
if grep -q '^FAIL 05-search:' "${started_dir}/results.txt"; then
  echo "a flow with START and DONE should stay green" >&2
  exit 1
fi
rm -rf "$started_dir"

finished_dir="$(mktemp -d)"
: > "${finished_dir}/results.txt"
for flow in "${flows[@]}"; do
  printf 'START %s\nPASS %s: ok\nDONE %s\n' "$flow" "$flow" "$flow" >> "${finished_dir}/results.txt"
done
if ! EMULATOR_ARTIFACTS="$finished_dir" GITHUB_STEP_SUMMARY="${finished_dir}/summary.md" \
  bash tool/emulator/summarize.sh >"${finished_dir}/out"; then
  echo "summarize.sh should pass when every flow has START and DONE" >&2
  cat "${finished_dir}/out" >&2
  exit 1
fi
rm -rf "$finished_dir"

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

# open_browse fallback, without a device. The home-button loop is skipped.
# A hit taps All Temples and leaves the drawer alone. A miss scrolls back
# to the top, looks once more, then closes so the next Home wait can run.
browse_dir="$(mktemp -d)"
(
  set -euo pipefail
  export EMULATOR_FLOW=18-home-reselect
  export EMULATOR_ARTIFACTS="$browse_dir"
  export EMULATOR_PACKAGE=com.example
  export OPEN_BROWSE_HOME_WAIT=0
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  ui_dump() { return 0; }
  ui_tap() { echo TAP >> "$browse_dir/log"; return 0; }
  ui_fling() { echo FLING >> "$browse_dir/log"; return 0; }
  ui_back() { echo BACK >> "$browse_dir/log"; return 0; }
  scroll_drawer_top() { echo TOP >> "$browse_dir/log"; return 0; }
  ui_find() {
    case "$*" in
      *home-browse-temples*) return 1 ;;
      *Browse*) return 1 ;;
      *"Open navigation menu"*) return 0 ;;
      *"All Temples"*)
        if [[ "${ALL_TEMPLES_VISIBLE:-}" == 1 ]]; then
          return 0
        fi
        return 1
        ;;
    esac
    return 1
  }
  scroll_drawer_until() {
    echo "UNTIL $*" >> "$browse_dir/log"
    case "$*" in
      *"All Temples$"*)
        echo "anchored All Temples pattern must not be used" >&2
        return 2
        ;;
      *"All Temples"*) ;;
      *)
        echo "unexpected drawer search: $*" >&2
        return 2
        ;;
    esac
    if [[ "${DRAWER_SEARCH_HITS:-}" == 1 ]]; then
      return 0
    fi
    return 1
  }

  : > "$browse_dir/log"
  DRAWER_SEARCH_HITS=1
  open_browse
  grep -qx 'UNTIL --text-regex ^All Temples' "$browse_dir/log"
  grep -qx 'TAP' "$browse_dir/log"
  if grep -qx 'TOP' "$browse_dir/log" || grep -qx 'BACK' "$browse_dir/log"; then
    echo "a found All Temples tile should not reset or close the drawer" >&2
    exit 1
  fi

  : > "$browse_dir/log"
  DRAWER_SEARCH_HITS=0
  ALL_TEMPLES_VISIBLE=1
  open_browse
  # Search miss, scroll to top, the retry finds the tile, tap. No close.
  grep -qx 'TOP' "$browse_dir/log"
  grep -qx 'TAP' "$browse_dir/log"
  if grep -qx 'BACK' "$browse_dir/log"; then
    echo "the retry should tap All Temples instead of closing the drawer" >&2
    exit 1
  fi

  : > "$browse_dir/log"
  DRAWER_SEARCH_HITS=0
  ALL_TEMPLES_VISIBLE=0
  if open_browse 2>"$browse_dir/err"; then
    echo "a drawer with no All Temples tile should fail" >&2
    exit 1
  fi
  awk '
    $0 == "UNTIL --text-regex ^All Temples" { until = 1 }
    until && $0 == "TOP" { top = 1 }
    top && $0 == "BACK" { back = 1 }
    END { exit !(until && top && back) }
  ' "$browse_dir/log"
)
rm -rf "$browse_dir"

# No emulator on this VM. A stub adb still exercises the versionCode log and
# the per-step shell cap (adb_shell_capped).
cap_dir="$(mktemp -d)"
stub_bin="$(mktemp -d)"
cat > "$stub_bin/adb" << 'EOF'
#!/bin/bash
printf '%s\n' "$*" >> "${STUB_ADB_LOG:?}"
if [[ "$1" == "shell" && "$2" == "sleep" ]]; then
  sleep "$3"
  exit 0
fi
if [[ "$1" == "shell" && "$2" == "dumpsys" ]]; then
  printf '    versionCode=6 targetSdk=34\n    versionName=1.0.0\n'
  exit 0
fi
exit 0
EOF
chmod +x "$stub_bin/adb"
(
  set -euo pipefail
  export STUB_ADB_LOG="$cap_dir/adb.log"
  export PATH="$stub_bin:$PATH"
  export EMULATOR_FLOW=18-home-reselect
  export EMULATOR_ARTIFACTS="$cap_dir"
  export EMULATOR_PACKAGE=com.example.temple
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  : > "$RESULTS"
  log_installed_version
  grep -qx 'VERSION 18-home-reselect versionCode=6 versionName=1.0.0' "$RESULTS"
  if adb_shell_capped 1 sleep 3; then
    echo "a 3s shell must hit the 1s step cap" >&2
    exit 1
  fi
)
rm -rf "$cap_dir" "$stub_bin"

echo "emulator self-test ok"
