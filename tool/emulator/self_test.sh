#!/usr/bin/env bash
# Host-side checks for the emulator checklist. No device required.
set -euo pipefail

# One count for every check that can fail this script, including checks
# that run inside a subshell. Append so a subshell's passes are kept.
PASS_FILE="$(mktemp)"
pass() { printf '.\n' >> "$PASS_FILE"; }

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
  pass
  if [[ "$got" != "$want" ]]; then
    echo "expected ${want} got ${got}" >&2
    exit 1
  fi
  pass
}

expect_fail() {
  if classify_inputs "$@" >/tmp/classify.out 2>/tmp/classify.err; then
    echo "expected failure for: $*" >&2
    exit 1
  fi
  pass
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
pass

chip="$(python3 tool/emulator/lib/ui.py find "$fixture" --resource-id filter-chip-state --text-contains State)"
case "$chip" in
  "115 340 10 300 220 380 "*) ;;
  *) echo "chip match was: ${chip}" >&2; exit 1 ;;
esac
pass

ids="$(python3 tool/emulator/lib/ui.py resource-ids "$fixture" --prefix filter-chip-)"
[[ "$ids" == "filter-chip-state" ]]

if python3 tool/emulator/lib/ui.py find "$fixture" --text-regex '^Not there$' >/dev/null; then
  echo "missing text should fail" >&2
  exit 1
fi
pass

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
pass
temple_bit="$(python3 tool/emulator/lib/ui.py find "$card_fixture" --resource-id temple-browse-card --text-contains "Temple")"
case "$temple_bit" in
  "158 480 16 400 300 560 Meenakshi Amman Temple Madurai") ;;
  *) echo "partial Temple match was: ${temple_bit}" >&2; exit 1 ;;
esac
pass
if python3 tool/emulator/lib/ui.py find "$card_fixture" --resource-id temple-browse-card --text-regex '.+Temple$' >/dev/null; then
  echo "a multi-line card label should not have to end with Temple" >&2
  exit 1
fi
pass
if python3 tool/emulator/lib/ui.py find "$card_fixture" --resource-id temple-browse-card --text-contains "All Temples" >/dev/null; then
  echo "app bar All Temples should not match a temple card" >&2
  exit 1
fi
pass
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
pass
counted="$(python3 tool/emulator/lib/ui.py find "$all_temples" --text-regex '^All Temples')"
case "$counted" in
  "208 220 16 180 400 260 All Temples 992") ;;
  *) echo "All Temples count match was: ${counted}" >&2; exit 1 ;;
esac
pass
rm -f "$all_temples"
rm -f "$card_fixture"

workflow=".github/workflows/emulator-app-test.yml"
if grep -Eq '<<:|&[A-Za-z]' "$workflow"; then
  echo "workflow uses a YAML anchor; GitHub Actions will not expand it" >&2
  exit 1
fi
pass
# Full flows get 30 minutes; the flow-29 slices (<= 8 min each) get 20.
if [[ "$(grep -cE '^[[:space:]]*timeout-minutes: (20|30)$' "$workflow")" -ne "$(grep -c "run_one_flow.sh " "$workflow")" ]]; then
  echo "each flow step needs timeout-minutes: 20 or 30" >&2
  exit 1
fi
pass
if [[ "$(grep -c '!cancelled() && steps.resolve-apk.outcome' "$workflow")" -ne "$(grep -c 'run_one_flow.sh ' "$workflow")" ]]; then
  echo "each flow step should use !cancelled() so a real cancellation skips it" >&2
  exit 1
fi
pass
if grep -Eq 'if:.*always\(\).*resolve-apk' "$workflow"; then
  echo "flow steps must not use always(); a contained hang exits the step" >&2
  exit 1
fi
pass
if ! grep -q 'select_labeled: gave up' tool/emulator/lib/common.sh; then
  echo "select_labeled must say when it hits its cap" >&2
  exit 1
fi
pass
if ! grep -q 'picker scroll gave up' tool/emulator/flows/22_filter_combos_reset.sh; then
  echo "flow 22 should fail when the picker scroll hits its cap" >&2
  exit 1
fi
pass
if grep -Eq '^[[:space:]]*(push|pull_request|schedule):' "$workflow"; then
  echo "workflow must trigger only on workflow_dispatch" >&2
  exit 1
fi
pass
runner_steps="$(grep -c 'uses: reactivecircus/android-emulator-runner@' "$workflow")"
if [[ "$runner_steps" -ne $(( $(grep -c "run_one_flow.sh " "$workflow") + 1 )) ]]; then
  echo "expected $(( $(grep -c 'run_one_flow.sh ' "$workflow") + 1 )) emulator steps (snapshot plus one per flow), found ${runner_steps}" >&2
  exit 1
fi
pass
if [[ "$(grep -F -c 'emulator-options: ${{ env.EMULATOR_OPTIONS }}' "$workflow")" -ne "$(grep -c 'run_one_flow.sh ' "$workflow")" ]]; then
  echo "each flow step should read EMULATOR_OPTIONS from env" >&2
  exit 1
fi
pass
if [[ "$(grep -F -c 'emulator-options: ${{ env.EMULATOR_SNAPSHOT_OPTIONS }}' "$workflow")" -ne 1 ]]; then
  echo "snapshot generation should be the only step with EMULATOR_SNAPSHOT_OPTIONS" >&2
  exit 1
fi
pass
options_line="$(grep -F 'EMULATOR_OPTIONS:' "$workflow")"
if [[ "$options_line" != *"-no-snapshot-save"* || "$options_line" != *"-wipe-data"* ]]; then
  echo "flow boots should pass -no-snapshot-save and -wipe-data" >&2
  exit 1
fi
pass
if [[ "$options_line" == *" -no-snapshot "* || "$options_line" == *" -no-snapshot-load"* ]]; then
  echo "flow boots should still be allowed to load a clean snapshot" >&2
  exit 1
fi
pass
snapshot_line="$(grep -F 'EMULATOR_SNAPSHOT_OPTIONS:' "$workflow")"
if [[ "$snapshot_line" == *"-no-snapshot"* || "$snapshot_line" == *"-wipe-data"* ]]; then
  echo "snapshot generation must be allowed to save a clean image" >&2
  exit 1
fi
pass
if ! grep -Fq 'script: echo "Generated AVD snapshot for caching."' "$workflow"; then
  echo "snapshot step should boot without installing an app" >&2
  exit 1
fi
pass
if ! grep -Fq "if: steps.create-avd.outcome == 'success'" "$workflow"; then
  echo "AVD cache should be saved only after the clean snapshot boot" >&2
  exit 1
fi
pass
if grep -Eq '^[[:space:]]*EMULATOR_AVD_CACHE_KEY: avd-30-x86_64-google_apis-emulator-app-test$' "$workflow"; then
  echo "AVD cache key should not be the snapshot that already contains an app" >&2
  exit 1
fi
pass
if ! grep -Fq 'EMULATOR_AVD_CACHE_KEY: avd-30-x86_64-google_apis-emulator-app-test-clean' "$workflow"; then
  echo "AVD cache key should name the clean snapshot" >&2
  exit 1
fi
pass
if [[ "$(grep -F -c 'EMULATOR_AVD_CACHE_KEY' "$workflow")" -lt 3 ]]; then
  echo "restore and save should share EMULATOR_AVD_CACHE_KEY" >&2
  exit 1
fi
pass
if ! grep -q 'actions: read' "$workflow"; then
  echo "workflow token should be actions: read" >&2
  exit 1
fi
pass
if ! grep -Fq 'EMULATOR_RESOLVE_OUTCOME: ${{ steps.plan.outcome }}' "$workflow"; then
  echo "summary step should receive steps.plan.outcome" >&2
  exit 1
fi
pass

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
  17a-entry-matrix-home
  17b-entry-matrix-drawer
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
  pass
  if ! grep -q "$flow" tool/emulator/summarize.sh; then
    echo "summarize.sh is missing ${flow}" >&2
    exit 1
  fi
  pass
done
for script in tool/emulator/flows/*.sh; do
  base="$(basename "$script")"
  if ! grep -q "$base" "$workflow"; then
    echo "workflow is missing ${base}" >&2
    exit 1
  fi
  pass
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
pass
if ! grep -q "apk=${locate_dir}/build/app/outputs/flutter-apk/app-debug.apk" "$locate_out"; then
  echo "locate_apk.sh did not prefer app-debug.apk" >&2
  cat "$locate_out" >&2
  exit 1
fi
pass
rm -rf "$locate_dir"
rm -f "$locate_out"

if ! grep -Fq 'run-as "$PKG" mkdir -p "$prefs"' tool/emulator/lib/common.sh; then
  echo "prefs seed should mkdir /data/data/<pkg>/shared_prefs via run-as" >&2
  exit 1
fi
pass
if ! grep -Fq '/data/data/${PKG}/shared_prefs' tool/emulator/lib/common.sh; then
  echo "prefs path should be absolute" >&2
  exit 1
fi
pass

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
pass
if ! grep -q 'if near_me_destination; then' <<<"$granted_near"; then
  echo "granted near-me path should decide open-granted from near_me_destination" >&2
  exit 1
fi
pass
if ! grep -q 'SECONDS - granted_start < 60' tool/emulator/flows/11_near_me.sh; then
  echo "granted near-me should keep waiting after the geo fix" >&2
  exit 1
fi
pass
if ! awk '
  /pm grant/ { grant = 1 }
  grant && /push_emulator_geo/ { found = 1 }
  grant && /open_near_me\(\)/ { exit }
  END { exit !found }
' tool/emulator/flows/11_near_me.sh; then
  echo "geo fix should be sent again after permission is granted" >&2
  exit 1
fi
pass
if ! grep -q 'dump_scroll_sig' tool/emulator/lib/common.sh; then
  echo "filter option scroll should stop when the option text stops changing" >&2
  exit 1
fi
pass
if grep -q 'cksum "$DUMP"' tool/emulator/lib/common.sh; then
  echo "picker scroll must not checksum the raw dump" >&2
  exit 1
fi
pass
if ! grep -q 'FLOW_BUDGET=1140' tool/emulator/run_one_flow.sh; then
  echo "each flow should run under timeout 1140" >&2
  exit 1
fi
pass
if ! grep -q 'timeout --kill-after=15 "$FLOW_BUDGET"' tool/emulator/run_one_flow.sh; then
  echo "the flow budget should be the timeout duration" >&2
  exit 1
fi
pass
if ! grep -q 'export FLOW_START_EPOCH=' tool/emulator/run_one_flow.sh; then
  echo "the 1140s timer must export FLOW_START_EPOCH for flow_over" >&2
  exit 1
fi
pass
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
pass
if grep -q '^[[:space:]]*set -e$' tool/emulator/run_one_flow.sh; then
  echo "run_one_flow should not turn set -e back on around the timeout" >&2
  exit 1
fi
pass
if ! grep -q 'log_installed_version' tool/emulator/run_one_flow.sh; then
  echo "each run should log the installed versionCode" >&2
  exit 1
fi
pass
if ! grep -q "text-regex '\\^All Temples'" tool/emulator/lib/common.sh; then
  echo "open_browse should match All Temples without a trailing anchor" >&2
  exit 1
fi
pass
if grep -q "text-regex '\\^All Temples\\$'" tool/emulator/lib/common.sh; then
  echo "open_browse must not require All Temples to be the whole content-desc" >&2
  exit 1
fi
pass
if ! grep -q 'scroll_drawer_top' tool/emulator/lib/common.sh; then
  echo "a missed All Temples search should scroll the drawer back to the top" >&2
  exit 1
fi
pass
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
pass
if ! grep -q "text-regex '\\^Home\\$'" tool/emulator/flows/18_home_reselect.sh; then
  echo "Home has no trailing count; its anchor should stay" >&2
  exit 1
fi
pass
if ! grep -q "text-regex '\\^Licences\\$'" tool/emulator/flows/13_licences.sh; then
  echo "Licences has no trailing count; its anchor should stay" >&2
  exit 1
fi
pass
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
pass
if ! awk '
  /double tap/ { block = 1 }
  block && $0 ~ /scroll_drawer_top/ { top = 1 }
  block && top && $0 ~ /text-regex '\''\^Home\$'\''/ { wait = 1 }
  END { exit !(top && wait) }
' tool/emulator/flows/18_home_reselect.sh; then
  echo "flow 18 should bring the drawer back to Home before the double-tap" >&2
  exit 1
fi
pass
if ! grep -q -- '-eq 124' tool/emulator/run_one_flow.sh; then
  echo "a timed-out flow should record FAIL on exit 124" >&2
  exit 1
fi
pass
if ! grep -q "printf 'START %s" tool/emulator/run_one_flow.sh; then
  echo "run_one_flow should write a START marker" >&2
  exit 1
fi
pass
if ! grep -q "printf 'DONE %s" tool/emulator/run_one_flow.sh; then
  echo "run_one_flow should write a DONE marker only after the flow exits" >&2
  exit 1
fi
pass
if ! grep -q 'geo fix 78.1193 9.9195 0 8' tool/emulator/lib/common.sh; then
  echo "geo fix should include altitude and satellites" >&2
  exit 1
fi
pass
if grep -q 'ui_back; ui_back' tool/emulator/flows/20_empty_and_back.sh; then
  echo "flow 20 must not send two backs after search" >&2
  exit 1
fi
pass
if ! grep -qF "select_labeled '^Kerala( +[0-9]+)?$' STATE" tool/emulator/flows/19_rotation_state.sh; then
  echo "flow 19 should select Kerala in the STATE section and check the result" >&2
  exit 1
fi
pass
if grep -q 'adb shell input tap' tool/emulator/flows/18_home_reselect.sh; then
  echo "flow 18 double-tap should use adb_shell_capped" >&2
  exit 1
fi
pass
if ! grep -q 'adb_shell_capped 8 input tap' tool/emulator/flows/18_home_reselect.sh; then
  echo "flow 18 should cap the Home double-tap" >&2
  exit 1
fi
pass
if ! grep -q 'adb_shell_capped 8 input tap' tool/emulator/flows/lib/entry_matrix.sh; then
  echo "flow 17 double-tap should use adb_shell_capped" >&2
  exit 1
fi
pass
if ! grep -q 'kerala_applied' tool/emulator/flows/lib/entry_matrix.sh; then
  echo "flow 17 should check the State reset only after Kerala applies" >&2
  exit 1
fi
pass
if ! grep -q 'adb_shell_capped 8 settings put secure show_ime_with_hard_keyboard' tool/emulator/run_one_flow.sh; then
  echo "IME settings should use the step cap" >&2
  exit 1
fi
pass
if ! grep -q 'scroll_drawer_until --resource-id temple-list-search-field' tool/emulator/flows/lib/entry_matrix.sh; then
  echo "flow 17 should scroll the drawer to the search field" >&2
  exit 1
fi
pass
# Flow 29/30 slices: District is generated only after a State (by design),
# every case relaunches, and the district loader is waited out.
for lib in tool/emulator/flows/lib/filter_matrix.sh tool/emulator/flows/lib/filter_matrix_b.sh; do
  if ! grep -A3 '^fresh_home()' "$lib" | grep -q 'force_stop_app'; then
    echo "${lib} should relaunch the app for every case" >&2
    exit 1
  fi
  pass
  if grep -q 'xfail_step' "$lib"; then
    echo "${lib} must not xfail; hidden-by-design cases are not generated" >&2
    exit 1
  fi
  pass
done
if ! grep -q 'state:select "district:\$action"' tool/emulator/flows/lib/filter_matrix.sh; then
  echo "flow 29 district cases must start with state:select" >&2
  exit 1
fi
pass
if ! grep -q 'wait_out_district_loader' tool/emulator/flows/lib/filter_matrix.sh; then
  echo "flow 29 should wait out the district loader" >&2
  exit 1
fi
pass
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
pass
if ! grep -q 'ui_wait 12 --text-contains "Sort by distance"' tool/emulator/flows/11_near_me.sh; then
  echo "denied near-me path should still wait for the location consent sheet" >&2
  exit 1
fi
pass

summary_dir="$(mktemp -d)"
if EMULATOR_ARTIFACTS="$summary_dir" GITHUB_STEP_SUMMARY="${summary_dir}/summary.md" \
  bash tool/emulator/summarize.sh >"${summary_dir}/fail.out" 2>&1; then
  echo "summarize.sh should fail when flows never reported" >&2
  cat "${summary_dir}/fail.out" >&2
  exit 1
fi
pass
missing="$(grep -c ': missing:' "${summary_dir}/results.txt")"
if [[ "$missing" -ne "${#flows[@]}" ]]; then
  echo "expected ${#flows[@]} missing-flow lines, found ${missing}" >&2
  exit 1
fi
pass
: > "${summary_dir}/results.txt"
for flow in "${flows[@]}"; do
  printf 'PASS %s: ok\n' "$flow" >> "${summary_dir}/results.txt"
done
if ! EMULATOR_ARTIFACTS="$summary_dir" GITHUB_STEP_SUMMARY="${summary_dir}/summary.md" \
  bash tool/emulator/summarize.sh; then
  echo "summarize.sh should pass once every flow has a PASS" >&2
  exit 1
fi
pass

printf 'XFAIL 06-filters: force-stop-keeps-filter: filters live in memory and reset after force-stop\n' >> "${summary_dir}/results.txt"
if ! EMULATOR_ARTIFACTS="$summary_dir" GITHUB_STEP_SUMMARY="${summary_dir}/summary.md" \
  bash tool/emulator/summarize.sh >"${summary_dir}/xfail.out"; then
  echo "summarize.sh should pass when the only extra line is XFAIL" >&2
  cat "${summary_dir}/xfail.out" >&2
  exit 1
fi
pass
if ! grep -q 'expected failures' "${summary_dir}/xfail.out"; then
  echo "summary should mention expected failures" >&2
  exit 1
fi
pass

printf 'FAIL 05-search: krishna: typed text did not match\n' >> "${summary_dir}/results.txt"
if EMULATOR_ARTIFACTS="$summary_dir" GITHUB_STEP_SUMMARY="${summary_dir}/summary.md" \
  bash tool/emulator/summarize.sh >"${summary_dir}/real-fail.out" 2>&1; then
  echo "summarize.sh should fail when a FAIL line is present" >&2
  exit 1
fi
pass
rm -rf "$summary_dir"

not_run_dir="$(mktemp -d)"
if ! EMULATOR_ARTIFACTS="$not_run_dir" EMULATOR_RESOLVE_OUTCOME=failure \
  GITHUB_STEP_SUMMARY="${not_run_dir}/summary.md" \
  bash tool/emulator/summarize.sh >"${not_run_dir}/out"; then
  echo "summarize.sh should exit 0 when APK resolution failed" >&2
  cat "${not_run_dir}/out" >&2
  exit 1
fi
pass
not_run="$(grep -c '^NOT RUN ' "${not_run_dir}/results.txt")"
if [[ "$not_run" -ne "${#flows[@]}" ]]; then
  echo "expected ${#flows[@]} NOT RUN lines, found ${not_run}" >&2
  exit 1
fi
pass
if grep -q '^FAIL ' "${not_run_dir}/results.txt"; then
  echo "NOT RUN flows should stay out of the FAIL count" >&2
  exit 1
fi
pass
if ! grep -qx 'NOT RUN 05-search' "${not_run_dir}/results.txt"; then
  echo "NOT RUN line should be 'NOT RUN <flow>'" >&2
  exit 1
fi
pass
rm -rf "$not_run_dir"

step_dir="$(mktemp -d)"
: > "${step_dir}/results.txt"
for flow in "${flows[@]}"; do
  printf 'PASS %s: ok\n' "$flow" >> "${step_dir}/results.txt"
done
printf 'NOT RUN 06-filters: combined-state: state-select did not apply a state\n' >> "${step_dir}/results.txt"
if EMULATOR_ARTIFACTS="$step_dir" GITHUB_STEP_SUMMARY="${step_dir}/summary.md" \
  bash tool/emulator/summarize.sh >"${step_dir}/out" 2>&1; then
  echo "a NOT RUN step with no FAIL must fail the summary (zero NOT RUN rule)" >&2
  cat "${step_dir}/out" >&2
  exit 1
fi
pass
if grep -q 'FAIL 06-filters: missing' "${step_dir}/results.txt"; then
  echo "a skipped step should count as the flow reporting" >&2
  exit 1
fi
pass
rm -rf "$step_dir"

# A green run with a by-design note (30a: no district chip without a
# state) passes; a flow-budget stop is a FAIL with its NOT RUN behind it.
info_dir="$(mktemp -d)"
: > "${info_dir}/results.txt"
for flow in "${flows[@]}"; do
  printf 'PASS %s: ok\n' "$flow" >> "${info_dir}/results.txt"
done
printf 'INFO 30a-drawer-bar-state: drawer_bar-state-dismiss-empty-then-district: district chip not offered with no state applied (by design)\n' >> "${info_dir}/results.txt"
if ! EMULATOR_ARTIFACTS="$info_dir" GITHUB_STEP_SUMMARY="${info_dir}/summary.md" \
  bash tool/emulator/summarize.sh >"${info_dir}/out" 2>&1; then
  echo "all PASS plus a by-design INFO line must be green" >&2
  cat "${info_dir}/out" >&2
  exit 1
fi
pass
grep -q ', 0 not run, 0 skipped, 1 notes\.' "${info_dir}/out" || { echo "INFO should be counted as a note: $(cat "${info_dir}/out")" >&2; exit 1; }
pass
# shellcheck disable=SC2030,SC2031
(
  set -euo pipefail
  export EMULATOR_FLOW=30a-drawer-bar-state
  export EMULATOR_ARTIFACTS="$info_dir/budget"
  export EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  # Fixture lines only: keep them out of the CI log. Run 40992967143's
  # log showed this fixture's "FAIL 30a-drawer-bar-state: budget: ..." at
  # 02:39:52 (self_test step) and it was read as a real 30a budget failure;
  # the real 30a ran 630s and wrote no budget line (results.txt).
  budget_stop drawer_bar-state-clear >/dev/null
  budget_stop drawer_bar-state-clear-then-state >/dev/null
  [[ "$(grep -c '^FAIL 30a-drawer-bar-state: budget:' "$RESULTS")" -eq 1 ]] || { echo "budget_stop must record one FAIL" >&2; exit 1; }
  [[ "$(grep -c '^NOT RUN 30a-drawer-bar-state: .*prerequisite budget failed' "$RESULTS")" -eq 2 ]] || { echo "budget_stop steps must be NOT RUN behind the FAIL" >&2; exit 1; }
)
pass
grep -rqF "stopped before the \${FLOW_BUDGET_S}s flow budget" tool/emulator/lib tool/emulator/flows \
  && { echo "a budget stop must go through budget_stop, not a bare NOT RUN" >&2; exit 1; }
pass
rm -rf "$info_dir"

# Near me flows report SKIPPED: not missing, no PASS needed, own count.
skip_dir="$(mktemp -d)"
: > "${skip_dir}/results.txt"
for flow in "${flows[@]}"; do
  case "$flow" in
    11-near-me|23-near-me-settings-roundtrip|30d-near-me)
      printf 'SKIPPED %s: location-dependent\n' "$flow" >> "${skip_dir}/results.txt" ;;
    *) printf 'PASS %s: ok\n' "$flow" >> "${skip_dir}/results.txt" ;;
  esac
done
if ! EMULATOR_ARTIFACTS="$skip_dir" GITHUB_STEP_SUMMARY="${skip_dir}/summary.md" \
  bash tool/emulator/summarize.sh >"${skip_dir}/out" 2>&1; then
  echo "SKIPPED flows must not fail the summary" >&2
  cat "${skip_dir}/out" >&2
  exit 1
fi
pass
grep -q 'missing' "${skip_dir}/results.txt" && { echo "SKIPPED flow reported as missing" >&2; exit 1; }
pass
grep -q ', 0 not run, 3 skipped, 0 notes\.' "${skip_dir}/out" || { echo "summary must count SKIPPED separately: $(cat "${skip_dir}/out")" >&2; exit 1; }
pass
for f in 11-near-me 23-near-me-settings-roundtrip 30d-near-me; do
  grep -qx "  - ${f}: location-dependent" "${skip_dir}/out" || { echo "summary must list SKIPPED ${f} with its reason" >&2; cat "${skip_dir}/out" >&2; exit 1; }
  grep -qx "  - ${f}: location-dependent" "${skip_dir}/summary.md" || { echo "job summary must list SKIPPED ${f}" >&2; exit 1; }
  pass
done
# run_one_flow.sh skips near me flows before any device work.
out="$(EMULATOR_ARTIFACTS="$skip_dir/run" bash tool/emulator/run_one_flow.sh 11-near-me tool/emulator/flows/11_near_me.sh 2>&1)" \
  || { echo "run_one_flow.sh should exit 0 for a skipped flow: $out" >&2; exit 1; }
for f in 11-near-me:11_near_me 23-near-me-settings-roundtrip:23_near_me_settings_roundtrip 30d-near-me:30d_near_me; do
  EMULATOR_ARTIFACTS="$skip_dir/run" bash tool/emulator/run_one_flow.sh "${f%%:*}" "tool/emulator/flows/${f##*:}.sh" >/dev/null 2>&1 \
    || { echo "run_one_flow.sh should exit 0 for skipped ${f%%:*}" >&2; exit 1; }
  grep -Eq "^SKIPPED ${f%%:*}: location-dependent: .+" "$skip_dir/run/results.txt" \
    || { echo "run_one_flow.sh did not record SKIPPED with a reason for ${f%%:*}" >&2; exit 1; }
  pass
done
grep -q '^START' "$skip_dir/run/results.txt" && { echo "a skipped flow must not START" >&2; exit 1; }
pass
rm -rf "$skip_dir"

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
pass
if ! grep -qx 'FAIL 06-filters: missing: flow did not pass any step' "${only_skip_dir}/results.txt"; then
  echo "a flow with only NOT RUN steps should be marked failed" >&2
  cat "${only_skip_dir}/results.txt" >&2
  exit 1
fi
pass
if grep -q '^FAIL 05-search:' "${only_skip_dir}/results.txt"; then
  echo "flows that passed should stay green" >&2
  exit 1
fi
pass
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
pass
if grep -q 'did not pass any step' "${fail_only_dir}/results.txt"; then
  echo "a flow that already failed should not gain a second missing line" >&2
  exit 1
fi
pass
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
pass
if ! grep -qx 'FAIL 06-filters: timeout: started but did not finish' "${started_dir}/results.txt"; then
  echo "a flow with START and no DONE should be marked failed" >&2
  cat "${started_dir}/results.txt" >&2
  exit 1
fi
pass
if grep -q '^FAIL 05-search:' "${started_dir}/results.txt"; then
  echo "a flow with START and DONE should stay green" >&2
  exit 1
fi
pass
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
pass
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
  pass

  : > "$RESULTS"
  skip_if_failed combined-chips "no combined filter was applied" state-select
  grep -q '^FAIL 06-filters: combined-chips: no combined filter was applied$' "$RESULTS"
  if grep -q '^NOT RUN ' "$RESULTS"; then
    echo "skip_if_failed without a prerequisite FAIL must not record NOT RUN" >&2
    exit 1
  fi
  pass

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
  pass

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
  pass

  : > "$browse_dir/log"
  DRAWER_SEARCH_HITS=0
  ALL_TEMPLES_VISIBLE=0
  if open_browse 2>"$browse_dir/err"; then
    echo "a drawer with no All Temples tile should fail" >&2
    exit 1
  fi
  pass
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
  pass
)
rm -rf "$cap_dir" "$stub_bin"

# ui_fling directions, without a device. Run 40658283240 sent "left" and
# "right" as vertical swipes, so flow 24 never paged the gallery.
fling_log="$(mktemp)"
(
  set -euo pipefail
  export EMULATOR_FLOW=24-gallery-autoadvance-viewer
  EMULATOR_ARTIFACTS="$(mktemp -d)"
  export EMULATOR_ARTIFACTS
  export EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  ui_screen_size() { echo "320 640"; }
  adb_shell_capped() { shift; echo "$*" >> "$fling_log"; }
  ui_fling left; ui_fling right; ui_fling up; ui_fling down
  if ui_fling sideways 2>/dev/null; then
    echo "ui_fling must reject unknown directions" >&2
    exit 1
  fi
  pass
  rm -rf "$EMULATOR_ARTIFACTS"
)
expected_flings="input swipe 256 213 64 213 200
input swipe 64 213 256 213 200
input swipe 160 480 160 213 280
input swipe 160 213 160 480 280"
if [[ "$(cat "$fling_log")" != "$expected_flings" ]]; then
  echo "ui_fling coordinates were:" >&2
  cat "$fling_log" >&2
  exit 1
fi
pass
rm -f "$fling_log"

# Run 40698852836: once a case passed its budget, ui_wait returned at once,
# so a filter bar that was on screen read as missing. A spent case budget
# must not turn a plain wait into a false negative.
budget_dir="$(mktemp -d)"
(
  set -euo pipefail
  export EMULATOR_FLOW=29g-search-state
  export EMULATOR_ARTIFACTS="$budget_dir"
  export EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  ui_dump() { return 0; }
  ui_find() { return 0; }
  STEP_DEADLINE=1
  if ! ui_wait 5 --resource-id filter-chip-state 2>/dev/null; then
    echo "ui_wait must still look once after the case budget is spent" >&2
    exit 1
  fi
  pass
  if ! ui_wait_scrolled 5 --text-contains "Temples near me" 2>/dev/null; then
    echo "ui_wait_scrolled must still look once after the case budget is spent" >&2
    exit 1
  fi
  pass
)
rm -rf "$budget_dir"
for lib in tool/emulator/flows/lib/filter_matrix.sh tool/emulator/flows/lib/filter_matrix_b.sh; do
  # case_start must come after the entry call inside run_case.
  if ! awk '
    /^run_case\(\)/ { inside = 1 }
    inside && /enter_\$\{MATRIX_ENTRY\}/ { entered = 1 }
    inside && /^  case_start$/ { if (!entered) bad = 1; started = 1 }
    inside && /^}/ { inside = 0 }
    END { exit (bad || !started) }
  ' "$lib"; then
    echo "${lib}: run_case must start the case budget after the entry screen" >&2
    exit 1
  fi
  pass
  if ! grep -q 'run_case_or_stop' "$lib"; then
    echo "${lib}: matrix_main must stop remaining cases before the flow budget" >&2
    exit 1
  fi
  pass
  if grep -q '~15 min' "$lib"; then
    echo "${lib}: the 15 minute comment claimed the slice fit under 1140s" >&2
    exit 1
  fi
  pass
done

# option-seek: hundreds of sorted deity chips (run 40698852836 ended at
# "Buddhist ..." looking for Shiva). The seek says which way to scroll.
seek_fixture="$(mktemp)"
cat > "$seek_fixture" <<'EOF'
<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>
<hierarchy rotation="0">
  <node text="" content-desc="Any deity  992" resource-id="filter-option-deity-any" class="android.view.View" package="com.example" clickable="true" bounds="[16,200][120,240]" />
  <node text="" content-desc="Buddhist (Kagyu) · Buddhist  1" resource-id="filter-option-deity-Buddhist (Kagyu)" class="android.view.View" package="com.example" clickable="true" bounds="[16,260][300,300]" />
  <node text="" content-desc="Chamunda  2" resource-id="filter-option-deity-Chamunda" class="android.view.View" package="com.example" clickable="true" bounds="[16,320][140,360]" />
  <node text="" content-desc="Durga  4" resource-id="filter-option-deity-Durga" class="android.view.View" package="com.example" clickable="true" bounds="[16,600][140,630]" />
  <node text="" content-desc="Kerala  12" resource-id="filter-option-state-Kerala" class="android.view.View" package="com.example" clickable="true" bounds="[16,380][140,420]" />
</hierarchy>
EOF
seek() { python3 tool/emulator/lib/ui.py option-seek "$seek_fixture" --min-top 153 --max-top 537 "$@"; }
[[ "$(seek --kind deity --name Shiva)" == "up far" ]] || { echo "option-seek: Shiva is far below" >&2; exit 1; }
pass
[[ "$(seek --kind deity --name Agni)" == "down mid" ]] || { echo "option-seek: Agni is one initial above" >&2; exit 1; }
pass
[[ "$(seek --kind deity --name Chamunda)" == "tap 78 340 Chamunda 2" ]] || { echo "option-seek: Chamunda tap was $(seek --kind deity --name Chamunda)" >&2; exit 1; }
pass
[[ "$(seek --kind deity --name Durga)" == "up near" ]] || { echo "option-seek: Durga is under the tap band" >&2; exit 1; }
pass
[[ "$(seek --kind deity --name Chandi)" == absent ]] || { echo "option-seek: Chandi is not listed" >&2; exit 1; }
pass
[[ "$(seek --kind district --name Madurai)" == absent ]] || { echo "option-seek: state and deity chips with no district between: none offered" >&2; exit 1; }
pass
# directoryDeitiesFrom uses Dart List.sort (UTF-16). U+1F600 is before
# U+F000 in UTF-16 and after it in Python's code-point order.
dart_order="$(mktemp)"
python3 - "$dart_order" <<'PY'
import sys
emoji = "\U0001F600"
path = sys.argv[1]
open(path, "w", encoding="utf-8").write(
    "<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>\n"
    "<hierarchy rotation=\"0\">\n"
    f'  <node text="" content-desc="{emoji}  1" resource-id="filter-option-deity-{emoji}" '
    'class="android.view.View" package="com.example" clickable="true" bounds="[16,260][300,300]" />\n'
    "</hierarchy>\n"
)
PY
[[ "$(python3 tool/emulator/lib/ui.py option-seek "$dart_order" --kind deity --name $'\uf000' --min-top 153 --max-top 537)" == "up far" ]] \
  || { echo "option-seek must follow Dart UTF-16 order, not Python code points" >&2; exit 1; }
  pass
rm -f "$seek_fixture" "$dart_order"

# Real option-list dumps from emulator run 40916686359, at the failure
# points. The old option-seek said "none" for every state pick (a fling
# had left STATE) and the picker gave up. With the section order it must
# say which way STATE is, and Shiva's neighbourhood must point at Shiva.
run_dumps=tool/emulator/testdata/run40916686359
real_seek() { python3 tool/emulator/lib/ui.py option-seek "$run_dumps/$1" --min-top 153 --max-top 537 "${@:2}"; }
for f in state_seek_deity_region.xml state_seek_deity_region_flow22.xml state_seek_district_region.xml; do
  got="$(real_seek "$f" --kind state --name 'Tamil Nadu' --order state,district,deity)"
  [[ "$got" == "down far" ]] || { echo "option-seek on real dump $f: want 'down far', got '$got'" >&2; exit 1; }
  pass
done
got="$(real_seek deity_seek_shiva_region.xml --kind deity --name Shiva --order deity,state,district)"
[[ "$got" == "down near" ]] || { echo "option-seek: Shiva is just above 'Shiva (Baneswar)', got '$got'" >&2; exit 1; }
pass
got="$(real_seek deity_seek_past_shiva.xml --kind deity --name Shiva --order deity,state,district)"
[[ "$got" == "up mid" ]] || { echo "option-seek: Shiva is a few rows below 'Shikari Devi', got '$got'" >&2; exit 1; }
pass
[[ "$(python3 tool/emulator/lib/ui.py sheet-kinds "$run_dumps/sheet_top_state.xml")" == state ]] || { echo "sheet-kinds: STATE leads the state sheet" >&2; exit 1; }
pass
[[ "$(python3 tool/emulator/lib/ui.py sheet-kinds "$run_dumps/district_sheet.xml")" == district ]] || { echo "sheet-kinds: DISTRICT leads the district sheet" >&2; exit 1; }
pass
# Madurai sits between real neighbours on the district sheet; Paraganas are first.
got="$(real_seek district_sheet.xml --kind district --name Madurai --order district,state,deity)"
[[ "$got" == "up far" ]] || { echo "option-seek: Madurai is far below the 24 Paraganas, got '$got'" >&2; exit 1; }
pass

# seek_option + select_labeled against a model of the real sheet
# (testdata/sheet_sim.py: run 40916686359 geometry and labels, flings that
# keep moving after the first dump). Each pick must tap the right chip,
# for many fling strengths, inside the 45s picker budget.
sim_pick() {
  # sim_pick KIND REGEX FOCUS SEED [init args...]; prints the tapped label.
  local kind="$1" regex="$2" focus="$3" seed="$4"
  shift 4
  local d
  d="$(mktemp -d)"
  python3 tool/emulator/testdata/sheet_sim.py init "$d/sim.json" --focus "$focus" --seed "$seed" --pad-deity 600 "$@"
  # The stubs below replace common.sh's device helpers; seek_option calls them.
  # shellcheck disable=SC2329,SC2030,SC2031
  (
    set -uo pipefail
    export EMULATOR_FLOW=29-sim
    export EMULATOR_ARTIFACTS="$d/art"
    export EMULATOR_PACKAGE=com.shradhaventures.temple
    # shellcheck disable=SC1091
    source tool/emulator/lib/common.sh
    STEP_DEADLINE=0
    SIM="$d/sim.json"
    ui_screen_size() { echo "320 640"; }
    # Device time (run 40992967143): ~1s per uiautomator dump and per
    # adb input swipe; 9 seek looks then filled the 45s seek window, as
    # in that run's "not reached before the deadline (9 looks ...)".
    ui_dump() { SECONDS=$((SECONDS + ${SIM_DUMP_S:-1})); python3 tool/emulator/testdata/sheet_sim.py dump "$SIM" "$DUMP"; }
    adb_shell_capped() {
      shift
      SECONDS=$((SECONDS + ${SIM_SWIPE_S:-1}))
      echo "$*" >> "$d/log"
      if [[ "$1 $2" == "input swipe" ]]; then
        python3 tool/emulator/testdata/sheet_sim.py swipe "$SIM" "$3" "$4" "$5" "$6" "$7"
      fi
    }
    ui_tap() {
      echo "tap $UI_CX $UI_CY" >> "$d/log"
      python3 tool/emulator/testdata/sheet_sim.py at "$SIM" "$UI_CX" "$UI_CY" > "$d/tapped"
    }
    wait_out_district_loader() { return 0; }
    sleep() { :; }
    local rc=0 t0=$SECONDS
    select_labeled "$regex" "$(printf '%s' "$kind" | tr '[:lower:]' '[:upper:]')" 2> "$d/err" || rc=$?
    printf '%s|%s|%s|%s|%s\n' "$rc" "$(cat "$d/tapped" 2>/dev/null)" "$(grep -c 'input swipe' "$d/log" 2>/dev/null || echo 0)" "$(tr '\n' ' ' < "$d/err")" "$((SECONDS - t0))"
  )
  if [[ -n "${SIM_PROOF_DIR:-}" ]]; then
    mkdir -p "$SIM_PROOF_DIR"
    cp "$d/log" "$SIM_PROOF_DIR/${kind}-${focus}-seed${seed}.actions.log" 2>/dev/null || true
    cp "$d/art/dumps/"*.xml "$SIM_PROOF_DIR/" 2>/dev/null || true
  fi
  rm -rf "$d"
}

sim_ok() {
  # sim_ok KIND REGEX FOCUS WANT_LABEL
  # sim_ok KIND REGEX FOCUS WANT_LABEL [MOMENTUM...]; with no MOMENTUM,
  # seeds 1-8 draw fling momentum 4-14x. WANT_LABEL may be a regex (~RX).
  local kind="$1" regex="$2" focus="$3" want="$4" seed out rc tapped swipes elapsed m
  shift 4
  local runs=()
  if (( $# )); then for m in "$@"; do runs+=("3:$m"); done
  else for seed in 1 2 3 4 5 6 7 8; do runs+=("$seed:"); done; fi
  local run
  for run in "${runs[@]}"; do
    seed="${run%%:*}" m="${run#*:}"
    if [[ -n "$m" ]]; then out="$(sim_pick "$kind" "$regex" "$focus" "$seed" --momentum "$m")"
    else out="$(sim_pick "$kind" "$regex" "$focus" "$seed")"; fi
    IFS='|' read -r rc tapped swipes _ elapsed <<<"$out"
    local ok=0
    if [[ "$want" == '~'* ]]; then [[ "$tapped" =~ ${want#\~} ]] && ok=1
    else [[ "$tapped" == "$want" ]] && ok=1; fi
    [[ "$rc" == 0 && "$ok" == 1 ]] \
      || { echo "sim: ${kind} pick (${focus} sheet, seed ${seed}, momentum ${m:-random}) tapped '${tapped}' rc=${rc}: ${out}" >&2; exit 1; }
    # Device time, not swipe count, is the limit: the pick must finish
    # inside select_labeled's window (SELECT_MAX, default 75s).
    (( elapsed <= ${SELECT_MAX:-75} )) || { echo "sim: ${kind} pick took ${elapsed}s of device time (seed ${seed})" >&2; exit 1; }
    [[ -n "${SIM_PROOF_DIR:-}" ]] && printf '%s %s focus=%s seed=%s momentum=%s -> rc=%s tapped="%s" swipes=%s device_s=%s\n' \
      "$kind" "$regex" "$focus" "$seed" "${m:-random}" "$rc" "$tapped" "$swipes" "$elapsed" >> "$SIM_PROOF_DIR/summary.txt"
    pass
  done
}
sim_ok state '^Tamil Nadu( +[0-9]+)?$' state 'Tamil Nadu  50'
sim_ok state '^Kerala( +[0-9]+)?$' state 'Kerala  50'
sim_ok district '^Madurai( +[0-9]+)?$' district 'Madurai  4'
sim_ok deity '^Shiva( +[0-9]+)?$' deity 'Shiva  159'
# Picking a state from a sheet opened on another section (flows 17, 22).
sim_ok state '^Tamil Nadu( +[0-9]+)?$' deity 'Tamil Nadu  50'
# Run 40992967143: every Shiva/Vishnu pick on the ~600-option DEITY
# section ran out of its 45s seek at P-R (06, 17a/17b, 22, 29c/29f/29i/29j,
# 30c). Fixed momenta from that run's pace (one 120ms fling per ~5s look
# reached P in 9 looks) up to the fastest seen; 4dd6f14 fails all of these.
sim_ok deity '^Shiva( +[0-9]+)?$' deity 'Shiva  159' 5 6 9 14
sim_ok deity '^Vishnu' deity '~^Vishnu ' 5 6 9 14
sim_ok state '^Tamil Nadu( +[0-9]+)?$' deity 'Tamil Nadu  50' 5 6 9 14
sim_ok district '^Madurai( +[0-9]+)?$' district 'Madurai  4' 5 6 9 14

# Negative: a missing option fails fast and says so, no tap.
for spec in "state|Atlantis|state" "deity|Shiva|deity|drop" "deity|Zzyzx|deity"; do
  IFS='|' read -r neg_kind neg_name neg_focus neg_drop <<<"$spec"
  extra=()
  [[ -n "$neg_drop" ]] && extra=(--drop "$neg_name")
  out="$(sim_pick "$neg_kind" "^${neg_name}( +[0-9]+)?$" "$neg_focus" 3 "${extra[@]}")"
  IFS='|' read -r rc tapped swipes err elapsed <<<"$out"
  [[ "$rc" != 0 && -z "$tapped" ]] || { echo "sim: missing ${neg_kind} '${neg_name}' should fail without a tap: ${out}" >&2; exit 1; }
  [[ "$err" == *"not offered in the ${neg_kind} list"* || "$err" == *"not in the list"* || "$err" == *"not listed"* ]] \
    || { echo "sim: missing ${neg_kind} '${neg_name}' error was unclear: ${err}" >&2; exit 1; }
  (( elapsed <= ${SELECT_MAX:-75} )) || { echo "sim: missing ${neg_kind} '${neg_name}' took ${elapsed}s (${swipes} swipes)" >&2; exit 1; }
  [[ -n "${SIM_PROOF_DIR:-}" ]] && printf 'NEGATIVE %s %s -> rc=%s tapped="%s" swipes=%s err=%s\n' \
    "$neg_kind" "$neg_name" "$rc" "$tapped" "$swipes" "$err" >> "$SIM_PROOF_DIR/summary.txt"
  pass
done

# Run 40992967143 real dumps and recording frames (testdata/run40992967143).
r7=tool/emulator/testdata/run40992967143
r7_seek() { python3 tool/emulator/lib/ui.py option-seek "$r7/$1" --min-top 153 --max-top 537 "${@:2}"; }
# Where the 45s ran out: P (06/17/29c) and R (22). Both still point at S.
got="$(r7_seek deity_seek_P_region.xml --kind deity --name Shiva --order deity,state,district)"
[[ "$got" == "up far" ]] || { echo "run 40992967143 P-region dump: Shiva should be 'up far', got '$got'" >&2; exit 1; }
pass
got="$(r7_seek deity_seek_R_region.xml --kind deity --name Shiva --order deity,state,district)"
[[ "$got" == "up mid" ]] || { echo "run 40992967143 R-region dump: Shiva should be 'up mid', got '$got'" >&2; exit 1; }
pass
got="$(r7_seek vishnu_seek_P_region.xml --kind deity --name Vishnu --order deity,state,district --prefix)"
[[ "$got" == "up far" ]] || { echo "run 40992967143 flow 22 dump: Vishnu should be 'up far', got '$got'" >&2; exit 1; }
pass
# "Shiva" is a prefix of every "Shiva (...)" row: a far one is a mid
# fling away, "Shiva (Adi...)"/"(Baneswar)" only a few rows.
prefix_fixture="$(mktemp)"
cat > "$prefix_fixture" <<'XML'
<hierarchy><node resource-id="filter-option-deity-Shiva (Somnath)" content-desc="Shiva (Somnath)  1" bounds="[16,300][252,332]"/><node resource-id="filter-option-deity-Shiva (Tryambakeshwar)" content-desc="Shiva (Tryambakeshwar)  1" bounds="[16,340][252,372]"/></hierarchy>
XML
got="$(python3 tool/emulator/lib/ui.py option-seek "$prefix_fixture" --kind deity --name Shiva --order deity,state,district --min-top 153 --max-top 537)"
[[ "$got" == "down mid" ]] || { echo "option-seek: Shiva is far above 'Shiva (Somnath)', got '$got'" >&2; exit 1; }
pass
rm -f "$prefix_fixture"
# The pick itself on the real lists: Tamil Nadu (run 40992967143 29a frame
# t87 transcribed onto that run's sheet dump), Shiva 159 (run 40916686359
# 29c frame t101.4, the one frame that shows it), Madurai (real dump,
# run 40698852836; run 40992967143's 29b frame t108 shows the same rows).
# Negative: the same list without the option must fail with no tap.
for spec in "state_sheet_tamil_nadu_frame_29a_t87.xml|state|^Tamil Nadu( +[0-9]+)?$|Tamil Nadu|Tamil Nadu  50" \
            "deity_sheet_shiva_frame_run40916686359_29c_t101.xml|deity|^Shiva( +[0-9]+)?$|Shiva|Shiva  159" \
            "district_sheet_madurai_visible_run40698852836.xml|district|^Madurai( +[0-9]+)?$|Madurai|Madurai  4"; do
  IFS='|' read -r r7_file r7_kind r7_rx r7_name r7_want <<<"$spec"
  out="$(SELECT_MAX=20 bash tool/emulator/testdata/replay_dump.sh "$r7/$r7_file" "$r7_kind" "$r7_rx")"
  [[ "$out" == "rc=0 tapped=${r7_want} "* ]] || { echo "replay ${r7_file}: want a tap on '${r7_want}': ${out}" >&2; exit 1; }
  pass
  out="$(SELECT_MAX=20 bash tool/emulator/testdata/replay_dump.sh "$r7/$r7_file" "$r7_kind" "$r7_rx" --drop "$r7_name")"
  [[ "$out" == "rc=1 tapped= "* ]] || { echo "replay ${r7_file} without ${r7_name}: must fail with no tap: ${out}" >&2; exit 1; }
  pass
done
# A plain "Shiva" regex must not take "Shiva (Adi Kumbeswarar)..." when
# Shiva itself is gone: the matcher stays strict.
out="$(SELECT_MAX=20 bash tool/emulator/testdata/replay_dump.sh "$r7/deity_sheet_shiva_frame_run40916686359_29c_t101.xml" deity '^Shiva( +[0-9]+)?$' --drop Shiva)"
[[ "$out" == *"not offered in the deity list"* ]] || { echo "replay: missing Shiva must say 'not offered': ${out}" >&2; exit 1; }
pass
# 29a/29d/29g *-select-then-state: the bar was there with State scrolled
# off to the left; filter_matrix.sh must accept any chip as the bar and
# scroll to State.
python3 tool/emulator/lib/ui.py find "$r7/home_bar_state_scrolled_off.xml" --resource-id filter-chip-state >/dev/null 2>&1 \
  && { echo "fixture: filter-chip-state should be absent (scrolled off)" >&2; exit 1; }
python3 tool/emulator/lib/ui.py find "$r7/home_bar_state_scrolled_off.xml" --resource-id-regex '^filter-chip-(state|district|deity)$' >/dev/null \
  || { echo "home_bar_state_scrolled_off: the bar must be found by any chip" >&2; exit 1; }
pass
grep -q "resource-id-regex '^filter-chip-(state|district|deity)\$'" tool/emulator/flows/lib/filter_matrix.sh \
  || { echo "filter_matrix.sh assert_entry_screen must accept any chip as the bar" >&2; exit 1; }
pass
fc="$(awk '/^find_chip\(\)/{f=1} f&&/^}/{exit} f' tool/emulator/flows/lib/filter_matrix.sh)"
if [[ "$fc" != *'scroll_chips_until --resource-id "filter-chip-$1"'* || "$fc" == *'state)'* ]]; then
  echo "filter_matrix.sh find_chip must scroll to State too" >&2; exit 1
fi
pass
# The far run must not settle between flings (each settle is 2+ dumps);
# a tap is only taken on a settled list.
if ! grep -q 'settled=0' tool/emulator/lib/common.sh || ! grep -q 'SEEK_FAR_FLINGS' tool/emulator/lib/common.sh; then
  echo "seek_option: far runs must fling back to back without settling" >&2; exit 1
fi
pass

# A list that keeps swinging stops after SEEK_MAX_FLIPS changes of direction.
flip_dir="$(mktemp -d)"
flip_seq="$(mktemp)"
printf '%s\n' up down up down up down up down > "$flip_seq"
cat > "$flip_dir/seek.py" <<'PY'
import os, sys
if sys.argv[1] == "sheet-kinds":
    print("deity")
    raise SystemExit(0)
path = os.environ["SEEK_SEQ"]
lines = open(path, encoding="utf-8").read().splitlines()
print(lines.pop(0) if lines else "none")
open(path, "w", encoding="utf-8").write("\n".join(lines) + ("\n" if lines else ""))
PY
(
  set -euo pipefail
  export EMULATOR_FLOW=06-filters
  export EMULATOR_ARTIFACTS="$flip_dir/art"
  export EMULATOR_PACKAGE=com.example
  export SEEK_SEQ="$flip_seq"
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  UI_PY="$flip_dir/seek.py"
  ui_screen_size() { echo "320 640"; }
  ui_dump() { printf '<hierarchy/>' > "$DUMP"; }
  dump_scroll_sig() { echo "$RANDOM"; }
  adb_shell_capped() { shift; echo "$*" >> "$flip_dir/log"; }
  ui_sheet_swipe() { echo "sheet $1" >> "$flip_dir/log"; }
  sleep() { :; }
  seek_settle() { ui_dump; }
  if seek_option deity Shiva $((SECONDS + 30)); then
    echo "seek_option should stop when the list keeps swinging" >&2
    exit 1
  fi
  pass
)
# seek_settle fails (no decision, no tap) while the list never stops moving.
# shellcheck disable=SC2030,SC2031,SC2329
(
  set -euo pipefail
  export EMULATOR_FLOW=06-filters
  export EMULATOR_ARTIFACTS="$flip_dir/art2"
  export EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  ui_dump() { printf '<hierarchy/>' > "$DUMP"; }
  dump_scroll_sig() { echo "$RANDOM$RANDOM"; }
  sleep() { :; }
  if seek_settle 2>/dev/null; then
    echo "seek_settle must fail while the list is still moving" >&2
    exit 1
  fi
  dump_scroll_sig() { echo same; }
  seek_settle || { echo "seek_settle must succeed once two dumps match" >&2; exit 1; }
)
pass
swipes="$(wc -l < "$flip_dir/log" | tr -d ' ')"
[[ "$swipes" -eq 6 ]] || { echo "seek_option swiped ${swipes} times; want 6 before the sixth change of direction" >&2; cat "$flip_dir/log" >&2; exit 1; }
pass
rm -rf "$flip_dir"
rm -f "$flip_seq"

# logcat_mark must hand the date format to the device as one word.
mark_dir="$(mktemp -d)"
(
  set -euo pipefail
  export EMULATOR_FLOW=25-directions-edge
  export EMULATOR_ARTIFACTS="$mark_dir"
  export EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  adb_shell_capped() { shift; [[ "$#" -eq 1 && "$1" == "date '+%m-%d %H:%M:%S.000'" ]] && echo "10-28 15:15:20.000"; }
  [[ "$(logcat_mark)" == "10-28 15:15:20.000" ]] || { echo "logcat_mark must pass the date format as one quoted word" >&2; exit 1; }
  pass
)
rm -rf "$mark_dir"

# no-maps-fallback: browsers are an allowlist plus the https VIEW handler.
# A chooser is other. The launcher is the HOME handler, not a name match.
# In-app passes only for the Couldn't open directions message, not the button.
fallback_dir="$(mktemp -d)"
(
  set -euo pipefail
  export EMULATOR_FLOW=25-directions-edge
  export EMULATOR_ARTIFACTS="$fallback_dir"
  export EMULATOR_PACKAGE=com.example.temple
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  expect_kind() {
    local want="$1" pkg="$2" handler="${3:-}" home="${4:-}" got
    got="$(classify_fallback_pkg "$pkg" "$handler" "$home")"
    [[ "$got" == "$want" ]] || { echo "classify_fallback_pkg ${pkg:-<empty>} handler=${handler:-<none>} home=${home:-<none>} was ${got}, want ${want}" >&2; exit 1; }
    pass
  }
  expect_kind browser com.android.chrome
  expect_kind browser com.android.chrome org.mozilla.firefox
  expect_kind browser org.mozilla.firefox
  expect_kind browser org.mozilla.fenix
  expect_kind browser com.sec.android.app.sbrowser
  expect_kind browser com.microsoft.emmx
  expect_kind browser com.brave.browser
  expect_kind browser com.android.browser com.android.browser
  expect_kind other com.android.browser
  expect_kind other android android
  expect_kind other com.android.intentresolver com.android.intentresolver
  expect_kind other android com.android.chrome
  expect_kind other com.example.temple com.example.temple
  expect_kind other com.example.temple
  expect_kind other com.google.android.apps.maps org.mozilla.firefox
  expect_kind other "" org.mozilla.firefox
  expect_kind other com.android.launcher3
  expect_kind other com.google.android.apps.nexuslauncher org.mozilla.firefox
  expect_kind launcher com.android.launcher3 "" com.android.launcher3
  expect_kind launcher com.google.android.apps.nexuslauncher "" com.google.android.apps.nexuslauncher
  expect_kind launcher com.android.launcher3 com.android.launcher3 com.android.launcher3
  expect_kind permission com.google.android.permissioncontroller "" com.google.android.permissioncontroller
  expect_kind permission com.android.permissioncontroller com.android.permissioncontroller com.android.permissioncontroller
  # The button text is not an argument: still in the app without the snackbar fails.
  [[ "$(no_maps_in_app_result com.example.temple 0)" == fail ]] || { echo "in-app without Couldn't open directions must fail" >&2; exit 1; }
  pass
  [[ "$(no_maps_in_app_result com.example.temple 1)" == pass ]] || { echo "in-app Couldn't open directions must pass" >&2; exit 1; }
  pass
  [[ "$(no_maps_in_app_result com.android.chrome 1)" == fail ]] || { echo "a browser is not the in-app snackbar pass" >&2; exit 1; }
  pass
  adb_shell_capped() {
    shift
    case "$*" in
      "cmd package resolve-activity --brief -a android.intent.action.VIEW -d https://example.com")
        printf '%s\n' "priority=0 preferredOrder=0 match=0x208000 specificIndex=-1 isDefault=true" \
          "com.android.chrome/com.google.android.apps.chrome.IntentDispatcher" ;;
      "cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME")
        printf '%s\n' "com.google.android.apps.nexuslauncher/com.google.android.apps.nexuslauncher.NexusLauncherActivity" ;;
      *)
        echo "unexpected resolve-activity: $*" >&2
        exit 1 ;;
    esac
    pass
  }
  [[ "$(https_view_handler)" == "com.android.chrome" ]] || { echo "https_view_handler did not parse the brief component" >&2; exit 1; }
  pass
  [[ "$(home_handler)" == "com.google.android.apps.nexuslauncher" ]] || { echo "home_handler did not parse the HOME component" >&2; exit 1; }
  pass
)
rm -rf "$fallback_dir"

if ! awk '
  /directions_tapped=1/ { tapped = 1 }
  tapped && /classify_fallback_pkg/ { classified = 1 }
  /Get Directions was not on screen to tap/ { missed = 1 }
  END { exit !(tapped && classified && missed) }
' tool/emulator/flows/25_directions_edge.sh; then
  echo "flow 25 must tap Get Directions before classifying, and fail when it was not found" >&2
  exit 1
fi
pass

# A spent flow budget records one FAIL (budget), marks the remaining cases
# and probes NOT RUN behind it, and does not run them.
budget_case_dir="$(mktemp -d)"
(
  set -euo pipefail
  export EMULATOR_FLOW=29a-home-browse-state
  export EMULATOR_ARTIFACTS="$budget_case_dir"
  export EMULATOR_PACKAGE=com.example.temple
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  # shellcheck disable=SC1091
  source tool/emulator/flows/lib/filter_matrix.sh
  force_stop_app() { :; }
  run_case() { echo "ran:$1" >> "$budget_case_dir/ran"; }
  unset FLOW_FALLBACK_EPOCH
  FLOW_START_EPOCH="$(date +%s)"
  if flow_over; then echo "a fresh flow should not be over the 1140s budget" >&2; exit 1; fi
  FLOW_START_EPOCH="$(( $(date +%s) - 2000 ))"
  if ! flow_over; then echo "elapsed time past the flow budget should stop the next case" >&2; exit 1; fi
  flow_over() { return 0; }
  MATRIX_ENTRY=home_browse
  MATRIX_CHIP=state
  ACTIONS=(select)
  matrix_main
  [[ ! -s "$budget_case_dir/ran" ]] || { echo "flow_over still ran a case" >&2; exit 1; }
  pass
  grep -qx 'FAIL 29a-home-browse-state: budget: home_browse-state-select and later steps not reached before the 1140s flow budget' "$RESULTS"
  grep -qx 'NOT RUN 29a-home-browse-state: home_browse-state-select: prerequisite budget failed' "$RESULTS"
  grep -qx 'NOT RUN 29a-home-browse-state: home_browse-state-select-then-district: prerequisite budget failed' "$RESULTS"
  flow_over() { return 1; }
  : > "$budget_case_dir/ran"
  : > "$RESULTS"
  matrix_main
  grep -qx 'ran:home_browse-state-select' "$budget_case_dir/ran"
)
rm -rf "$budget_case_dir"

# wait_browse_ready taps "Try again" once and waits out that load
# (runs 40698852836 flows 09 and 27).
wbr_dir="$(mktemp -d)"
(
  set -euo pipefail
  export EMULATOR_FLOW=09-photos
  export EMULATOR_ARTIFACTS="$wbr_dir"
  export EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  sleep() { SECONDS=$((SECONDS + ${1%.*})); }
  ui_dump() { return 0; }
  ui_tap() { TAPS=$((TAPS + 1)); }
  TAPS=0
  # Fails until 10s after the tap, then the bar appears.
  ui_find() {
    local ok=0
    if (( TAPS > 0 && SECONDS - TAP_AT >= 10 )); then ok=1; fi
    case "$*" in
      *"Could not load temples"*) (( ok == 0 )) ;;
      *browse-load-failed-retry*) (( ok == 0 )) ;;
      *filter-chip-state*) (( ok == 1 )) ;;
      *) return 1 ;;
    esac
  }
  ui_tap() { TAPS=$((TAPS + 1)); TAP_AT=$SECONDS; }
  wait_browse_ready >/dev/null 2>&1 || { echo "wait_browse_ready must survive one failed load" >&2; exit 1; }
  pass
  [[ "$TAPS" -eq 1 ]] || { echo "wait_browse_ready tapped Try again ${TAPS} times" >&2; exit 1; }
  pass
  # Still failing after the grace: report failure, one tap only.
  TAPS=0
  ui_find() { case "$*" in *"Could not load temples"*|*browse-load-failed-retry*) return 0 ;; *) return 1 ;; esac; }
  if wait_browse_ready >/dev/null 2>&1; then echo "a persistent failure must fail" >&2; exit 1; fi
  pass
  [[ "$TAPS" -eq 1 ]] || { echo "persistent failure tapped ${TAPS} times" >&2; exit 1; }
  pass
)
rm -rf "$wbr_dir"

# find_filter_chip in landscape: wm size says 320x640, the dump is
# 640x320, and the app bar title repeats "Kerala" (run 40698852836 flow 19).
ffc_dir="$(mktemp -d)"
(
  set -euo pipefail
  export EMULATOR_FLOW=19-rotation-state
  export EMULATOR_ARTIFACTS="$ffc_dir"
  export EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  ui_screen_size() { echo "320 640"; }
  ui_dump() {
    cat > "$DUMP" <<'EOF'
<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>
<hierarchy rotation="1">
  <node text="" content-desc="" resource-id="" class="android.widget.FrameLayout" package="com.example" bounds="[0,0][640,320]">
    <node text="" content-desc="Kerala" resource-id="" class="android.view.View" package="com.example" bounds="[289,52][351,76]" />
    <node text="" content-desc="Kerala" resource-id="filter-chip-state" class="android.view.View" package="com.example" clickable="true" bounds="[54,181][137,216]" />
  </node>
</hierarchy>
EOF
  }
  scroll_chip_bar_at() { echo "scrolled" >&2; return 0; }
  sleep() { :; }
  chip_exact Kerala 2>"$ffc_dir/err" || { echo "chip_exact must find the Kerala chip in landscape" >&2; exit 1; }
  pass
  [[ "$UI_CX" == 95 && "$UI_CY" == 198 ]] || { echo "chip_exact matched ${UI_CX},${UI_CY}, not the chip" >&2; exit 1; }
  pass
  ! grep -q scrolled "$ffc_dir/err" || { echo "chip_exact scrolled a chip that was in view" >&2; exit 1; }
  pass
)
rm -rf "$ffc_dir"

# ---- Run 40992967143 (dry run 4) regressions, real dumps ----
r4="tool/emulator/testdata/run40992967143"
# 29d/29g: with a state applied the State chip is scrolled off to the left.
# The bar is still there; assert_entry_screen must accept any chip.
r4_bar="$r4/29d-drawer-all-state_drawer_all-state-select-then-state.xml"
if python3 tool/emulator/lib/ui.py find "$r4_bar" --resource-id filter-chip-state >/dev/null; then
  echo "fixture: State chip should be off-screen in $r4_bar" >&2; exit 1
fi
pass
python3 tool/emulator/lib/ui.py find "$r4_bar" --resource-id-regex '^filter-chip-(state|district|deity)$' >/dev/null \
  || { echo "the chip-row regex must find the bar with State scrolled off" >&2; exit 1; }
pass
grep -qF "ui_wait 8 --resource-id-regex '^filter-chip-(state|district|deity)\$'" tool/emulator/flows/lib/filter_matrix.sh \
  || { echo "filter_matrix.sh assert_entry_screen must accept any filter chip" >&2; exit 1; }
pass

# Pick step against real dumps: present -> tap the real label; missing -> FAIL, no tap.
r4_pick() {
  # r4_pick DUMP KIND REGEX; prints rc|tapped|err
  local dump="$1" kind="$2" regex="$3" d
  d="$(mktemp -d)"
  # shellcheck disable=SC2030,SC2031
  (
    set -uo pipefail
    export EMULATOR_FLOW=29-r4 EMULATOR_ARTIFACTS="$d/art" EMULATOR_PACKAGE=com.shradhaventures.temple
    # shellcheck disable=SC1091
    source tool/emulator/lib/common.sh
    STEP_DEADLINE=0
    ui_screen_size() { echo "320 640"; }
    ui_dump() { mkdir -p "$(dirname "$DUMP")"; cp "$dump" "$DUMP"; }
    adb_shell_capped() { shift; echo "$*" >> "$d/log"; }
    ui_tap() { echo "$UI_TEXT" > "$d/tapped"; }
    wait_out_district_loader() { return 0; }
    sleep() { :; }
    SELECT_MAX=20
    local rc=0
    select_labeled "$regex" "$(printf '%s' "$kind" | tr '[:lower:]' '[:upper:]')" 2> "$d/err" || rc=$?
    printf '%s|%s|%s\n' "$rc" "$(cat "$d/tapped" 2>/dev/null)" "$(tr '\n' ' ' < "$d/err")"
  )
  rm -rf "$d"
}
seq2="$r4/29j-sequences_seq2.xml"
out="$(r4_pick "$seq2" deity '^Murugan( +[0-9]+)?$')"
[[ "$out" == "0|Murugan 1|"* ]] || { echo "Murugan must be picked from the real Madurai deity list: $out" >&2; exit 1; }
pass
# Shiva is not under Madurai (the run 4 seq2 failure): FAIL, no tap.
out="$(r4_pick "$seq2" deity '^Shiva( +[0-9]+)?$')"
IFS='|' read -r rc tapped err <<<"$out"
[[ "$rc" != 0 && -z "$tapped" && "$err" == *"not offered in the deity list"* ]] \
  || { echo "Shiva is not under Madurai; the pick must fail without a tap: $out" >&2; exit 1; }
pass
# Negative on the same real dump with the target removed: the pick FAILS.
nodump="$(mktemp)"
# uiautomator writes the dump on one line: drop the node, not the line.
sed -E 's#<node [^>]*resource-id="filter-option-deity-Murugan"[^>]*/>##' "$seq2" > "$nodump"
grep -q 'filter-option-deity-Devi"' "$nodump" || { echo "fixture: node removal broke the dump" >&2; exit 1; }
! grep -q 'filter-option-deity-Murugan"' "$nodump" || { echo "fixture: Murugan not removed" >&2; exit 1; }
out="$(r4_pick "$nodump" deity '^Murugan( +[0-9]+)?$')"
IFS='|' read -r rc tapped err <<<"$out"
[[ "$rc" != 0 && -z "$tapped" && "$err" == *"not offered in the deity list"* ]] \
  || { echo "Murugan removed from the real dump; the pick must fail without a tap: $out" >&2; exit 1; }
pass
rm -f "$nodump"
# 29j: Murugan only where Madurai is applied or must stay offered (seq2,
# seq3); seq1 keeps Shiva (Sanu: no target change to dodge the matcher).
seq_block="$(awk '/MATRIX_ENTRY" == seq/{f=1} f&&/^  else/{exit} f' tool/emulator/flows/lib/filter_matrix.sh)"
seq1_line="$(grep -n 'matrix_case seq1' <<<"$seq_block" | cut -d: -f1)"
mur_line="$(grep -n 'PICK\[deity\]="\$SEQ_DEITY_PICK"' <<<"$seq_block" | cut -d: -f1)"
seq3_line="$(grep -n 'matrix_case seq3' <<<"$seq_block" | cut -d: -f1)"
back_line="$(grep -n "PICK\[deity\]='\^Shiva" <<<"$seq_block" | cut -d: -f1)"
if [[ -z "$seq1_line" || -z "$mur_line" || -z "$back_line" ]] || (( mur_line < seq1_line || back_line < seq3_line )); then
  echo "29j: seq1 must pick Shiva; Murugan only for seq2/seq3, then back to Shiva" >&2; exit 1
fi
pass
grep -qF "SEQ_DEITY_PICK='^Murugan( +[0-9]+)?\$'" tool/emulator/flows/lib/filter_matrix.sh \
  || { echo "29j must pick a deity present under Tamil Nadu / Madurai" >&2; exit 1; }
pass
# 29f real dump (all-India deity list at M): Shiva is below, a far fling.
got="$(python3 tool/emulator/lib/ui.py option-seek "$r4/29f-drawer-all-deity_drawer_all-deity-select.xml" \
  --kind deity --name Shiva --order deity,state,district --min-top 153 --max-top 537)"
[[ "$got" == "up far" ]] || { echo "29f real dump: Shiva should be 'up far', got '$got'" >&2; exit 1; }
pass
# Sheet model: Murugan is reachable in the deity list too.
sim_ok deity '^Murugan( +[0-9]+)?$' deity 'Murugan  10'

# Budgets: each probe has its own clock, actions their own (run 4: the
# third probe of every district case failed "case exceeded 90s").
for lib in filter_matrix filter_matrix_b; do
  bud_dir="$(mktemp -d)"
  # shellcheck disable=SC2030,SC2031
  (
    set -uo pipefail
    export EMULATOR_FLOW=29e-budget EMULATOR_ARTIFACTS="$bud_dir" EMULATOR_PACKAGE=com.example
    # shellcheck disable=SC1091
    source tool/emulator/lib/common.sh
    # shellcheck disable=SC1090
    source "tool/emulator/flows/lib/${lib}.sh"
    step_shot() { :; }
    : > "$RESULTS"
    [[ "$(actions_budget state:select district:select)" == 180 ]] || { echo "$lib: actions_budget state+district" >&2; exit 1; }
    [[ "$(actions_budget deity:select)" == 130 ]] || { echo "$lib: actions_budget deity" >&2; exit 1; }
    set_case_need state:select district:select
    [[ "$CASE_NEED_S" == 205 ]] || { echo "$lib: CASE_NEED_S=$CASE_NEED_S" >&2; exit 1; }
    MATRIX_ENTRY=fake
    enter_fake() { return 0; }
    # Actions take 70s (old single 90s budget left 20s for four probes).
    do_action() { SECONDS=$((SECONDS + 35)); STATE_APPLIED=1; return 0; }
    # Each probe takes 25s: passes on its own 40s clock.
    probe() { SECONDS=$((SECONDS + 25)); return 0; }
    district_in_bar() { return 0; }
    flow_over() { return 1; }
    run_case case1 state:select district:select
    [[ "$(grep -c '^PASS 29e-budget: case1' "$RESULTS")" -eq 5 ]] || { echo "$lib: 25s probes must all pass:"; cat "$RESULTS"; } >&2
    [[ "$(grep -c '^PASS 29e-budget: case1' "$RESULTS")" -eq 5 ]] || exit 1
    ! grep -q '^FAIL' "$RESULTS" || { echo "$lib: no FAIL expected" >&2; cat "$RESULTS" >&2; exit 1; }
    [[ "$CASE_MAX" == 90 ]] || { echo "$lib: CASE_MAX not restored ($CASE_MAX)" >&2; exit 1; }
    # A 50s probe is over its own 40s budget: FAIL, rest NOT RUN.
    : > "$RESULTS"
    probe() { SECONDS=$((SECONDS + 50)); return 0; }
    run_case case2 state:select district:select
    grep -q '^FAIL 29e-budget: case2-then-state: probe took 5[0-9]s, over its 40s budget' "$RESULTS" \
      || { echo "$lib: slow probe must FAIL:"; cat "$RESULTS"; exit 1; } >&2
    # Actions over their budget: the case FAILs, probes NOT RUN.
    : > "$RESULTS"
    do_action() { SECONDS=$((SECONDS + 100)); return 0; }
    run_case case3 state:select district:select
    grep -q '^FAIL 29e-budget: case3: actions took' "$RESULTS" \
      || { echo "$lib: slow actions must FAIL:"; cat "$RESULTS"; exit 1; } >&2
    ! grep -q '^PASS' "$RESULTS" || { echo "$lib: no PASS after slow actions" >&2; exit 1; }
  ) > "$bud_dir/out" 2>&1 || { cat "$bud_dir/out" >&2; exit 1; }
  pass
  rm -rf "$bud_dir"
done

PASS="$(wc -l < "$PASS_FILE" | tr -d ' ')"
rm -f "$PASS_FILE"
echo "${PASS} self-test checks passed"
echo "emulator self-test ok"
