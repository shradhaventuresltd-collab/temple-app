#!/usr/bin/env bash
# shellcheck disable=SC2030,SC2031 # test fixtures export env inside subshells on purpose
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


# A clean full-tier run for the release gate: every planned flow PASSes
# (planned skips SKIPPED), and every shard artifact is present under
# <dir>/shards/emulator-app-test-<n>/results.txt (EMULATOR_SHARD_RESULTS).
gate_clean_results() { # dir [missing-shard]
  local d="$1" miss="${2:-}" n
  bash -c 'source tool/emulator/plan.sh
    for id in $(plan_ids full); do
      if plan_is_skipped "$id"; then echo "SKIPPED ${id}: location-dependent, skipped on the emulator (EMULATOR_SKIP_FLOWS)"
      else printf "START %s\nPASS %s: ok\nDONE %s\n" "$id" "$id" "$id"; fi
    done' > "${d}/results.txt"
  for n in $(bash -c 'source tool/emulator/plan.sh; seq 1 "$SHARD_COUNT"'); do
    mkdir -p "${d}/shards/emulator-app-test-${n}"
    [[ "$n" == "$miss" ]] && continue
    bash -c 'source tool/emulator/plan.sh
      for id in $(plan_ids full "$1"); do echo "PASS ${id}: ok"; done' _ "$n" > "${d}/shards/emulator-app-test-${n}/results.txt"
  done
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
if ! grep -q 'select_labeled: gave up' tool/emulator/lib/common.sh; then
  echo "select_labeled must say when it hits its cap" >&2
  exit 1
fi
# The picker gives up after a bounded 20s walk (Confluence 12353537 A).
# shellcheck disable=SC2016 # literal source text, not an expansion
if ! grep -Fq 'PICKER_GIVEUP_S="${EMULATOR_PICKER_GIVEUP_S:-20}"' tool/emulator/lib/common.sh; then
  echo "picker give-up should default to 20s" >&2
  exit 1
fi
# shellcheck disable=SC2016 # literal source text
if ! grep -Fq 'deadline=$((started + PICKER_GIVEUP_S))' tool/emulator/lib/common.sh; then
  echo "select_labeled should use PICKER_GIVEUP_S for its deadline" >&2
  exit 1
fi
if grep -Eq 'deadline=\$\(\(started \+ [0-9]+\)\)' tool/emulator/lib/common.sh; then
  echo "select_labeled must not hard-code its give-up seconds" >&2
  exit 1
fi
if [[ "$(EMULATOR_FLOW=self-test EMULATOR_ARTIFACTS="$(mktemp -d)" bash -c 'unset EMULATOR_PICKER_GIVEUP_S; source tool/emulator/lib/common.sh; echo "$PICKER_GIVEUP_S"')" != 20 ]]; then
  echo "PICKER_GIVEUP_S should resolve to 20 when unset" >&2
  exit 1
fi
if ! grep -q 'picker scroll gave up' tool/emulator/flows/22_filter_combos_reset.sh; then
  echo "flow 22 should fail when the picker scroll hits its cap" >&2
  exit 1
fi
# ---- Workflow shape (Confluence 12353537 B/C/D/E) ----
# Every step in every job has its own timeout-minutes.
if ! awk '
  function check() { if (in_step && !has_timeout) { print "step without timeout-minutes: " name > "/dev/stderr"; bad = 1 } }
  /^      - name: / { check(); in_step = 1; has_timeout = 0; name = $0; next }
  /^  [a-z][a-z-]*:$/ { check(); in_step = 0 }
  in_step && /^        timeout-minutes: / { has_timeout = 1 }
  END { check(); exit bad }
' "$workflow"; then
  echo "every workflow step needs timeout-minutes" >&2
  exit 1
fi
for job in gate build emulator summary; do
  if ! awk -v job="$job" '
    $0 == "  " job ":" { in_job = 1; next }
    in_job && /^  [a-z][a-z-]*:$/ { exit }
    in_job && /^    timeout-minutes: / { found = 1 }
    END { exit !found }
  ' "$workflow"; then
    echo "job ${job} needs timeout-minutes" >&2
    exit 1
  fi
done
# Triggers (Sanu): smoke on PRs; full only on dispatch and release.
on_keys="$(awk '/^on:$/ { o = 1; next } o && /^[a-z]/ { exit } o && /^  [a-z_]+:/ { sub(/:.*/, ""); sub(/^  /, ""); print }' "$workflow" | tr '\n' ' ')"
if [[ "$on_keys" != "workflow_dispatch pull_request release " ]]; then
  echo "triggers should be exactly workflow_dispatch, pull_request, release; got: ${on_keys}" >&2
  exit 1
fi
if grep -Eq '^\s+(schedule|push):|cron:' "$workflow"; then
  echo "no push-to-main or nightly schedule: the full suite runs on dispatch and release only" >&2
  exit 1
fi
if ! grep -Fq 'types: [published]' "$workflow"; then
  echo "release runs should use types [published] (covers pre-releases)" >&2
  exit 1
fi
if [[ -e tool/emulator/nightly_gate.sh ]]; then
  echo "nightly_gate.sh should be gone with the nightly schedule" >&2
  exit 1
fi
# Release gate: the summary prints the tested 40-char SHA, and only a
# build-mode run may present it as tested.
# shellcheck disable=SC2016 # literal workflow text
if ! grep -Fq 'tested_sha: ${{ steps.tested-sha.outputs.sha }}' "$workflow" ||
   ! grep -Fq 'apk_source: ${{ steps.tested-sha.outputs.source }}' "$workflow" ||
   ! grep -Fq 'TESTED_SHA: ${{ needs.build.outputs.tested_sha }}' "$workflow" ||
   ! grep -Fq 'APK_SOURCE: ${{ needs.build.outputs.apk_source }}' "$workflow" ||
   ! grep -Fq 'sha="$(git -C build-src rev-parse HEAD)"' "$workflow" ||
   ! grep -Fq 'run: bash tool/emulator/release_gate.sh "$TIER" "$TESTED_SHA" "$APK_SOURCE"' "$workflow"; then
  echo "summary should print the release gate via release_gate.sh with the APK source" >&2
  exit 1
fi
if ! grep -q '\^\[0-9a-f\]{40}\$' "$workflow" || ! grep -q '\^\[0-9a-f\]{40}\$' tool/emulator/release_gate.sh; then
  echo "tested SHA must be validated as 40 hex characters in build and summary" >&2
  exit 1
fi
gate_sha=0123456789abcdef0123456789abcdef01234567
gate_sum="$(mktemp)"
gate_art="$(mktemp -d)"
printf 'START 01-first-launch\nPASS 01-first-launch: launch\nDONE 01-first-launch\n' > "${gate_art}/results.txt"
export EMULATOR_ARTIFACTS="$gate_art"
GITHUB_STEP_SUMMARY="$gate_sum" bash tool/emulator/release_gate.sh full "$gate_sha" build >/dev/null
if ! grep -Fq "### Release gate" "$gate_sum" || ! grep -Fq "suite ran on commit \`${gate_sha}\`." "$gate_sum" || grep -q UNVERIFIED "$gate_sum"; then
  echo "release gate: build mode must present the SHA as tested" >&2; cat "$gate_sum" >&2; exit 1
fi
for gate_mode in url artifact; do
  : > "$gate_sum"
  GITHUB_STEP_SUMMARY="$gate_sum" bash tool/emulator/release_gate.sh full "$gate_sha" "$gate_mode" >/dev/null
  if ! grep -Fq "SHA UNVERIFIED, not valid as release gate" "$gate_sum" || grep -Fq "suite ran on commit" "$gate_sum"; then
    echo "release gate: ${gate_mode} mode must print 'SHA UNVERIFIED, not valid as release gate'" >&2; cat "$gate_sum" >&2; exit 1
  fi
done
if bash tool/emulator/release_gate.sh full abc build >/dev/null 2>&1 ||
   bash tool/emulator/release_gate.sh full "$gate_sha" other >/dev/null 2>&1; then
  echo "release gate: a short SHA or an unknown source must fail" >&2; exit 1
fi
# The gate reads the results and refuses any FAIL, XFAIL or XPASS (a known
# bug is still in the release), and missing results.
for bad in "FAIL 25-directions-edge: single-maps-launch: double tap started Maps 2 times (want 1)" \
           "XFAIL 27-offline-cold-start: recover: KAN-186: did not recover after network on" \
           "XPASS 27-offline-cold-start: recover: KAN-186: did not recover after network on" ""; do
  printf 'PASS 01-first-launch: launch\n%s\n' "$bad" > "${gate_art}/results.txt"
  [[ -z "$bad" ]] && : > "${gate_art}/results.txt"
  : > "$gate_sum"
  if out="$(EMULATOR_GATE_EVENT=release GITHUB_STEP_SUMMARY="$gate_sum" bash tool/emulator/release_gate.sh full "$gate_sha" build 2>&1)" ||
     [[ "$out" != *"NOT a release gate"* ]] || ! grep -q "NOT a release gate" "$gate_sum"; then
    echo "release gate must refuse (exit 1) a release with: '${bad:-no results}'" >&2; echo "$out" >&2; exit 1
  fi
  for ev in workflow_dispatch pull_request; do
    : > "$gate_sum"
    if ! out="$(EMULATOR_GATE_EVENT="$ev" GITHUB_STEP_SUMMARY="$gate_sum" bash tool/emulator/release_gate.sh full "$gate_sha" build 2>&1)" ||
       [[ "$out" != *"NOT a release gate"* ]] || ! grep -q "NOT a release gate" "$gate_sum"; then
      echo "release gate on ${ev}: print 'NOT a release gate' with '${bad:-no results}' and exit 0" >&2; echo "$out" >&2; exit 1
    fi
  done
done
unset EMULATOR_ARTIFACTS
rm -rf "$gate_art"
rm -f "$gate_sum"
# summarize.sh lists XFAIL prominently and fails on XPASS.
sum_art="$(mktemp -d)"
{
  echo "START 27-offline-cold-start"; echo "PASS 27-offline-cold-start: offline-home"
  echo "XFAIL 27-offline-cold-start: recover: KAN-186: did not recover after network on"
  echo "DONE 27-offline-cold-start"
} > "${sum_art}/results.txt"
sum_md="$(mktemp)"
sum_out="$(EMULATOR_TIER=all EMULATOR_ARTIFACTS="$sum_art" GITHUB_STEP_SUMMARY="$sum_md" bash tool/emulator/summarize.sh 2>&1)" || true
if ! grep -q '^#### Expected failures (XFAIL: 1)' "$sum_md" || ! grep -q '^- XFAIL 27-offline-cold-start: recover: KAN-186' "$sum_md" ||
   ! grep -q '^XFAIL (1):' <<<"$sum_out" || ! grep -q '1 expected failures, 0 unexpected passes' <<<"$sum_out"; then
  echo "summarize.sh: XFAIL count and list must be in the summary and on stdout" >&2; echo "$sum_out" >&2; cat "$sum_md" >&2; exit 1
fi
sed -i 's/^XFAIL 27-offline-cold-start: recover/XPASS 27-offline-cold-start: recover/' "${sum_art}/results.txt"
if sum_out="$(EMULATOR_TIER=all EMULATOR_ARTIFACTS="$sum_art" GITHUB_STEP_SUMMARY=/dev/null bash tool/emulator/summarize.sh 2>&1)" ||
   ! grep -q '^::error::XPASS 27-offline-cold-start: recover' <<<"$sum_out"; then
  echo "summarize.sh: an XPASS must fail the job with ::error::" >&2; echo "$sum_out" >&2; exit 1
fi
rm -rf "$sum_art" "$sum_md"
if [[ "$(grep -c 'uses: reactivecircus/android-emulator-runner@' "$workflow")" -ne 3 ]]; then
  echo "expected 3 emulator steps (warm-up snapshot, fallback snapshot plus one flow run per shard job)" >&2
  exit 1
fi
# Both boots use the same emulator options (run 41314245431: the flow boot
# could not load the snapshot saved minutes earlier in the same job).
# shellcheck disable=SC2016 # literal workflow text
if [[ "$(grep -F -c 'emulator-options: ${{ env.EMULATOR_OPTIONS }}' "$workflow")" -ne 3 ]] ||
   grep -q 'EMULATOR_SNAPSHOT_OPTIONS' "$workflow"; then
  echo "snapshot creation and the flow run must both use EMULATOR_OPTIONS" >&2
  exit 1
fi
# shellcheck disable=SC2016 # literal workflow text
if ! grep -Fq 'script: bash tool/emulator/run_shard.sh ${{ needs.build.outputs.tier }}' "$workflow"; then
  echo "the flow step should run run_shard.sh for this job's tier" >&2
  exit 1
fi
if grep -q 'run_one_flow.sh' "$workflow"; then
  echo "flows run through run_shard.sh, not one emulator boot per flow" >&2
  exit 1
fi
options_line="$(grep -F 'EMULATOR_OPTIONS:' "$workflow")"
if [[ "$options_line" == *"-wipe-data"* ]]; then
  echo "the single boot should load the snapshot; pm clear replaces -wipe-data" >&2
  exit 1
fi
if [[ "$options_line" != *"-no-snapshot-save"* ]]; then
  echo "flow boots must not write back to the cached snapshot" >&2
  exit 1
fi
if [[ "$options_line" == *" -no-snapshot "* || "$options_line" == *" -no-snapshot-load"* ]]; then
  echo "flow boots should load the clean snapshot" >&2
  exit 1
fi
if ! grep -Fq 'script: bash tool/emulator/snapshot_create.sh' "$workflow" ||
   ! grep -q 'adb emu avd snapshot save default_boot' tool/emulator/snapshot_create.sh ||
   grep -Eq 'adb (install|shell pm install)' tool/emulator/snapshot_create.sh; then
  echo "snapshot step saves the snapshot explicitly and installs no app" >&2
  exit 1
fi
# Round 4.3: the AVD cache is saved once, by the avd-warmup job that every
# shard needs, only after the clean snapshot boot, the image check and the
# snapshot config check; no shard saves it (run 41391038302 cache race).
if ! grep -Fq "if: steps.create-avd.outcome == 'success' && steps.sysimg-check.outputs.same == 'true' && steps.snapcfg.outcome == 'success'" "$workflow" ||
   [[ "$(grep -c '^      - name: Save AVD cache$' "$workflow")" -ne 1 ]] ||
   ! grep -Fq 'needs: [gate, build, avd-warmup]' "$workflow" ||
   ! grep -Fq 'run: bash tool/emulator/check_snapshot_config.sh pre' "$workflow" ||
   grep -q "matrix.shard == '1'" "$workflow"; then
  echo "AVD cache should be saved by the avd-warmup job only, after the snapshot and config checks" >&2
  exit 1
fi
if [[ "$options_line" == *"-partition-size"* ]]; then
  echo "EMULATOR_OPTIONS must not carry -partition-size (run 41391038302: 2g overrode the snapshot's 6g)" >&2
  exit 1
fi
# The cached snapshot loads only on the AVD config it was saved with
# (run 41306793034: "cannot load snapshot ... different AVD configuration"
# after the emulator binary moved 37.2.12.0 -> 37.2.13.0). So the key is
# built from every input that shapes that config, the core count is known
# before the restore, and both emulator steps boot the same config.
if ! python3 - "$workflow" "$root/tool/emulator/avd_cache_key.sh" <<'PY'
import re, sys
wf = open(sys.argv[1]).read()
errs = []
keysh = open(sys.argv[2]).read()
key = re.search(r'^key="([^"]+)"$', keysh, re.M)
if "run: bash tool/emulator/avd_cache_key.sh\n" not in wf:
    errs.append("the AVD cache key step must run tool/emulator/avd_cache_key.sh")
if not key:
    errs.append("EMULATOR_AVD_CACHE_KEY is not computed in avd_cache_key.sh")
else:
    for part in ("${EMULATOR_API_LEVEL}", "${EMULATOR_TARGET}", "${EMULATOR_ARCH}", "${image}",
                 "${cores}", "${EMULATOR_DISK_SIZE}", "${EMULATOR_BUILD}", "${EMULATOR_AVD_NAME}", "clean"):
        if part not in key.group(1):
            errs.append(f"AVD cache key lacks {part}")
if not re.search(r'EMULATOR_BUILD: "\d+"', wf):
    errs.append("EMULATOR_BUILD must pin an emulator build number")
emu = wf[wf.index("\n  emulator:"):]
steps = [m.group(1) for m in re.finditer(r"^      - name: (.+)$", emu, re.M)]
def idx(prefix):
    for i, n in enumerate(steps):
        if n.startswith(prefix):
            return i
    errs.append(f"missing step {prefix!r}")
    return -1
order = [idx("Restore emulator system image"), idx("Choose emulator core count"),
         idx("Restore AVD cache"), idx("Create AVD snapshot"),
         idx("Check system image revision"), idx("Run emulator flows")]
if order != sorted(order):
    errs.append(f"step order must be image restore, key, restore, create, check, run: {order}")
warm = wf[wf.index("\n  avd-warmup:"):wf.index("\n  emulator:")]
wsteps = [m.group(1) for m in re.finditer(r"^      - name: (.+)$", warm, re.M)]
want = ["Restore emulator system image", "Choose emulator core count and AVD cache key", "Restore AVD cache",
        "Create AVD snapshot", "Check system image revision", "Verify snapshot config", "Save AVD cache"]
if [n for n in wsteps if n in want] != want:
    errs.append(f"avd-warmup step order must be {want}: {wsteps}")
if not re.search(r"- name: Save AVD cache\n        if: [^\n]*steps\.sysimg-check\.outputs\.same == 'true'", warm):
    errs.append("Save AVD cache must require the system image revision check")
if "run: bash tool/emulator/avd_cache_key.sh --check" not in emu:
    errs.append("Check system image revision must run avd_cache_key.sh --check")
runners = re.findall(r"uses: reactivecircus/android-emulator-runner@\S+.*?\n        with:\n(.*?)(?=\n\n|\n      - )", warm + emu, re.S)
cfg_keys = ("api-level", "target", "arch", "cores", "disk-size", "avd-name",
            "force-avd-creation", "disable-animations", "emulator-build")
cfgs = []
for body in runners:
    kv = dict(re.findall(r"^          ([a-z-]+): (.*)$", body, re.M))
    cfgs.append({k: kv.get(k) for k in cfg_keys})
if len(cfgs) != 3 or any(c != cfgs[0] for c in cfgs) or None in cfgs[0].values():
    errs.append(f"warm-up, snapshot and flow steps must boot the same AVD config: {cfgs}")
opts = [re.search(r"^          emulator-options: (.*)$", body, re.M).group(1) for body in runners]
if len(set(opts)) != 1:
    errs.append(f"both emulator boots must use identical options: {opts}")
if "avd-30-x86_64-google_apis-emulator-app-test-clean" in wf:
    errs.append("the old fixed AVD key (snapshot saved by emulator 37.2.12.0) must not be restored")
print("\n".join(errs), file=sys.stderr)
sys.exit(1 if errs else 0)
PY
then
  echo "AVD cache key must carry the AVD config, and cores must be chosen before the restore" >&2
  exit 1
fi
# avd_cache_key.sh against a stub SDK: the key carries the revision that the
# stub sdkmanager installs (an update from 5 to 6), a missing revision gives
# a one-run key, and --check refuses to save after the image moves.
key_tmp="$(mktemp -d)"
mkdir -p "$key_tmp/sdk/cmdline-tools/latest/bin" "$key_tmp/sdk/system-images/android-30/google_apis/x86_64"
key_props="$key_tmp/sdk/system-images/android-30/google_apis/x86_64/source.properties"
printf 'Pkg.Desc=Google APIs Intel x86_64 Atom System Image\nPkg.Revision=5\n' > "$key_props"
cat > "$key_tmp/sdk/cmdline-tools/latest/bin/sdkmanager" <<STUB
#!/usr/bin/env bash
[[ "\$1" == --install && "\$2" == 'system-images;android-30;google_apis;x86_64' && "\$3" == --channel=0 ]] || exit 0
printf 'Pkg.Desc=Google APIs Intel x86_64 Atom System Image\nPkg.Revision=6\n' > "$key_props"
STUB
chmod +x "$key_tmp/sdk/cmdline-tools/latest/bin/sdkmanager"
key_env=(ANDROID_HOME="$key_tmp/sdk" EMULATOR_API_LEVEL=30 EMULATOR_TARGET=google_apis
  EMULATOR_ARCH=x86_64 EMULATOR_DISK_SIZE=2048M EMULATOR_BUILD=16740729
  EMULATOR_AVD_NAME=emulator-app-test-30 GITHUB_RUN_ID=77 GITHUB_RUN_ATTEMPT=1)
env "${key_env[@]}" EMULATOR_NPROC=4 GITHUB_ENV="$key_tmp/env" bash tool/emulator/avd_cache_key.sh > /dev/null 2>&1
if ! grep -qx 'EMULATOR_AVD_CACHE_KEY=avd-30-google_apis-x86_64-img6-cores4-disk2048M-emu16740729-emulator-app-test-30-clean-cfg4' "$key_tmp/env" ||
  ! grep -qx 'EMULATOR_SYSIMG_REVISION=6' "$key_tmp/env" || ! grep -qx 'EMULATOR_CORES=4' "$key_tmp/env"; then
  echo "AVD cache key must carry the system image revision the emulator steps will boot" >&2
  cat "$key_tmp/env" >&2
  exit 1
fi
if [[ "$(env "${key_env[@]}" EMULATOR_SYSIMG_REVISION=6 GITHUB_OUTPUT=/dev/stdout bash tool/emulator/avd_cache_key.sh --check | tail -n 1)" != same=true ]]; then
  echo "--check must allow the save when the image revision is unchanged" >&2
  exit 1
fi
printf 'Pkg.Revision=7\n' > "$key_props"
if [[ "$(env "${key_env[@]}" EMULATOR_SYSIMG_REVISION=6 GITHUB_OUTPUT=/dev/stdout bash tool/emulator/avd_cache_key.sh --check | tail -n 1)" != same=false ]]; then
  echo "--check must refuse the save when the image revision moved" >&2
  exit 1
fi
rm -f "$key_props" "$key_tmp/sdk/cmdline-tools/latest/bin/sdkmanager"
env "${key_env[@]}" EMULATOR_NPROC=2 GITHUB_ENV="$key_tmp/env2" bash tool/emulator/avd_cache_key.sh > /dev/null 2>&1
if ! grep -qx 'EMULATOR_AVD_CACHE_KEY=avd-30-google_apis-x86_64-imgunknown-77-1-cores2-disk2048M-emu16740729-emulator-app-test-30-clean-cfg4' "$key_tmp/env2"; then
  echo "an unknown image revision must give a one-run AVD cache key" >&2
  cat "$key_tmp/env2" >&2
  exit 1
fi
rm -rf "$key_tmp"
if [[ "$(grep -F -c 'EMULATOR_AVD_CACHE_KEY' "$workflow")" -lt 3 ]]; then
  echo "restore and save should share EMULATOR_AVD_CACHE_KEY" >&2
  exit 1
fi
if ! grep -q 'actions: read' "$workflow" || grep -Eq '^\s+(contents|actions|pull-requests): write' "$workflow"; then
  echo "workflow token should be read-only (contents: read, actions: read)" >&2
  exit 1
fi
if grep -E 'secrets\.|google-services|keystore|\.jks' "$workflow" | grep -v 'No keystore' | grep -q .; then
  echo "emulator workflow must not use secrets, keystores, or google-services" >&2
  exit 1
fi
# shellcheck disable=SC2016 # literal workflow text
if [[ "$(grep -F -c 'if: ${{ !cancelled() && steps.resolve-apk.outcome' "$workflow")" -ne 1 ]]; then
  echo "the flow step should use !cancelled() so a real cancellation skips it" >&2
  exit 1
fi
# APK built once, reused as an artifact (B).
if [[ "$(grep -c 'flutter build apk' "$workflow")" -ne 1 ]]; then
  echo "the APK should be built once, in the build job" >&2
  exit 1
fi
if ! awk '
  /^  build:$/ { job = "build" } /^  emulator:$/ { job = "emulator" } /^  summary:$/ { job = "summary" }
  job == "build" && /name: emulator-apk$/ { up = 1 }
  job == "emulator" && /name: emulator-apk$/ { down = 1 }
  job != "build" && /flutter|setup-java|Cache Gradle/ { bad = 1 }
  END { exit !(up && down && !bad) }
' "$workflow"; then
  echo "build uploads emulator-apk; emulator jobs download it and never run Flutter/Gradle" >&2
  exit 1
fi
# shellcheck disable=SC2016 # literal workflow text
if ! grep -Fq 'shard: ${{ fromJSON(needs.build.outputs.matrix) }}' "$workflow" ||
   ! grep -Fq 'fail-fast: false' "$workflow"; then
  echo "emulator job should take its matrix from the build job, fail-fast off" >&2
  exit 1
fi
# shellcheck disable=SC2016 # literal workflow text
# Guardrails (architect, PR #126 review).
# (1) concurrency per event and ref; only pull request runs cancel.
# shellcheck disable=SC2016 # literal workflow text
# The tier is in the key so a smoke dispatch does not queue behind a full
# one on the same ref (runs 41306793034 / 41306882301).
if ! grep -Fxq "  group: emulator-app-test-\${{ github.event_name }}-\${{ (inputs.release_gate && 'full') || inputs.tier || (github.event_name == 'pull_request' && 'smoke') || 'full' }}-\${{ github.event.pull_request.number || github.ref }}" "$workflow" ||
   ! grep -Fxq "  cancel-in-progress: \${{ github.event_name == 'pull_request' }}" "$workflow"; then
  echo "concurrency group needs event_name, tier and ref; cancel-in-progress only for pull_request" >&2
  exit 1
fi
# (2) PR smoke: non-draft and only for app/test/CI paths.
pr_paths="$(awk '/^  pull_request:/ { p = 1; next } p && /^  [a-z_]+:/ { exit } p && /^      - / { print $2 }' "$workflow" | tr '\n' ' ')"
if [[ "$pr_paths" != "'lib/**' 'test/**' 'integration_test/**' 'android/**' 'assets/**' 'pubspec.*' 'tool/emulator/**' '.github/workflows/emulator-app-test.yml' " ]]; then
  echo "pull_request paths should be lib, test, integration_test, android, assets, pubspec, and the emulator CI files; got: ${pr_paths}" >&2
  exit 1
fi
if ! awk '/^  gate:$/ { g = 1 } g && /if: github.event_name != .pull_request. \|\| !github.event.pull_request.draft/ { f = 1 } END { exit !f }' "$workflow"; then
  echo "draft PRs must be skipped by the gate" >&2
  exit 1
fi
# (3) jobs after the gate fail open: they skip only on a skipped gate or
# run=false, never because the gate job failed.
fail_open="!cancelled() && needs.gate.result != 'skipped' && needs.gate.outputs.run != 'false'"
for job in build emulator summary; do
  job_if="$(awk -v job="$job" '$0 == "  " job ":" { j = 1; next } j && /^  [a-z][a-z-]*:$/ { exit } j && /^    if: / { sub(/^    if: /, ""); print; exit }' "$workflow")"
  job_needs="$(awk -v job="$job" '$0 == "  " job ":" { j = 1; next } j && /^  [a-z][a-z-]*:$/ { exit } j && /^    needs: / { print; exit }' "$workflow")"
  if [[ "$job_if" != "\${{ ${fail_open}"* || "$job_needs" != *gate* ]]; then
    echo "job ${job} must need gate and use the fail-open condition, got: ${job_if}" >&2
    exit 1
  fi
done
if grep -Fq "needs.gate.outputs.run == 'true'" "$workflow"; then
  echo "a failed gate (no output) must not skip the tests" >&2
  exit 1
fi
# Summary must go red on any real failure despite continue-on-error.
summary_job="$(awk '/^  summary:$/ { j = 1 } j { print }' "$workflow")"
if grep -q 'continue-on-error' <<<"$(awk '/name: Write combined summary/ { n = 1 } n { print } n && /run: bash tool\/emulator\/summarize.sh/ { exit }' <<<"$summary_job")"; then
  echo "the combined summary step must not use continue-on-error" >&2
  exit 1
fi
if ! grep -Fq "if: \${{ needs.emulator.result != 'success' }}" <<<"$summary_job" ||
   ! grep -q 'exit 1' <<<"$summary_job"; then
  echo "summary job should fail when a shard job did not succeed" >&2
  exit 1
fi
if ! awk '/name: Write results summary/ { n = 1 } n && /continue-on-error/ { bad = 1 } n && /run: bash tool\/emulator\/summarize.sh/ { exit !(!bad) }' "$workflow"; then
  echo "the shard summary step must not use continue-on-error" >&2
  exit 1
fi
merged_dir="$(mktemp -d)"
(
  # shellcheck source=SCRIPTDIR/plan.sh
  source tool/emulator/plan.sh
  for id in $(plan_ids all); do
    if plan_is_skipped "$id"; then
      printf 'SKIPPED %s: location-dependent\n' "$id"
    else
      printf 'START %s\nPASS %s: ok\nDONE %s\n' "$id" "$id" "$id"
    fi
  done
) > "$merged_dir/results.txt"
if ! EMULATOR_ARTIFACTS="$merged_dir" EMULATOR_TIER=all GITHUB_STEP_SUMMARY=/dev/null bash tool/emulator/summarize.sh >/dev/null 2>&1; then
  echo "a merged all-green run with SKIPPED flows should pass" >&2
  exit 1
fi
printf 'FAIL 05-search: query: no results\n' >> "$merged_dir/results.txt"
if EMULATOR_ARTIFACTS="$merged_dir" EMULATOR_TIER=all GITHUB_STEP_SUMMARY=/dev/null bash tool/emulator/summarize.sh >/dev/null 2>&1; then
  echo "combined summary must exit non-zero when a non-skipped flow fails" >&2
  exit 1
fi
rm -rf "$merged_dir"
# (4) manual runs stay available.
if ! grep -Eq '^  workflow_dispatch:' "$workflow"; then
  echo "workflow_dispatch must stay" >&2
  exit 1
fi
# shellcheck disable=SC2016 # literal workflow text
if ! grep -Fq 'EMULATOR_RESOLVE_OUTCOME: ${{ steps.resolve-apk.outcome }}' "$workflow"; then
  echo "summary step should receive the APK outcome" >&2
  exit 1
fi
# Step and job timeouts cover the worst case from plan.sh.
smoke_step="$(grep -E '^\s+timeout-minutes: \$\{\{ matrix.shard == .smoke. && [0-9]+ \|\| [0-9]+ \}\}$' "$workflow" | sed -n '2p')"
smoke_job="$(grep -E '^\s+timeout-minutes: \$\{\{ matrix.shard == .smoke. && [0-9]+ \|\| [0-9]+ \}\}$' "$workflow" | sed -n '1p')"
read -r step_smoke step_full < <(sed -E 's/.*&& ([0-9]+) \|\| ([0-9]+).*/\1 \2/' <<<"$smoke_step")
read -r job_smoke job_full < <(sed -E 's/.*&& ([0-9]+) \|\| ([0-9]+).*/\1 \2/' <<<"$smoke_job")
need_smoke="$(bash tool/emulator/plan.sh need-minutes smoke)"
if [[ -z "${step_smoke:-}" ]] || (( step_smoke < need_smoke )); then
  echo "smoke flow step timeout ${step_smoke:-unset} is under the ${need_smoke} min worst case" >&2
  exit 1
fi
for n in $(seq 1 "$(bash -c 'source tool/emulator/plan.sh; echo "$SHARD_COUNT"')"); do
  need="$(bash tool/emulator/plan.sh need-minutes full "$n")"
  if [[ -z "${step_full:-}" ]] || (( step_full < need )); then
    echo "shard ${n} step timeout ${step_full:-unset} is under its ${need} min worst case" >&2
    exit 1
  fi
done
# Job = flow step + setup (checkout, KVM, APK, caches, 15 min snapshot).
if (( job_smoke < step_smoke + 20 || job_full < step_full + 20 )); then
  echo "job timeouts should leave 20 min for setup beyond the flow step" >&2
  exit 1
fi
# Tier choice per event.
tier_out="$(mktemp)"
for pair in pull_request:smoke release:full workflow_dispatch:full; do
  : > "$tier_out"
  GITHUB_EVENT_NAME="${pair%%:*}" GITHUB_OUTPUT="$tier_out" INPUT_TIER="" bash tool/emulator/choose_tier.sh >/dev/null
  if ! grep -qx "tier=${pair##*:}" "$tier_out"; then
    echo "event ${pair%%:*} should pick tier ${pair##*:}" >&2
    exit 1
  fi
done
: > "$tier_out"
GITHUB_EVENT_NAME=workflow_dispatch GITHUB_OUTPUT="$tier_out" INPUT_TIER=smoke bash tool/emulator/choose_tier.sh >/dev/null
grep -qx 'matrix=\["smoke"\]' "$tier_out"
: > "$tier_out"
GITHUB_EVENT_NAME=release GITHUB_OUTPUT="$tier_out" bash tool/emulator/choose_tier.sh >/dev/null
grep -qxF "matrix=[$(seq -s, -f '"%g"' 1 "$(bash -c 'source tool/emulator/plan.sh; echo "$SHARD_COUNT"')")]" "$tier_out"
if GITHUB_EVENT_NAME=workflow_dispatch INPUT_TIER=everything bash tool/emulator/choose_tier.sh >/dev/null 2>&1; then
  echo "choose_tier.sh should reject an unknown tier" >&2
  exit 1
fi
for ev in push schedule; do
  if GITHUB_EVENT_NAME="$ev" bash tool/emulator/choose_tier.sh >/dev/null 2>&1; then
    echo "choose_tier.sh should reject ${ev}: it is no longer a trigger" >&2
    exit 1
  fi
done
rm -f "$tier_out"


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
  17a-entry-matrix-home-button
  17b-entry-matrix-drawer-all
  17c-entry-matrix-drawer-search
  17d-entry-matrix-list-drawer-all
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
  29a-filter-matrix-home-state
  29b-filter-matrix-home-district
  29c-filter-matrix-home-deity
  29d-filter-matrix-drawer-all-state
  29e-filter-matrix-drawer-all-district
  29f-filter-matrix-drawer-all-deity
  30a-filter-matrix-drawer-bar-state
  30b-filter-matrix-drawer-bar-district
  30c-filter-matrix-drawer-bar-deity
  30e-filter-matrix-search-state
  30f-filter-matrix-search-district
  30g-filter-matrix-search-deity
  30s-filter-matrix-sequences
  30d-near-me
)
for flow in "${flows[@]}"; do
  if ! grep -q "\"${flow}|" tool/emulator/plan.sh; then
    echo "plan.sh is missing ${flow}" >&2
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
if ! grep -qx 'FLOW_BUDGET=600' tool/emulator/run_one_flow.sh; then
  echo "each flow should run under the 600s per-flow cap" >&2
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
if grep -q 'district chip hidden"' tool/emulator/flows/29_filter_matrix.sh; then
  echo "flow 29 must not xfail a missing district chip unconditionally" >&2
  exit 1
fi
eval "$(sed -n '/^district_miss_outcome()/,/^}/p' tool/emulator/flows/29_filter_matrix.sh)"
if [[ "$(district_miss_outcome 0 0)" != xfail ]]; then
  echo "a missing district chip with no state selected should be xfail" >&2
  exit 1
fi
if [[ "$(district_miss_outcome 0 1)" != fail ]]; then
  echo "a missing district chip after a state was selected should fail" >&2
  exit 1
fi
if [[ "$(district_miss_outcome 1 0)" != fail || "$(district_miss_outcome 1 1)" != fail ]]; then
  echo "a district chip that is in the dump should not be xfail" >&2
  exit 1
fi
if ! grep -A3 '^enter_home_browse()' tool/emulator/flows/29_filter_matrix.sh | grep -q 'fresh_home'; then
  echo "flow 29 should return home between cases" >&2
  exit 1
fi
if ! grep -q 'filter-district-loading' tool/emulator/flows/29_filter_matrix.sh; then
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
# Flows that never started are NOT RUN (the job still fails), skipped
# flows are SKIPPED, and neither is a FAIL (run 41306793034 listed both
# as "FAIL missing").
unstarted_n="$(grep -c '^NOT RUN [^:]*: did not start$' "${summary_dir}/results.txt")"
skipped_n="$(grep -c '^SKIPPED ' "${summary_dir}/results.txt")"
if [[ "$unstarted_n" -ne 42 || "$skipped_n" -ne 3 ]] ||
   ! grep -q '^SKIPPED 30d-near-me: ' "${summary_dir}/results.txt" ||
   grep -q '^FAIL ' "${summary_dir}/results.txt" ||
   ! grep -q '^SKIPPED 11-near-me: ' "${summary_dir}/results.txt" ||
   ! grep -q '^SKIPPED 23-near-me-settings-roundtrip: ' "${summary_dir}/results.txt" ||
   ! grep -q '0 failed, 0 expected failures, 0 unexpected passes, 42 not run, 3 skipped' "${summary_dir}/fail.out" ||
   ! grep -q 'did not start' "${summary_dir}/fail.out"; then
  echo "unstarted flows: 42 NOT RUN, 3 SKIPPED (11, 23, 30d), no FAIL, job not green" >&2
  cat "${summary_dir}/fail.out" >&2
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
if [[ "$not_run" -ne 42 ]] || [[ "$(grep -c '^SKIPPED ' "${not_run_dir}/results.txt")" -ne 3 ]]; then
  echo "expected 42 NOT RUN and 3 SKIPPED lines, found ${not_run} NOT RUN" >&2
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
# shellcheck disable=SC2030,SC2031 # exports stay inside this subshell on purpose
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

# ---- Tiers, shards, skips (Confluence 12353537 C/D/E) ----
# shellcheck source=SCRIPTDIR/plan.sh
source tool/emulator/plan.sh
if [[ "$FLOW_CAP_S" -ne 600 ]] || ! grep -qx "FLOW_BUDGET=${FLOW_CAP_S}" tool/emulator/run_one_flow.sh; then
  echo "plan.sh FLOW_CAP_S and run_one_flow.sh FLOW_BUDGET must both be 600" >&2
  exit 1
fi
smoke_got="$(plan_ids smoke | tr '\n' ' ')"
if [[ "$smoke_got" != "01-first-launch 04-home 05-search 08-list-detail 14-back-relaunch 15-offline " ]]; then
  echo "smoke tier must be flows 01 04 05 08 14 15, got: ${smoke_got}" >&2
  exit 1
fi
for id in $(plan_ids smoke); do
  if plan_is_skipped "$id"; then
    echo "smoke flow ${id} must not be skipped" >&2
    exit 1
  fi
done
if [[ "$(plan_matrix full)" != "[$(seq -s, -f '"%g"' 1 "$SHARD_COUNT")]" || "$(plan_matrix smoke)" != '["smoke"]' ]]; then
  echo "full must be ${SHARD_COUNT} shards and smoke one job" >&2
  exit 1
fi
all_ids="$(plan_ids all | sort)"
shard_ids="$(for n in $(seq 1 "$SHARD_COUNT"); do plan_ids full "$n"; done | sort)"
if [[ "$all_ids" != "$shard_ids" ]]; then
  echo "the ${SHARD_COUNT} shards must cover every flow exactly once" >&2
  diff <(echo "$all_ids") <(echo "$shard_ids") >&2 || true
  exit 1
fi
if [[ -n "$(printf '%s\n' "$shard_ids" | uniq -d)" ]]; then
  echo "a flow is in two shards" >&2
  exit 1
fi
if [[ "$(printf '%s\n' "$all_ids" | wc -l)" -ne "${#flows[@]}" ]]; then
  echo "plan.sh should hold the ${#flows[@]} known flows" >&2
  exit 1
fi
while read -r _id script _part; do
  if [[ ! -f "$script" ]]; then
    echo "plan.sh points at a missing script ${script}" >&2
    exit 1
  fi
done < <(plan_flows all)
for script in tool/emulator/flows/*.sh; do
  if ! grep -q "|${script}|" tool/emulator/plan.sh; then
    echo "plan.sh does not run ${script}" >&2
    exit 1
  fi
done
# Round 4 (run 41373837994: 17/29/30 at the 600s cap): 17 in parts a/b,
# the filter matrix one entry x chip per flow, every cell covered once.
if [[ "$(plan_flows all | awk '$2 ~ /17_entry_matrix.sh$/ { print $3 }' | sort | paste -sd' ')" != "drawer_all drawer_search home_button list_drawer_all" ||
      "$(plan_flows all | awk '$1 == "29a-filter-matrix-home-state" { print $3 }')" != home_browse:state ||
      "$(plan_flows all | awk '$1 == "30s-filter-matrix-sequences" { print $3 }')" != seqs ]]; then
  echo "flow 17 must run one entry per flow (17a-17d) and the matrix entry:chip parts" >&2
  exit 1
fi
want_cells="$(for e in home_browse drawer_all drawer_bar search; do for c in state district deity; do echo "$e:$c"; done; done | sort)"
got_cells="$(plan_flows all | awk '$2 ~ /29_filter_matrix.sh$/ && $3 ~ /:/ && $3 !~ /^near_me:/ { print $3 }' | sort)"
# The near-me cells are a planned-skip row (30d), never silently dropped.
if [[ "$(plan_flows all | awk '$1 == "30d-near-me" { print $3 }')" != near_me:all ]] || ! (unset EMULATOR_SKIP_FLOWS; plan_is_skipped 30d-near-me); then
  echo "30d-near-me must be a planned-skip row running near_me:all" >&2; exit 1
fi
if [[ "$want_cells" != "$got_cells" ]]; then
  echo "filter matrix parts must cover every entry x chip exactly once: ${got_cells}" >&2
  exit 1
fi
for n in $(seq 1 "$SHARD_COUNT"); do
  active=0
  for id in $(plan_ids full "$n"); do
    plan_is_skipped "$id" || active=$((active + 1))
  done
  if (( active == 0 || active > 3 || active > SHARD_MAX_ACTIVE )); then
    echo "shard ${n} should run 1-3 flows that are not skipped, has ${active}" >&2
    exit 1
  fi
  if (( $(plan_need_s full "$n") > 39 * 60 )); then
    echo "shard ${n} worst case $(plan_need_s full "$n")s is over 39 min (incl. boot)" >&2
    exit 1
  fi
done
for id in 11-near-me 23-near-me-settings-roundtrip 30d-near-me; do
  if ! (unset EMULATOR_SKIP_FLOWS; plan_is_skipped "$id"); then
    echo "${id} must stay skipped as location-dependent" >&2
    exit 1
  fi
done
if EMULATOR_SKIP_FLOWS="" plan_is_skipped 11-near-me; then
  echo "EMULATOR_SKIP_FLOWS=\"\" should run the location flows" >&2
  exit 1
fi
for bad in "full 0" "full $((SHARD_COUNT + 1))" "full x" "nightly"; do
  # shellcheck disable=SC2086 # split tier and shard on purpose
  if plan_flows $bad >/dev/null 2>&1; then
    echo "plan_flows should reject '${bad}'" >&2
    exit 1
  fi
done
if bash tool/emulator/run_shard.sh full >/dev/null 2>&1; then
  echo "run_shard.sh full needs a shard number" >&2
  exit 1
fi
dry="$(EMULATOR_SHARD_DRY_RUN=1 EMULATOR_ARTIFACTS="$(mktemp -d)" bash tool/emulator/run_shard.sh full 2)"
if ! grep -qx 'PLAN 29b-filter-matrix-home-district tool/emulator/flows/29_filter_matrix.sh home_browse:district' <<<"$dry" ||
   [[ "$(grep -c '^PLAN ' <<<"$dry")" -ne "$(plan_ids full 2 | wc -l)" ]]; then
  echo "run_shard.sh dry run should list shard 2 with its matrix part" >&2
  echo "$dry" >&2
  exit 1
fi
# Replays on real dumps from PR #126 run 41306793034 (testdata/run41306793034,
# shard 4 flow 06: each filter sheet as it opened, and the list behind it).
# No device: ui_dump serves a fixture, adb shell calls are logged.
replay_dir="$(mktemp -d)"
# Stubs are called by the sourced library; the exports stay in the subshell.
# shellcheck disable=SC2030,SC2031,SC2329
replay() {
  local fixture="$1"
  shift
  (
    set -uo pipefail
    export EMULATOR_FLOW=06-filters EMULATOR_ARTIFACTS="$replay_dir/art" EMULATOR_PACKAGE=com.example
    # shellcheck disable=SC1091
    source tool/emulator/lib/common.sh
    ui_dump() { cp "tool/emulator/testdata/${REPLAY_DIR:-run41306793034}/${REPLAY_FIXTURE}" "$DUMP"; }
    ui_screen_size() { echo 320 640; }
    ui_tap() { echo "TAP ${UI_TEXT:-}" >> "$replay_dir/log"; }
    adb_shell_capped() { shift; echo "ADB $*" >> "$replay_dir/log"; }
    sleep() { :; }
    REPLAY_FIXTURE="$fixture"
    "$@"
  )
}
: > "$replay_dir/log"
# Picker: the all-India targets are on the sheet's first screen (tap, no swipe).
pick_regex="$(grep -h "^ALL_INDIA_" tool/emulator/lib/common.sh)"
for pick in "deity_sheet_open.xml:ALL_INDIA_DEITY_PICK:DEITY" "district_sheet_open.xml:ALL_INDIA_DISTRICT_PICK:DISTRICT"; do
  IFS=: read -r fx var section <<<"$pick"
  rx="$(sed -n "s/^${var}='\\(.*\\)'\$/\\1/p" <<<"$pick_regex")"
  : > "$replay_dir/log"
  if [[ -z "$rx" ]] || ! (replay "$fx" select_labeled "$rx" "$section") >/dev/null 2>&1 ||
     grep -q '^ADB input swipe' "$replay_dir/log" || ! grep -q '^TAP ' "$replay_dir/log"; then
    echo "${var} should be tapped on the real ${section} sheet's first screen, no swipe" >&2
    cat "$replay_dir/log" >&2
    exit 1
  fi
done
# The old targets are not on that screen: Shiva/Madurai need a scroll walk
# (they gave up at 20-21s in the run). On a frozen dump that walk ends unmatched.
: > "$replay_dir/log"
if (replay deity_sheet_open.xml select_labeled '^Shiva( +[0-9]+)?$' DEITY) >/dev/null 2>&1 ||
   ! grep -q '^ADB input swipe' "$replay_dir/log"; then
  echo "Shiva is not on the deity sheet's first screen; it needs a scroll" >&2
  exit 1
fi
# Picker swipes start inside the option scroller (ui.py sheet-band 251-569).
if [[ "$(python3 tool/emulator/lib/ui.py sheet-band tool/emulator/testdata/run41306793034/deity_sheet_open.xml)" != "251 569" ]] ||
   python3 tool/emulator/lib/ui.py sheet-band tool/emulator/testdata/run41306793034/browse_no_sheet.xml >/dev/null 2>&1; then
  echo "sheet-band: scroller 251-569 on the real sheet, exit 1 with no sheet" >&2
  exit 1
fi
: > "$replay_dir/log"
replay deity_sheet_open.xml eval 'ui_dump; ui_sheet_swipe up 95' >/dev/null 2>&1 || true
if ! grep -qx 'ADB input swipe 160 553 160 [0-9]* 900' "$replay_dir/log"; then
  echo "a picker swipe below the scroller must start at its bottom edge - 16 (553)" >&2
  cat "$replay_dir/log" >&2
  exit 1
fi
# Sheet gone under the walk (real list dump, which shows a Shiva card):
# fail at once, without swiping the list behind it.
: > "$replay_dir/log"
out="$( (replay browse_no_sheet.xml select_labeled '^Ahalya( +[0-9]+)?$' DEITY) 2>&1)" && {
  echo "select_labeled must fail when the sheet is gone" >&2; exit 1; }
if [[ "$out" != *"filter sheet is not on screen"* ]] || [[ "$(grep -c '^ADB input swipe' "$replay_dir/log")" -gt 1 ]]; then
  echo "select_labeled: a closed sheet fails fast (at most the one swipe that showed no movement)" >&2
  echo "$out" >&2
  cat "$replay_dir/log" >&2
  exit 1
fi
# Chip bar on a real dump from PR #126 run 41314245431 (shard 6, flow 22
# deity-scoped): state "Tamil Nadu" + district chips in a HorizontalScrollView
# at x 14-248, pinned Clear at 248-312, Deity chip off-screen right. The old
# fixed 80%->25% swipe started at x 256, on Clear, and never scrolled.
chip_fx=tool/emulator/testdata/run41314245431/chipbar_state_district_clear.xml
if [[ "$(python3 tool/emulator/lib/ui.py chip-bar "$chip_fx")" != "14 178 248 218" ]] ||
   python3 tool/emulator/lib/ui.py chip-bar tool/emulator/testdata/run41306793034/deity_sheet_open.xml >/dev/null 2>&1; then
  echo "chip-bar: scroller 14-248 (Clear excluded) on the real bar, exit 1 with no chip bar" >&2
  exit 1
fi
: > "$replay_dir/log"
if (REPLAY_DIR=run41314245431 replay chipbar_state_district_clear.xml find_filter_chip filter-chip-deity '^(Deity|All deities)$') >/dev/null 2>&1; then
  echo "find_filter_chip: the frozen dump has no Deity chip; it must fail" >&2; exit 1
fi
swipes="$(grep '^ADB input swipe' "$replay_dir/log")"
first="$(head -1 <<<"$swipes")"
if [[ "$first" != "ADB input swipe 236 198 26 198 300" ]] ||
   [[ "$(grep -c . <<<"$swipes")" -ne 8 ]] ||
   awk '{ for (i = 4; i <= 6; i += 2) if ($i < 14 || $i >= 248) bad = 1 } END { exit !bad }' <<<"$swipes"; then
  echo "find_filter_chip: 8 swipes inside the bar (14-248), right-to-left first, never on Clear" >&2
  echo "$swipes" >&2
  exit 1
fi
# A chip whose centre is under Clear (x 250) is not tappable: scroll, do not tap.
sed 's/bounds="\[179,181\]\[248,216\]"/bounds="[220,181][280,216]"/' "$chip_fx" > "$replay_dir/clipped.xml"
mkdir -p tool/emulator/testdata/.replay-tmp && cp "$replay_dir/clipped.xml" tool/emulator/testdata/.replay-tmp/clipped.xml
: > "$replay_dir/log"
(REPLAY_DIR=.replay-tmp replay clipped.xml find_filter_chip filter-chip-district '') >/dev/null 2>&1 || true
rm -rf tool/emulator/testdata/.replay-tmp
if ! grep -qx 'ADB input swipe 236 198 26 198 300' "$replay_dir/log"; then
  echo "find_filter_chip: a chip under the pinned Clear button must be scrolled into the bar" >&2
  cat "$replay_dir/log" >&2
  exit 1
fi
# Flow 06 stops after the first combined-* failure (run 41314245431: it ran
# on after combined-deity and hit the 600s cap).
if ! grep -q 'abort_after_combined_fail combined-deity' tool/emulator/flows/06_filters.sh ||
   [[ "$(grep -c -A1 'abort_after_combined_fail combined-' tool/emulator/flows/06_filters.sh | head -1)" == 0 ]]; then
  echo "flow 06 must stop after a combined step fails" >&2; exit 1
fi
abort_out="$(
  set -uo pipefail
  export EMULATOR_FLOW=06-filters EMULATOR_ARTIFACTS="$replay_dir/abort" EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  eval "$(sed -n '/^COMBINED_REST=/p; /^abort_after_combined_fail() {/,/^}/p' tool/emulator/flows/06_filters.sh)"
  abort_after_combined_fail combined-deity >/dev/null
  cat "$RESULTS"
)"
if [[ "$(grep -c '^NOT RUN 06-filters: ' <<<"$abort_out")" -ne 7 ]] || grep -q '^NOT RUN 06-filters: combined-deity:' <<<"$abort_out"; then
  echo "abort after combined-deity: the 7 later steps are NOT RUN" >&2
  echo "$abort_out" >&2
  exit 1
fi
# Flow 24/25/27 on real dumps from run 41314245431 shard 6.
fx126=tool/emulator/testdata/run41314245431
# shellcheck disable=SC2030,SC2031,SC2329
lib126() {
  (
    set -uo pipefail
    export EMULATOR_FLOW=25-directions-edge EMULATOR_ARTIFACTS="$replay_dir/f126" EMULATOR_PACKAGE=com.shradhaventures.temple
    # shellcheck disable=SC1091
    source tool/emulator/lib/common.sh
    PKG=com.shradhaventures.temple
    sleep() { :; }
    adb_shell_capped() { shift; echo "ADB $*" >> "$replay_dir/log"; }
    ui_back() { echo BACK >> "$replay_dir/log"; }
    # ui_dump serves the fixtures in SEQ in order, repeating the last one.
    ui_dump() {
      local n; n="$(grep -c '^DUMP' "$replay_dir/log" || true)"
      local -a seq; read -r -a seq <<<"$SEQ"
      (( n >= ${#seq[@]} )) && n=$((${#seq[@]} - 1))
      echo "DUMP ${seq[$n]}" >> "$replay_dir/log"
      cp "${fx126}/${seq[$n]}" "$DUMP"
    }
    "$@"
  )
}
# 24: the burst dump shows detail-gallery-4 with '5 / 5': consistent. The
# old '^1 / ' check called it a desync. A counter that disagrees fails.
: > "$replay_dir/log"
if ! (SEQ=gallery_burst_5of5.xml lib126 eval 'ui_dump; gallery_index_consistent'); then
  echo "gallery_index_consistent: detail-gallery-4 with '5 / 5' is consistent" >&2; exit 1
fi
sed 's/"5 \/ 5"/"1 \/ 5"/' "$fx126/gallery_burst_5of5.xml" > "$replay_dir/desync.xml"
cp "$replay_dir/desync.xml" "$fx126/.desync.xml"
desync_rc=0
(SEQ=.desync.xml lib126 eval 'ui_dump; gallery_index_consistent') || desync_rc=$?
rm -f "$fx126/.desync.xml"
if [[ "$desync_rc" -ne 1 ]]; then
  echo "gallery_index_consistent: detail-gallery-4 with '1 / 5' is a desync" >&2; exit 1
fi
if ! grep -q 'gallery_index_consistent' tool/emulator/flows/24_gallery_autoadvance_viewer.sh ||
   grep -q "text-regex '^1 / ' && pass_step swipe-burst-index" tool/emulator/flows/24_gallery_autoadvance_viewer.sh; then
  echo "flow 24 must check the counter against the page, after the burst settles" >&2; exit 1
fi
# 25: Maps "Update Google Maps to continue" swallows backs. Two Maps dumps,
# then detail: back_until_detail needs 3 backs and passes; Maps forever fails at the cap.
: > "$replay_dir/log"
# shellcheck disable=SC2016 # literal text, expanded later
if ! (SEQ="maps_update_prompt.xml maps_update_prompt.xml detail_with_directions.xml" lib126 eval 'back_until_detail 6 && [[ "$BACKS_USED" -eq 3 ]]'); then
  echo "back_until_detail: 3 backs to leave the Maps update prompt" >&2; cat "$replay_dir/log" >&2; exit 1
fi
: > "$replay_dir/log"
if (SEQ=maps_update_prompt.xml lib126 back_until_detail 6) || [[ "$(grep -c '^BACK' "$replay_dir/log")" -ne 6 ]]; then
  echo "back_until_detail: stays in Maps -> fail after exactly 6 backs" >&2; exit 1
fi
if grep -q 'ui_back; sleep 1; ui_back; sleep 1; ui_dump' tool/emulator/flows/25_directions_edge.sh; then
  echo "flow 25 must not rely on exactly two backs" >&2; exit 1
fi
# 27: KAN-186 fixed on main (#127): recover and chips-after-flap are plain
# PASS/FAIL assertions, no XFAIL left anywhere for KAN-186.
f27=tool/emulator/flows/27_offline_cold_start.sh
if grep -Eq 'xfail_known|xfail_step' "$f27" || grep -rq 'xfail_known [a-z-]* KAN-186' tool/emulator/flows ||
   ! grep -q 'pass_step recover ||' "$f27" || ! grep -q 'pass_step chips-after-flap ||' "$f27"; then
  echo "flow 27: recover and chips-after-flap must be normal assertions (KAN-186 fixed)" >&2; exit 1
fi
# Swipe-dismiss on each real sheet: a pull from the title centre (156,182)
# to 96% that is slow enough to deliver moves (300ms, retry 600ms), not 80ms.
for fx in state_sheet_open.xml deity_sheet_open.xml district_sheet_open.xml; do
  : > "$replay_dir/log"
  (replay "$fx" dismiss_sheet_swipe) >/dev/null 2>&1 || true
  if [[ "$(grep '^ADB input swipe' "$replay_dir/log")" != $'ADB input swipe 156 182 156 614 300\nADB input swipe 156 182 156 614 600' ]]; then
    echo "${fx}: swipe-dismiss should pull 156,182 -> 156,614 at 300ms then 600ms" >&2
    cat "$replay_dir/log" >&2
    exit 1
  fi
done
rm -rf "$replay_dir"

# Every planned flow runs, even when a flow reads stdin (adb shell does).
# The stub drains stdin, as adb did in run 41306793034, and records its id.
stub_dir="$(mktemp -d)"
cat >"${stub_dir}/flow.sh" <<'STUB'
#!/usr/bin/env bash
leaked="$(cat)"
printf '%s %s\n' "$1" "${#leaked}" >>"${STUB_LOG}"
STUB
tier_shards=(smoke); for n in $(seq 1 "$SHARD_COUNT"); do tier_shards+=("full $n"); done
for tier_shard in "${tier_shards[@]}"; do
  : >"${stub_dir}/ran"
  # shellcheck disable=SC2086 # split tier and shard on purpose
  STUB_LOG="${stub_dir}/ran" EMULATOR_FLOW_RUNNER="${stub_dir}/flow.sh" \
    EMULATOR_ARTIFACTS="${stub_dir}/art" bash tool/emulator/run_shard.sh $tier_shard >/dev/null 2>&1
  # shellcheck disable=SC2086
  want="$(plan_ids $tier_shard | while read -r f; do plan_is_skipped "$f" || echo "$f"; done)"
  got="$(cut -d' ' -f1 "${stub_dir}/ran")"
  if [[ "$got" != "$want" ]] || grep -qv ' 0$' "${stub_dir}/ran"; then
    echo "run_shard.sh ${tier_shard}: every planned flow must run with empty stdin" >&2
    echo "want: $(tr '\n' ' ' <<<"$want")" >&2
    echo "ran:  $(tr '\n' ' ' <"${stub_dir}/ran")" >&2
    exit 1
  fi
  if [[ "$(grep -c '^TIME ' "${stub_dir}/art/results.txt")" -lt "$(wc -l <<<"$want")" ]]; then
    echo "run_shard.sh ${tier_shard}: a TIME line per flow" >&2
    exit 1
  fi
  # shellcheck disable=SC2086
  for f in $(plan_ids $tier_shard); do
    if plan_is_skipped "$f" && ! grep -q "^SKIPPED ${f}: " "${stub_dir}/art/results.txt"; then
      echo "run_shard.sh ${tier_shard}: skipped ${f} must be recorded SKIPPED at plan time" >&2
      exit 1
    fi
  done
  rm -rf "${stub_dir}/art"
done
rm -rf "$stub_dir"

if ! grep -q 'EMULATOR_REUSE_INSTALL=1' tool/emulator/run_shard.sh ||
   ! grep -q 'clear_app_data' tool/emulator/run_one_flow.sh ||
   ! grep -q 'reset_device_state' tool/emulator/run_one_flow.sh; then
  echo "a reused emulator must reset the device and pm clear between flows" >&2
  exit 1
fi

# plan.sh with no arguments prints one usage line and exits non-zero.
if plan_noarg="$(bash tool/emulator/plan.sh 2>&1)"; then
  echo "plan.sh with no arguments must exit non-zero" >&2
  exit 1
fi
if [[ "$(printf '%s\n' "$plan_noarg" | wc -l)" -ne 1 || "$plan_noarg" != usage:* ]]; then
  echo "plan.sh with no arguments should print a single usage line, got: ${plan_noarg}" >&2
  exit 1
fi
# The emulator-apk artifact is only needed within the run: keep it 1 day.
if [[ "$(awk '/name: emulator-apk$/ { a = 1 } a && /retention-days:/ { print $2; exit }' "$workflow")" != 1 ]]; then
  echo "emulator-apk artifact retention should be 1 day" >&2
  exit 1
fi

# Skipped flow: SKIPPED line, no START, and the summary stays green.
skipf_dir="$(mktemp -d)"
EMULATOR_ARTIFACTS="$skipf_dir" EMULATOR_PACKAGE=com.example \
  bash tool/emulator/run_one_flow.sh 11-near-me tool/emulator/flows/11_near_me.sh >/dev/null
if ! grep -q '^SKIPPED 11-near-me: location-dependent' "$skipf_dir/results.txt" ||
   grep -q '^START 11-near-me' "$skipf_dir/results.txt"; then
  echo "a skipped flow should write SKIPPED and not start" >&2
  cat "$skipf_dir/results.txt" >&2
  exit 1
fi
: > "$skipf_dir/results.txt"
for id in $(plan_ids full 3); do
  if plan_is_skipped "$id"; then
    printf 'SKIPPED %s: location-dependent\n' "$id" >> "$skipf_dir/results.txt"
  else
    printf 'START %s\nPASS %s: ok\nDONE %s\n' "$id" "$id" "$id" >> "$skipf_dir/results.txt"
  fi
done
if ! EMULATOR_ARTIFACTS="$skipf_dir" EMULATOR_TIER=full EMULATOR_SHARD=3 GITHUB_STEP_SUMMARY=/dev/null \
  bash tool/emulator/summarize.sh > "$skipf_dir/out" 2>&1; then
  echo "a SKIPPED flow must not fail the shard summary" >&2
  cat "$skipf_dir/out" >&2
  exit 1
fi
if ! grep -q '1 skipped' "$skipf_dir/out"; then
  echo "summary should count skipped flows" >&2
  exit 1
fi
# Shard summary expects only its own flows; flow 01 is in shard 1.
if grep -q '^FAIL 01-first-launch' "$skipf_dir/results.txt"; then
  echo "shard 3 summary should not require flows from other shards" >&2
  exit 1
fi
if EMULATOR_ARTIFACTS="$skipf_dir" EMULATOR_TIER=all GITHUB_STEP_SUMMARY=/dev/null \
  bash tool/emulator/summarize.sh >/dev/null 2>&1; then
  echo "tier all summary must fail when shard 1 flows are missing" >&2
  exit 1
fi
rm -rf "$skipf_dir"

# pm clear and device reset against a stub adb.
reuse_dir="$(mktemp -d)"
reuse_bin="$(mktemp -d)"
cat > "$reuse_bin/adb" << 'STUB'
#!/bin/bash
printf '%s\n' "$*" >> "${STUB_ADB_LOG:?}"
case "$*" in
  "shell pm path com.example.temple") echo "package:/data/app/base.apk" ;;
  "shell pm clear com.example.temple") [[ -n "${STUB_PM_FAIL:-}" ]] && echo "Failed" || echo "Success" ;;
esac
exit 0
STUB
chmod +x "$reuse_bin/adb"
# shellcheck disable=SC2030,SC2031 # exports stay inside this subshell on purpose
(
  set -euo pipefail
  export STUB_ADB_LOG="$reuse_dir/adb.log"
  export PATH="$reuse_bin:$PATH"
  export EMULATOR_FLOW=04-home
  export EMULATOR_ARTIFACTS="$reuse_dir"
  export EMULATOR_PACKAGE=com.example.temple
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  : > "$RESULTS"
  app_installed
  reset_device_state
  clear_app_data
  for want in "shell wm size reset" "shell settings put system user_rotation 0" \
    "shell settings put secure location_mode 3" "shell pm clear com.example.temple" \
    "shell cmd connectivity airplane-mode disable" "shell svc wifi enable" "shell svc data enable" \
    "shell pm enable com.google.android.apps.maps" "shell settings put global animator_duration_scale 0" \
    "shell pm revoke com.example.temple android.permission.ACCESS_FINE_LOCATION" \
    "shell settings put system font_scale 1.0" "shell wm density reset"; do
    grep -qx "$want" "$STUB_ADB_LOG" || { echo "reset should run: ${want}" >&2; exit 1; }
  done
  if STUB_PM_FAIL=1 clear_app_data; then
    echo "a failed pm clear must fail the flow" >&2
    exit 1
  fi
  grep -q '^FAIL 04-home: pm-clear:' "$RESULTS"
  EMULATOR_PACKAGE="" PKG=other.pkg
  if app_installed; then
    echo "app_installed should be false for a package pm path does not know" >&2
    exit 1
  fi
)
rm -rf "$reuse_dir" "$reuse_bin"

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
rm -f "$fling_log"

# Snapshot config (run 41314245431): the runner action appends
# hw.cpu.ncore/disk.dataPartition.size to config.ini on every launch
# (testdata config_ini_appends.log: once in Create AVD snapshot, again in
# Run emulator flows), and the flow boot could not load the snapshot.
# prepare_avd.sh must leave config.ini byte-identical at both boots.
snap_dir="$(mktemp -d)"
avd="${snap_dir}/avd/emulator-app-test-30.avd"
mkdir -p "$avd"
printf 'avd.ini.encoding=UTF-8\nhw.cpu.ncore=2\nimage.sysdir.1=system-images/android-30/google_apis/x86_64/\nhw.ramSize=1536\n' > "${avd}/config.ini"
append() { printf 'hw.cpu.ncore=4\ndisk.dataPartition.size=2048M\n' >> "${avd}/config.ini"; }
prep() {
  ANDROID_AVD_HOME="${snap_dir}/avd" EMULATOR_AVD_NAME=emulator-app-test-30 EMULATOR_CORES=4 \
    EMULATOR_DISK_SIZE=2048M RUNNER_TEMP="${snap_dir}/tmp" PATH="${snap_dir}/bin:$PATH" \
    bash tool/emulator/prepare_avd.sh "$1" >/dev/null 2>&1
}
mkdir -p "${snap_dir}/bin"
printf '#!/bin/sh\nexit 0\n' > "${snap_dir}/bin/adb"; cp "${snap_dir}/bin/adb" "${snap_dir}/bin/pkill"; chmod +x "${snap_dir}/bin/"*
append; prep create; cp "${avd}/config.ini" "${snap_dir}/create.ini"
append; prep run; cp "${avd}/config.ini" "${snap_dir}/run.ini"
if ! cmp -s "${snap_dir}/create.ini" "${snap_dir}/run.ini" ||
   [[ "$(grep -c '^hw.cpu.ncore=' "${snap_dir}/run.ini")" -ne 1 ]] ||
   ! grep -qx 'hw.cpu.ncore=4' "${snap_dir}/run.ini" || ! grep -qx 'hw.ramSize=2048' "${snap_dir}/run.ini" ||
   ! grep -qx 'disk.dataPartition.size=2048M' "${snap_dir}/run.ini" ||
   ! grep -qx 'image.sysdir.1=system-images/android-30/google_apis/x86_64/' "${snap_dir}/run.ini" ||
   [[ ! -f "${snap_dir}/tmp/avd-ini/run-prelaunch/config.ini" ]]; then
  echo "prepare_avd.sh: config.ini must be identical at the snapshot and flow boots, one value per key" >&2
  diff "${snap_dir}/create.ini" "${snap_dir}/run.ini" >&2
  exit 1
fi
rm -rf "$snap_dir"
# Boot log check on real excerpts: the flow boot (cold) and the snapshot
# creation boot (no snapshot yet, not a failed load).
fx126=tool/emulator/testdata/run41314245431
if [[ "$(bash tool/emulator/boot_log_check.sh --file "$fx126/boot_cold_excerpt.log" s6 | head -1)" != "boot: cold (s6)" ]] ||
   ! bash tool/emulator/boot_log_check.sh --file "$fx126/boot_cold_excerpt.log" s6 | grep -q '^::warning::' ||
   [[ "$(bash tool/emulator/boot_log_check.sh --file "$fx126/boot_create_excerpt.log" s6)" != "boot: snapshot (s6)" ]]; then
  echo "boot_log_check.sh: 'cannot load snapshot'/'different AVD configuration' -> boot: cold + ::warning::" >&2
  exit 1
fi
# run_shard.sh boot marker: set by snapshot_create.sh before the save, so it
# survives only a snapshot restore.
boot_dir="$(mktemp -d)"
mkdir -p "${boot_dir}/bin"
# shellcheck disable=SC2016 # literal text, expanded later
printf '#!/bin/sh\n[ "$*" = "shell getprop debug.temple.snapshot_marker" ] && echo "${STUB_MARKER:-}"\nexit 0\n' > "${boot_dir}/bin/adb"
chmod +x "${boot_dir}/bin/adb"
printf '#!/bin/sh\nexit 0\n' > "${boot_dir}/flow.sh"
for m in 1 ""; do
  rm -rf "${boot_dir}/art"; : > "${boot_dir}/summary"
  out="$(STUB_MARKER="$m" PATH="${boot_dir}/bin:$PATH" EMULATOR_FLOW_RUNNER="${boot_dir}/flow.sh" \
    EMULATOR_ARTIFACTS="${boot_dir}/art" GITHUB_STEP_SUMMARY="${boot_dir}/summary" GITHUB_ENV="${boot_dir}/env" \
    bash tool/emulator/run_shard.sh full 6 2>&1)"
  want=snapshot; [[ -z "$m" ]] && want=cold
  if ! grep -qx "BOOT full-6 ${want}" "${boot_dir}/art/results.txt" || ! grep -qx "boot: ${want}" "${boot_dir}/summary" ||
     { [[ "$want" == cold ]] && ! grep -q '^::warning::.*cold-booted' <<<"$out"; } ||
     { [[ "$want" == snapshot ]] && grep -q '^::warning::' <<<"$out"; }; then
    echo "run_shard.sh: marker '${m}' must give BOOT ${want}" >&2; echo "$out" >&2; exit 1
  fi
done
rm -rf "$boot_dir"
if ! grep -q 'setprop debug.temple.snapshot_marker 1' tool/emulator/snapshot_create.sh ||
   ! grep -q 'run: bash tool/emulator/boot_log_check.sh' "$workflow" ||
   ! grep -Fq "name: emulator-avd-ini-\${{ matrix.shard }}" "$workflow" ||
   ! grep -Fq "env.EMULATOR_BOOT != 'snapshot' || steps.flows.outcome != 'success'" "$workflow" ||
   ! grep -q -- '-clean-cfg4"' tool/emulator/avd_cache_key.sh; then
  echo "snapshot diagnostics: marker, boot log check, ini artifact on cold boot/failure, bumped key" >&2
  exit 1
fi

# 24: the left flings must change the page; gallery_page reads it.
mkdir -p "$replay_dir"; : > "$replay_dir/log"
# shellcheck disable=SC2016 # literal text passed to eval / grep
if [[ "$(SEQ=gallery_burst_5of5.xml lib126 eval 'ui_dump; gallery_page')" != 4 ]] ||
   ! grep -q 'pass_step swipe-pages' tool/emulator/flows/24_gallery_autoadvance_viewer.sh ||
   ! grep -q '"$page_after" != "$page_before"' tool/emulator/flows/24_gallery_autoadvance_viewer.sh; then
  echo "flow 24: swipe-pages asserts the page changed (gallery_page = 4 on the burst dump)" >&2; exit 1
fi
rm -rf "$replay_dir"
# 25: exactly one Maps START after the double tap (real logcat line from
# run 41314245431; the 2-launch fixture repeats it 318 ms later).
maps_count() {
  EMULATOR_FLOW=x EMULATOR_ARTIFACTS="$(mktemp -d)" \
    bash -c 'source tool/emulator/lib/common.sh >/dev/null 2>&1; count_maps_starts' < "tool/emulator/testdata/run41314245431/$1"
}
f25=tool/emulator/flows/25_directions_edge.sh
# shellcheck disable=SC2016 # literal flow text
if [[ "$(maps_count maps_start_once.logcat.txt)" != 1 ]] || [[ "$(maps_count maps_start_twice.logcat.txt)" != 2 ]] ||
   ! grep -q 'fail_step single-maps-launch' "$f25" ||
   ! grep -Fq '"${maps_starts:-0}" -eq 1' "$f25" ||
   ! grep -q 'logcat_window_start directions-double-tap' "$f25" || ! grep -q 'window="$(logcat_window_read)"' "$f25" ||
   grep -q 'device_time\|logcat -c' "$f25" ||
   ! grep -q "echo \"directions: logcat window starts at device time" "$f25"; then
  echo "flow 25: single-maps-launch counts Maps START lines after the taps (1 passes, 2 fails)" >&2; exit 1
fi
# xfail_known (library) gives XFAIL while the check fails, XPASS once it passes.
xk="$(
  EMULATOR_ARTIFACTS="$(mktemp -d)"
  export EMULATOR_FLOW=27-offline-cold-start EMULATOR_ARTIFACTS EMULATOR_PACKAGE=com.example
  source tool/emulator/lib/common.sh >/dev/null 2>&1
  step_shot() { :; }
  xfail_known recover KAN-186 "did not recover" false >/dev/null
  xfail_known chips-after-flap KAN-186 "chips dead" true 2>&1 | grep '^::error::' || true
  cat "$RESULTS"
)"
if ! grep -qx 'XFAIL 27-offline-cold-start: recover: KAN-186: did not recover' <<<"$xk" ||
   ! grep -qx 'XPASS 27-offline-cold-start: chips-after-flap: KAN-186: chips dead' <<<"$xk" ||
   ! grep -q '^::error::XPASS 27-offline-cold-start: chips-after-flap' <<<"$xk"; then
  echo "xfail_known -> XFAIL on failure, XPASS + ::error:: on pass" >&2; echo "$xk" >&2; exit 1
fi
# 24: settle needs two consecutive consistent dumps on the same page.
# shellcheck disable=SC2016 # literal flow text
if ! grep -Fq 'cur_page" == "$prev_page"' tool/emulator/flows/24_gallery_autoadvance_viewer.sh; then
  echo "flow 24: two consecutive agreeing dumps" >&2; exit 1
fi
if grep -q '/tmp/n' tool/emulator/flows/25_directions_edge.sh; then
  echo "flow 25: no dead /tmp/n write" >&2; exit 1
fi
# snapshot_create.sh: a save that does not report OK fails the step (no cache save).
sc_dir="$(mktemp -d)"; mkdir -p "${sc_dir}/bin"
# shellcheck disable=SC2016 # literal stub script text
printf '#!/bin/sh\ncase "$*" in "emu avd snapshot save default_boot") echo "${STUB_SAVE:-KO: failed}";; esac\nexit 0\n' > "${sc_dir}/bin/adb"
chmod +x "${sc_dir}/bin/adb"
if PATH="${sc_dir}/bin:$PATH" RUNNER_TEMP="$sc_dir" bash tool/emulator/snapshot_create.sh >/dev/null 2>&1 ||
   ! STUB_SAVE=OK PATH="${sc_dir}/bin:$PATH" RUNNER_TEMP="$sc_dir" bash tool/emulator/snapshot_create.sh >/dev/null 2>&1; then
  echo "snapshot_create.sh: exit 1 on a failed save, 0 on OK" >&2; exit 1
fi
rm -rf "$sc_dir"
# Every testdata file this script uses is tracked (run 88a7569: *.log fixtures were gitignored).
if git rev-parse --git-dir >/dev/null 2>&1; then
  for f in tool/emulator/testdata/run41314245431/{boot_cold_excerpt,boot_create_excerpt,config_ini_appends}.log; do
    git ls-files --error-unmatch "$f" >/dev/null 2>&1 || { echo "testdata not tracked: $f" >&2; exit 1; }
  done
fi
# adb shell re-splits on the device. A stub adb that does the same (shlex
# on the joined words, like the device sh) exercises the REAL command
# construction of the logcat marker; the old cc3e912 split form must not
# survive it. The stub logcat buffer is never cleared: logcat -c fails the
# test, since later checks need the earlier lines.
rs_dir="$(mktemp -d)"; mkdir -p "${rs_dir}/bin"
cat > "${rs_dir}/bin/adb" <<'STUB'
#!/usr/bin/env bash
buf="${RS_DIR}/buffer"
[[ -f "$buf" ]] || echo "11-01 14:16:40.000  100  100 I Old     : line from before the window" > "$buf"
if [[ "$1" == shell ]]; then
  shift
  python3 - "$*" "$buf" "${RS_FIXTURE:-/dev/null}" <<'PY2'
import shlex, sys
argv = shlex.split(sys.argv[1])
if argv[:1] == ["date"]:
    if len(argv) == 2 and argv[1] == "+%m-%d %H:%M:%S":
        print("11-01 14:16:53\r")
    else:
        print("date: extra operand", file=sys.stderr); sys.exit(1)
elif argv[:3] == ["log", "-t", "TempleEmuMark"]:
    if len(argv) != 4:
        print("log: bad args", file=sys.stderr); sys.exit(1)
    with open(sys.argv[2], "a") as f:
        f.write("11-01 14:16:53.123  200  200 I TempleEmuMark: %s\n" % argv[3])
        f.write(open(sys.argv[3]).read())
PY2
  exit $?
fi
if [[ "$1" == logcat ]]; then
  case " $* " in
    *" -c "*) echo "cleared" > "${RS_DIR}/cleared"; exit 0 ;;
    *" -d "*) cat "$buf"; exit 0 ;;
  esac
fi
exit 0
STUB
chmod +x "${rs_dir}/bin/adb"
rs() {
  (
    export PATH="${rs_dir}/bin:$PATH" RS_DIR="$rs_dir" EMULATOR_FLOW=25-directions-edge EMULATOR_ARTIFACTS="${rs_dir}/art" EMULATOR_PACKAGE=com.example
    # shellcheck disable=SC1091
    source tool/emulator/lib/common.sh >/dev/null 2>&1
    "$@"
  )
}
# shellcheck disable=SC2016 # literal command for eval
if [[ -n "$(rs eval 'adb_shell_capped 8 date +"%m-%d %H:%M:%S.000" 2>/dev/null')" ]]; then
  echo "stub adb must reject the old split date form (else this test proves nothing)" >&2; exit 1
fi
# shellcheck disable=SC2016 # literal command for eval
if rs eval 'adb_shell_capped 8 log -t TempleEmuMark "two words" 2>/dev/null'; then
  echo "stub adb must reject an unquoted multi-word log message" >&2; exit 1
fi
count_maps_starts_st() { EMULATOR_FLOW=x EMULATOR_ARTIFACTS="$(mktemp -d)" bash -c 'source tool/emulator/lib/common.sh >/dev/null 2>&1; count_maps_starts'; }
for want in once:1 twice:2; do
  rm -f "${rs_dir}/buffer" "${rs_dir}/cleared"
  win="$(RS_FIXTURE="${fx126}/maps_start_${want%%:*}.logcat.txt" rs eval 'logcat_window_start t; logcat_window_read')"
  got="$(count_maps_starts_st <<< "$win")"
  if [[ "$got" != "${want##*:}" ]] || [[ -e "${rs_dir}/cleared" ]] ||
     [[ "$(head -n1 <<< "$win" | cut -c1-18)" != "11-01 14:16:53.123" ]] ||
     grep -q 'line from before the window' <<< "$win" ||
     ! grep -q 'line from before the window' "${rs_dir}/buffer"; then
    echo "logcat window: ${want%%:*} launch fixture -> ${want##*:} (got '${got}'), marker first, no logcat -c, earlier lines kept" >&2; exit 1
  fi
done
# 26: a crash on back must not pass back-exits.
crash_in() { rs eval "app_crashed_in_log com.example.temple" <<< "$1"; }
if ! crash_in "11-01 14:17:00.000 300 300 E AndroidRuntime: Process: com.example.temple, PID: 300" ||
   ! crash_in "11-01 14:17:00.000 1 1 E ActivityManager: ANR in com.example.temple (com.example.temple/.MainActivity)" ||
   ! crash_in "11-01 14:17:00.000 1 1 W ActivityTaskManager: Force finishing activity com.example.temple/.MainActivity" ||
   crash_in "11-01 14:17:00.000 1 1 E AndroidRuntime: Process: com.google.android.apps.maps, PID: 9" ||
   crash_in "11-01 14:17:00.000 1 1 I ActivityTaskManager: Displayed com.example.temple/.MainActivity"; then
  echo "app_crashed_in_log: our FATAL/ANR/force-finish only" >&2; exit 1
fi
f26=tool/emulator/flows/26_drawer_nav_stack.sh
# shellcheck disable=SC2016 # literal flow text
if ! grep -q 'logcat_window_start back-exits' "$f26" || ! grep -q 'app_crashed_in_log "$PKG" <<<"$window"' "$f26" ||
   ! grep -q 'fail_step back-exits "TempleEmuMark logcat marker missing' "$f26" ||
   ! grep -q 'fail_step back-exits "app crashed on back from Home' "$f26"; then
  echo "flow 26 back-exits must fail on a crash (logcat or dialog)" >&2; exit 1
fi
rm -rf "$rs_dir"
# 06 / 26: by-design behaviour is a PASS assertion, not an XFAIL.
if grep -q 'xfail' tool/emulator/flows/06_filters.sh tool/emulator/flows/26_drawer_nav_stack.sh ||
   ! grep -q 'pass_step force-stop-resets-filter' tool/emulator/flows/06_filters.sh ||
   ! grep -q 'fail_step back-exits "app still focused after back on Home"' tool/emulator/flows/26_drawer_nav_stack.sh; then
  echo "flow 06 force-stop-resets-filter and flow 26 back-exits are PASS assertions" >&2; exit 1
fi
# 17 / 29(30): XFAIL (KAN-190) only when the chip bar is on
# screen and only the district chip is missing; Home (no bar) is not it.
mkdir -p "$replay_dir"; : > "$replay_dir/log"
if ! (REPLAY_DIR=run41314245431 replay chipbar_state_deity_no_district.xml chip_bar_only_district_missing) >/dev/null 2>&1 ||
   (REPLAY_DIR=run41314245431 replay home_no_chip_bar.xml chip_bar_only_district_missing) >/dev/null 2>&1 ||
   (REPLAY_DIR=run41314245431 replay chipbar_state_district_clear.xml chip_bar_only_district_missing) >/dev/null 2>&1; then
  echo "chip_bar_only_district_missing: true only for state+deity with no district" >&2; exit 1
fi
dx="$(
  EMULATOR_ARTIFACTS="$(mktemp -d)"
  export EMULATOR_FLOW=30-filter-matrix-rest EMULATOR_ARTIFACTS EMULATOR_PACKAGE=com.example
  source tool/emulator/lib/common.sh >/dev/null 2>&1
  # shellcheck disable=SC2329 # stub called by the sourced library
  step_shot() { :; }
  # shellcheck disable=SC2329 # stub called by the sourced library
  sleep() { :; }
  # shellcheck disable=SC2329 # stub called by the sourced library
  ui_dump() { cp "tool/emulator/testdata/run41314245431/${FX}" "$DUMP"; }
  FX=chipbar_state_deity_no_district.xml xfail_known a-then-district KAN-190 "hidden" district_chip_reappears >/dev/null
  FX=chipbar_state_district_clear.xml xfail_known b-then-district KAN-190 "hidden" district_chip_reappears >/dev/null 2>&1
  cat "$RESULTS"
)"
if ! grep -qx 'XFAIL 30-filter-matrix-rest: a-then-district: KAN-190: hidden' <<<"$dx" ||
   ! grep -qx 'XPASS 30-filter-matrix-rest: b-then-district: KAN-190: hidden' <<<"$dx"; then
  echo "district XFAIL: stays XFAIL while hidden, XPASS when the chip reappears" >&2; echo "$dx" >&2; exit 1
fi
rm -rf "$replay_dir"
for f in 17_entry_matrix.sh 29_filter_matrix.sh; do
  # shellcheck disable=SC2016 # literal flow text
  if ! grep -q 'chip_bar_only_district_missing' "tool/emulator/flows/$f" ||
     ! grep -q 'xfail_known "$id-.*" KAN-190' "tool/emulator/flows/$f" ||
     grep -q 'xfail_step' "tool/emulator/flows/$f"; then
    echo "flow ${f}: district XFAIL only via chip_bar_only_district_missing + xfail_known KAN-190" >&2; exit 1
  fi
done
# shellcheck disable=SC2016 # literal flow text
if ! grep -q 'fail_step "$id-then-$other" "filter chip bar not on screen"' tool/emulator/flows/29_filter_matrix.sh; then
  echo "flow 29: no chip bar -> FAIL" >&2; exit 1
fi
# Release-gate paths: strict (published release, or dispatch with
# release_gate=true) exits 1 on any FAIL/XFAIL/XPASS/missing results, a
# non-full tier, or an APK not built from the SHA; report mode exits 0.
rg_art="$(mktemp -d)"
gate_clean_results "$rg_art"
export EMULATOR_SHARD_RESULTS="${rg_art}/shards"
for mode in "EMULATOR_GATE_MODE=strict" "EMULATOR_GATE_EVENT=release"; do
  if ! env "$mode" EMULATOR_ARTIFACTS="$rg_art" GITHUB_STEP_SUMMARY=/dev/null bash tool/emulator/release_gate.sh full "$gate_sha" build >/dev/null 2>&1; then
    echo "release gate (${mode}): a clean full build run passes" >&2; exit 1
  fi
  for bad in "smoke $gate_sha build" "full $gate_sha url" "full $gate_sha artifact"; do
    # shellcheck disable=SC2086 # split on purpose
    if env "$mode" EMULATOR_ARTIFACTS="$rg_art" GITHUB_STEP_SUMMARY=/dev/null bash tool/emulator/release_gate.sh $bad >/dev/null 2>&1; then
      echo "release gate (${mode}): must refuse '${bad}'" >&2; exit 1
    fi
  done
done
printf 'XFAIL 29-filter-matrix: x-then-district: KAN-190: district chip hidden with no state selected\n' >> "${rg_art}/results.txt"
if env EMULATOR_GATE_MODE=strict EMULATOR_ARTIFACTS="$rg_art" GITHUB_STEP_SUMMARY=/dev/null bash tool/emulator/release_gate.sh full "$gate_sha" build >/dev/null 2>&1; then
  echo "release gate (strict): the conditional KAN-190 XFAIL must go red" >&2; exit 1
fi
if ! out="$(env EMULATOR_GATE_MODE=report EMULATOR_GATE_EVENT=workflow_dispatch EMULATOR_ARTIFACTS="$rg_art" GITHUB_STEP_SUMMARY=/dev/null bash tool/emulator/release_gate.sh full "$gate_sha" build 2>&1)" ||
   [[ "$out" != *"NOT a release gate"* ]]; then
  echo "release gate (report): XFAIL prints 'NOT a release gate' and exits 0" >&2; exit 1
fi
unset EMULATOR_SHARD_RESULTS
rm -rf "$rg_art"
# choose_tier.sh: release -> full; dispatch release_gate=true -> full, and
# release_gate with tier smoke is an error.
ct() { env -u GITHUB_OUTPUT "$@" bash tool/emulator/choose_tier.sh 2>/dev/null | sed -n 's/^Emulator tier \([a-z]*\),.*/\1/p'; }
if [[ "$(ct GITHUB_EVENT_NAME=release)" != full ]] ||
   [[ "$(ct GITHUB_EVENT_NAME=workflow_dispatch INPUT_RELEASE_GATE=true)" != full ]] ||
   env -u GITHUB_OUTPUT GITHUB_EVENT_NAME=workflow_dispatch INPUT_TIER=smoke INPUT_RELEASE_GATE=true bash tool/emulator/choose_tier.sh >/dev/null 2>&1 ||
   [[ "$(ct GITHUB_EVENT_NAME=workflow_dispatch INPUT_TIER=smoke INPUT_RELEASE_GATE=false)" != smoke ]]; then
  echo "choose_tier.sh: release and release_gate dispatch run full; release_gate+smoke fails" >&2; exit 1
fi
# shellcheck disable=SC2016 # literal workflow text
if ! grep -q '^  release:$' "$workflow" || ! grep -q '^    types: \[published\]$' "$workflow" ||
   ! grep -A4 '^      release_gate:$' "$workflow" | grep -q 'type: boolean' ||
   ! grep -A4 '^      release_gate:$' "$workflow" | grep -q 'default: false' ||
   ! grep -Fq "EMULATOR_GATE_MODE: \${{ (github.event_name == 'release' || inputs.release_gate) && 'strict' || 'report' }}" "$workflow" ||
   ! grep -Fq "INPUT_RELEASE_GATE: \${{ inputs.release_gate && 'true' || 'false' }}" "$workflow"; then
  echo "workflow: release published trigger, release_gate input, strict gate mode on those paths" >&2; exit 1
fi
# Strict gate also refuses NOT RUN and SKIPPED outside plan.sh's planned
# skips (DEFAULT_SKIP_FLOWS, read from plan.sh here too); report mode lists
# them and exits 0.
planned_skips="$(bash -c 'source tool/emulator/plan.sh; printf "%s" "$DEFAULT_SKIP_FLOWS"')"
gate_case() { # want results-lines...
  local want="$1" d rc; shift; d="$(mktemp -d)"
  gate_clean_results "$d"
  printf '%s\n' "$@" >> "${d}/results.txt"
  rc=0; EMULATOR_GATE_MODE=strict EMULATOR_SHARD_RESULTS="${d}/shards" EMULATOR_ARTIFACTS="$d" GITHUB_STEP_SUMMARY=/dev/null bash tool/emulator/release_gate.sh full "$gate_sha" build >/dev/null 2>&1 || rc=$?
  if [[ "$rc" != "$want" ]]; then echo "strict gate: '$*' should exit ${want}, got ${rc}" >&2; exit 1; fi
  out="$(EMULATOR_GATE_MODE=report EMULATOR_GATE_EVENT=pull_request EMULATOR_ARTIFACTS="$d" GITHUB_STEP_SUMMARY="${d}/sum" bash tool/emulator/release_gate.sh full "$gate_sha" build 2>&1)" ||
    { echo "report gate must exit 0 for '$*'" >&2; exit 1; }
  if [[ "$want" == 1 && "$out" != *"NOT a release gate"* ]]; then echo "report gate must list '$*'" >&2; exit 1; fi
  if [[ "$want" == 0 && "$out" == *"NOT a release gate"* ]]; then echo "report gate: planned skips are not a refusal" >&2; exit 1; fi
  GATE_OUT="$out"; GATE_SUM="$(cat "${d}/sum" 2>/dev/null)"; rm -rf "$d"
}
planned_lines=(); for id in $planned_skips; do planned_lines+=("SKIPPED ${id}: location-dependent, skipped on the emulator (EMULATOR_SKIP_FLOWS)"); done
gate_case 1 "NOT RUN 05-search"
[[ "$GATE_OUT" == *"1 NOT RUN"* && "$GATE_SUM" == *"- NOT RUN 05-search"* ]] || { echo "report gate lists NOT RUN" >&2; exit 1; }
gate_case 1 "SKIPPED 05-search: skipped"
[[ "$GATE_OUT" == *"1 unplanned SKIPPED (05-search)"* && "$GATE_SUM" == *"- unplanned: SKIPPED 05-search"* ]] || { echo "report gate lists unplanned SKIPPED" >&2; exit 1; }
gate_case 0 "${planned_lines[@]}"
# Round 4.3 (run 41391038302): a missing shard must refuse the gate even
# when summarize.sh has not run yet (no "NOT RUN" lines at all).
ms="$(mktemp -d)"
gate_clean_results "$ms" 11
# Shard 11's flows never reported: drop them from the merged results.
for id in $(bash -c 'source tool/emulator/plan.sh; plan_ids full 11'); do
  sed -i "/ ${id}\(:\|\$\)/d" "${ms}/results.txt"
done
rc=0; g="$(EMULATOR_GATE_MODE=strict EMULATOR_SHARD_RESULTS="${ms}/shards" EMULATOR_ARTIFACTS="$ms" GITHUB_STEP_SUMMARY=/dev/null \
  bash tool/emulator/release_gate.sh full "$gate_sha" build 2>&1)" || rc=$?
if [[ "$rc" != 1 || "$g" != *"3 NOT RUN (no result: 30s-filter-matrix-sequences 19-rotation-state 20-empty-and-back)"* ||
      "$g" != *"missing shard artifacts: 11 (need 14)"* ]]; then
  echo "strict gate must refuse a run with shard 11 missing (3 silent NOT RUN + missing artifact): rc=${rc} ${g}" >&2; exit 1
fi
# Artifact present but its flows silent (e.g. results.txt from a dead shard):
# the plan comparison alone refuses it.
gate_clean_results "$ms"
sed -i '/ 19-rotation-state\(:\|$\)/d' "${ms}/results.txt"
rc=0; g="$(EMULATOR_GATE_MODE=strict EMULATOR_SHARD_RESULTS="${ms}/shards" EMULATOR_ARTIFACTS="$ms" GITHUB_STEP_SUMMARY=/dev/null \
  bash tool/emulator/release_gate.sh full "$gate_sha" build 2>&1)" || rc=$?
[[ "$rc" == 1 && "$g" == *"1 NOT RUN (no result: 19-rotation-state)"* ]] || { echo "gate: a planned flow with no line is NOT RUN: ${g}" >&2; exit 1; }
# Shard artifacts present, results complete: passes; and only the missing
# artifact (results complete) still refuses.
gate_clean_results "$ms"
EMULATOR_GATE_MODE=strict EMULATOR_SHARD_RESULTS="${ms}/shards" EMULATOR_ARTIFACTS="$ms" GITHUB_STEP_SUMMARY=/dev/null \
  bash tool/emulator/release_gate.sh full "$gate_sha" build >/dev/null 2>&1 || { echo "gate: clean 14-shard run must pass" >&2; exit 1; }
rm -f "${ms}/shards/emulator-app-test-7/results.txt"
if EMULATOR_GATE_MODE=strict EMULATOR_SHARD_RESULTS="${ms}/shards" EMULATOR_ARTIFACTS="$ms" GITHUB_STEP_SUMMARY=/dev/null \
  bash tool/emulator/release_gate.sh full "$gate_sha" build >/dev/null 2>&1; then echo "gate: missing shard 7 artifact must refuse" >&2; exit 1; fi
rm -rf "$ms"
echo "release gate negative: missing shard 11 refused (round 4.3)"
[[ "${#planned_lines[@]}" -ge 3 ]] || { echo "plan.sh DEFAULT_SKIP_FLOWS should hold 11, 23, 30d" >&2; exit 1; }
if grep -Eq '11-near-me|23-near-me|30d-near-me' tool/emulator/release_gate.sh; then
  echo "release_gate.sh must read planned skips from plan.sh, not hard-code them" >&2; exit 1
fi
# release_gate dispatch with apk_url / artifact_run_id fails fast.
for extra in INPUT_APK_URL=https://x/a.apk INPUT_ARTIFACT_RUN_ID=123; do
  if env -u GITHUB_OUTPUT GITHUB_EVENT_NAME=workflow_dispatch INPUT_RELEASE_GATE=true "$extra" bash tool/emulator/choose_tier.sh >/dev/null 2>&1; then
    echo "choose_tier.sh: release_gate with ${extra%%=*} must fail" >&2; exit 1
  fi
  if ! env -u GITHUB_OUTPUT GITHUB_EVENT_NAME=workflow_dispatch INPUT_RELEASE_GATE=false "$extra" bash tool/emulator/choose_tier.sh >/dev/null 2>&1; then
    echo "choose_tier.sh: ${extra%%=*} without release_gate is fine" >&2; exit 1
  fi
done
# ---------------------------------------------------------------------------
# Round 4 regressions: real dumps and ini files from run 41373837994.
# ---------------------------------------------------------------------------
fx4=tool/emulator/testdata/run41373837994
r4="$(mktemp -d)"
# shellcheck disable=SC2030,SC2031,SC2329
lib4() {
  (
    set -uo pipefail
    export EMULATOR_FLOW="${R4_FLOW:-30a-filter-matrix-drawer-bar-state}" EMULATOR_ARTIFACTS="$r4/art" EMULATOR_PACKAGE=com.shradhaventures.temple
    # shellcheck disable=SC1091
    source tool/emulator/lib/common.sh
    PKG=com.shradhaventures.temple
    sleep() { :; }
    step_shot() { :; }
    ui_screen_size() { echo "${R4_SIZE:-320 640}"; }
    ui_tap() { echo "TAP ${UI_TEXT:-}" >> "$r4/log"; }
    adb_shell_capped() { shift; echo "ADB $*" >> "$r4/log"; }
    # Serves R4_SEQ fixtures in order, repeating the last one.
    ui_dump() {
      step_budget_ok || return 1
      local n; n="$(grep -c '^DUMP' "$r4/log" || true)"
      local -a seq; read -r -a seq <<<"$R4_SEQ"
      (( n >= ${#seq[@]} )) && n=$((${#seq[@]} - 1))
      echo "DUMP ${seq[$n]}" >> "$r4/log"
      cp "${fx4}/${seq[$n]}" "$DUMP"
    }
    "$@"
  )
}
# 1. Snapshot: the create boot grew disk.dataPartition.size to 6g; the run
# phase must pin config.ini to the snapshot's hardware.ini, not 2048M.
avd4="$r4/avd/emulator-app-test-30.avd"
mkdir -p "$avd4/snapshots/default_boot" "$r4/bin"
cp "$fx4/config_prelaunch.ini" "$avd4/config.ini"
printf 'hw.cpu.ncore=4\ndisk.dataPartition.size=2048M\n' >> "$avd4/config.ini"
cp "$fx4/snapshot_hardware_6g.ini" "$avd4/snapshots/default_boot/hardware.ini"
printf '#!/bin/sh\nexit 0\n' > "$r4/bin/adb"; cp "$r4/bin/adb" "$r4/bin/pkill"; chmod +x "$r4/bin/adb" "$r4/bin/pkill"
p4="$(PATH="$r4/bin:$PATH" ANDROID_AVD_HOME="$r4/avd" HOME="$r4" RUNNER_TEMP="" EMULATOR_AVD_NAME=emulator-app-test-30 \
  EMULATOR_DISK_SIZE=2048M EMULATOR_CORES=4 bash tool/emulator/prepare_avd.sh run 2>&1)"
if ! grep -qx 'disk.dataPartition.size=6442450944' "$avd4/config.ini" ||
   [[ "$(grep -c '^disk.dataPartition.size=' "$avd4/config.ini")" -ne 1 ]] ||
   ! grep -q 'pinned to snapshot hardware.ini: disk=6442450944 cores=4 ram=2048' <<<"$p4"; then
  echo "prepare_avd run: config.ini must follow the snapshot's 6g data partition (run 41373837994 cold boots)" >&2
  echo "$p4" >&2; grep '^disk\.' "$avd4/config.ini" >&2; exit 1
fi
cp "$fx4/config_prelaunch.ini" "$avd4/config.ini"
PATH="$r4/bin:$PATH" ANDROID_AVD_HOME="$r4/avd" HOME="$r4" RUNNER_TEMP="" EMULATOR_DISK_SIZE=2048M EMULATOR_CORES=4 \
  bash tool/emulator/prepare_avd.sh create >/dev/null 2>&1
if ! grep -qx 'disk.dataPartition.size=2048M' "$avd4/config.ini"; then
  echo "prepare_avd create: keeps the key's 2048M (only the run phase pins to the snapshot)" >&2; exit 1
fi
# 2. Boot summary from the shard results' BOOT lines, not the job-log API.
mkdir -p "$r4/sr/emulator-app-test-1" "$r4/sr/emulator-app-test-2"
printf 'BOOT full-1 snapshot\nPASS x: y\n' > "$r4/sr/emulator-app-test-1/results.txt"
printf 'BOOT full-2 cold\n' > "$r4/sr/emulator-app-test-2/results.txt"
b4="$(GITHUB_STEP_SUMMARY="" bash tool/emulator/boot_log_check.sh --results "$r4/sr" 2>&1)"
if ! grep -qx 'boot: snapshot (emulator full-1)' <<<"$b4" || ! grep -qx 'boot: cold (emulator full-2)' <<<"$b4" ||
   grep -q 'unknown' <<<"$b4"; then
  echo "boot_log_check --results: one verdict per shard from BOOT lines" >&2; echo "$b4" >&2; exit 1
fi
if ! bash tool/emulator/boot_log_check.sh --results "$r4/none" | grep -q '^boot: unknown (no BOOT lines'; then
  echo "boot_log_check --results: no BOOT lines -> unknown" >&2; exit 1
fi
# 3. Drawer FILTERS row at y 478 of 640: invisible to the 70% chip band,
# found with CHIP_MAX_TOP_PCT=95; flow 29 sets 95 for drawer_bar and waits
# for a non-zero "All Temples" count (the sheet offered "Any state 0").
: > "$r4/log"
if (R4_SEQ=drawer_bar_chips.xml lib4 scroll_chips_until --resource-id filter-chip-district) >/dev/null 2>&1; then
  echo "scroll_chips_until: drawer row is below the default 70% band (precondition)" >&2; exit 1
fi
: > "$r4/log"
if ! (R4_SEQ=drawer_bar_chips.xml CHIP_MAX_TOP_PCT=95 lib4 scroll_chips_until --resource-id filter-chip-district) >/dev/null 2>&1 ||
   grep -q '^ADB input swipe' "$r4/log"; then
  echo "scroll_chips_until: CHIP_MAX_TOP_PCT=95 finds the drawer district chip without scrolling" >&2; cat "$r4/log" >&2; exit 1
fi
f29=tool/emulator/flows/29_filter_matrix.sh
if ! sed -n '/^enter_drawer_bar() {/,/^}/p' "$f29" | grep -q 'CHIP_MAX_TOP_PCT=95' ||
   ! sed -n '/^enter_drawer_bar() {/,/^}/p' "$f29" | grep -Fq -- "--content-desc-regex '^All Temples\\s+[1-9][0-9]*\$'"; then
  echo "flow 29 drawer_bar: CHIP_MAX_TOP_PCT=95 and wait for a non-zero All Temples count" >&2; exit 1
fi
if ! python3 tool/emulator/lib/ui.py find "$fx4/drawer_bar_chips.xml" --content-desc-regex '^All Temples\s+[1-9][0-9]*$' >/dev/null ||
   python3 tool/emulator/lib/ui.py find "$fx4/drawer_sheet_zero_temples.xml" --content-desc-regex '^All Temples\s+[1-9][0-9]*$' >/dev/null; then
  echo "All Temples count regex: 992 matches, the zero-temple sheet does not" >&2; exit 1
fi
# 4. State chip off the LEFT edge (22 after detail back, 29 re-tap): the
# scroll must reach the left side (swipe left-to-right) within 8 tries.
: > "$r4/log"
(R4_SEQ=state_chip_off_left.xml lib4 scroll_chips_until --resource-id filter-chip-state) >/dev/null 2>&1 || true
if [[ "$(grep -c '^ADB input swipe' "$r4/log")" -ne 8 ]] ||
   ! awk '$1 == "ADB" && $3 == "swipe" && $4 < $6 { r = 1 } END { exit !r }' "$r4/log"; then
  echo "scroll_chips_until: 8 tries, the last ones swipe right (reveal the left side)" >&2; cat "$r4/log" >&2; exit 1
fi
if ! sed -n '/^chip_present() {/,/^}/p' "$f29" | grep -q 'state) find_filter_chip filter-chip-state'; then
  echo "flow 29 chip_present: the state chip must be scrolled into view too" >&2; exit 1
fi
if grep -q 'for other in "${CHIPS\[@\]}" "$done_chip"' "$f29"; then
  echo "flow 29: the duplicate re-tap probe of the done chip is gone" >&2; exit 1
fi
# 5. Flow 19 landscape: chip_exact Kerala takes the filter-chip-state node
# (95,198), not the app bar title "Kerala" (320,64).
: > "$r4/log"
c4="$(R4_SEQ=landscape_title_kerala.xml R4_SIZE="640 320" lib4 eval 'chip_exact Kerala && echo "$UI_CX $UI_CY"' 2>/dev/null)"
if [[ "$c4" != "95 198" ]]; then
  echo "chip_exact: filter chip first, not the app bar title (got '${c4}')" >&2; exit 1
fi
# 6. Flow 25: Chrome's first-run screen after Get Directions with Maps
# disabled is the URL fallback working; the Kerala list is not.
if ! (R4_SEQ=chrome_first_run.xml lib4 eval 'ui_dump; maps_fallback_shown') ||
   (R4_SEQ=kerala_list.xml lib4 eval 'ui_dump; maps_fallback_shown'); then
  echo "maps_fallback_shown: browser in front passes, an unchanged app screen fails" >&2; exit 1
fi
f25=tool/emulator/flows/25_directions_edge.sh
if grep -q "ui_find --text-contains \"irections\" && pass_step no-maps-fallback" "$f25" ||
   ! grep -q 'pm enable com.google.android.apps.maps' "$f25"; then
  echo "flow 25: fallback via maps_fallback_shown on a fresh dump, Maps re-enabled after" >&2; exit 1
fi
# 7. TempleEmuMark: a logcat without the marker is an error (exit 3, no
# output), never an empty window that passes; 25 and 26 FAIL on it.
mkdir -p "$r4/lc"
cat > "$r4/lc/adb" <<'ADB'
#!/usr/bin/env bash
if [[ "$1" == logcat ]]; then cat "$R4_LOGCAT"; fi
exit 0
ADB
chmod +x "$r4/lc/adb"
printf '11-02 01:50:00.000 1 1 I ActivityTaskManager: START u0 {cmp=com.google.android.apps.maps/x}\n' > "$r4/lc/nomark.txt"
printf '11-02 01:49:59.000 1 1 I TempleEmuMark: temple-emu-window-x-1-2\n11-02 01:50:00.000 1 1 I ActivityTaskManager: START u0 {cmp=com.google.android.apps.maps/x}\n' > "$r4/lc/mark.txt"
lc_rc() {
  ( export PATH="$r4/lc:$PATH" R4_LOGCAT="$1" EMULATOR_FLOW=26-drawer-nav-stack EMULATOR_ARTIFACTS="$r4/lcart" EMULATOR_PACKAGE=com.example
    # shellcheck disable=SC1091
    source tool/emulator/lib/common.sh
    LOGCAT_MARK="${2-temple-emu-window-x-1-2}"
    out="$(logcat_window_read 2>/dev/null)"; rc=$?
    echo "$rc $(grep -c . <<<"$out")" )
}
if [[ "$(lc_rc "$r4/lc/nomark.txt")" != "3 0" ]] || [[ "$(lc_rc "$r4/lc/mark.txt")" != "0 2" ]] ||
   [[ "$(lc_rc "$r4/lc/mark.txt" "")" != "3 0" ]]; then
  echo "logcat_window_read: marker missing -> exit 3 and no lines; marker present -> the window" >&2; exit 1
fi
for f in tool/emulator/flows/25_directions_edge.sh tool/emulator/flows/26_drawer_nav_stack.sh; do
  if ! grep -q 'TempleEmuMark logcat marker missing' "$f" || grep -q 'logcat_window_read |' "$f"; then
    echo "${f}: must FAIL when the TempleEmuMark marker is missing" >&2; exit 1
  fi
done
if grep -rn 'logcat_window_read' tool/emulator/flows | grep -v 'window="$(logcat_window_read)"' | grep -q .; then
  echo "every logcat_window_read caller must check its exit status" >&2; exit 1
fi
# Flow 26 tail on a logcat without the marker: back-exits is a FAIL.
b26="$(
  export EMULATOR_FLOW=26-drawer-nav-stack EMULATOR_ARTIFACTS="$r4/b26" EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  step_shot() { :; }; dismiss_blockers() { :; }; adb_shell_capped() { :; }
  logcat_window_read() { return 3; }
  # shellcheck disable=SC2034 # read by the eval below
  crash_dialog=0
  eval "$(sed -n '/^window_rc=0$/,$p' tool/emulator/flows/26_drawer_nav_stack.sh)" >/dev/null 2>&1
  cat "$RESULTS"
)"
if ! grep -qx 'FAIL 26-drawer-nav-stack: back-exits: TempleEmuMark logcat marker missing: crash check could not run' <<<"$b26"; then
  echo "flow 26: back-exits must FAIL when the marker is missing" >&2; echo "$b26" >&2; exit 1
fi
# 8. Flow 24 (Manu blocker): NA only on a detail page that proves a single
# photo; a failed search/scroll, a failed tap or the wrong screen is FAIL.
# Runs the flow's "multi-photo open" block with stubbed UI.
f24=tool/emulator/flows/24_gallery_autoadvance_viewer.sh
run24() {
  ( export EMULATOR_FLOW=24-gallery-autoadvance-viewer EMULATOR_ARTIFACTS="$r4/f24-$1" EMULATOR_PACKAGE=com.example
    # shellcheck disable=SC1091
    source tool/emulator/lib/common.sh
    step_shot() { :; }; dismiss_blockers() { :; }; sleep() { :; }
    adb_shell_capped() { :; }
    ui_replace_field_text() { [[ "${R24_SEARCH:-ok}" == ok ]] || { UI_FIELD_ACTUAL="field not found"; return 1; }; }
    ui_wait_scrolled() { [[ "${R24_SCROLL:-ok}" == ok ]]; }
    ui_tap() { [[ "${R24_TAP:-ok}" == ok ]]; }
    ui_dump() { cp "${fx4}/${R24_DUMP}" "$DUMP"; }
    eval "$(sed -n '/^# --- multi-photo open begin$/,/^# --- multi-photo open end$/p' "$f24")"
    cat "$RESULTS" )
}
o="$(R24_DUMP=detail_single_1of1.xml R24_SCROLL=fail run24 scroll 2>/dev/null)"
grep -q "^FAIL 24-gallery-autoadvance-viewer: multi-photo: no 'Aazhimala' card after the search" <<<"$o" || { echo "flow 24: scroll/search miss must FAIL: $o" >&2; exit 1; }
o="$(R24_DUMP=detail_single_1of1.xml R24_SEARCH=fail run24 search 2>/dev/null)"
grep -q "^FAIL 24-gallery-autoadvance-viewer: multi-photo: search for 'Aazhimala' failed" <<<"$o" || { echo "flow 24: search failure must FAIL: $o" >&2; exit 1; }
o="$(R24_DUMP=detail_single_1of1.xml R24_TAP=fail run24 tap 2>/dev/null)"
grep -q "^FAIL 24-gallery-autoadvance-viewer: multi-photo: tap on the 'Aazhimala' card failed" <<<"$o" || { echo "flow 24: tap failure must FAIL: $o" >&2; exit 1; }
o="$(R24_DUMP=kerala_list.xml run24 wrong 2>/dev/null)"
grep -q "^FAIL 24-gallery-autoadvance-viewer: multi-photo: not on the detail page" <<<"$o" || { echo "flow 24: wrong screen must FAIL: $o" >&2; exit 1; }
o="$(R24_DUMP=detail_single_1of1.xml run24 single 2>/dev/null)"
grep -q "^NA 24-gallery-autoadvance-viewer: multi-photo: 'Aazhimala' has a single photo" <<<"$o" && ! grep -q '^PASS ' <<<"$o" || { echo "flow 24: proven 1 / 1 -> NA (not PASS): $o" >&2; exit 1; }
o="$(R24_DUMP=detail_multi_1of5.xml run24 multi 2>/dev/null)"
grep -qx 'PASS 24-gallery-autoadvance-viewer: multi-photo' <<<"$o" || { echo "flow 24: '1 / 5' -> PASS: $o" >&2; exit 1; }
if grep -q 'multi-photo-not-applicable\|skip_step multi-photo' "$f24" || ! grep -q '^if (( ! SINGLE )); then$' "$f24"; then
  echo "flow 24: no blanket NA; paging checks run unless a single photo was proven" >&2; exit 1
fi
# NA is not a PASS for summarize, and the strict gate refuses unplanned NA.
na_art="$r4/na"; mkdir -p "$na_art"
printf 'START 24-gallery-autoadvance-viewer\nNA 24-gallery-autoadvance-viewer: multi-photo: single photo\nDONE 24-gallery-autoadvance-viewer\n' > "$na_art/results.txt"
if EMULATOR_ARTIFACTS="$na_art" EMULATOR_TIER=all bash tool/emulator/summarize.sh > "$na_art/out" 2>&1 ||
   ! grep -q '^FAIL 24-gallery-autoadvance-viewer: missing: flow did not pass any step' "$na_art/results.txt" ||
   ! grep -q '0 passed, .* 1 not applicable' "$na_art/out"; then
  echo "summarize: NA is not a PASS (a flow with only NA fails)" >&2; cat "$na_art/out" >&2; exit 1
fi
gate_art="$r4/gate"; mkdir -p "$gate_art"
printf 'PASS 24-gallery-autoadvance-viewer: browse\nNA 24-gallery-autoadvance-viewer: multi-photo: single photo\n' > "$gate_art/results.txt"
g="$(EMULATOR_ARTIFACTS="$gate_art" EMULATOR_GATE_MODE=strict bash tool/emulator/release_gate.sh full 0123456789abcdef0123456789abcdef01234567 build 2>&1)" && {
  echo "strict gate must refuse an unplanned NA: $g" >&2; exit 1; }
grep -q '1 unplanned NA (24-gallery-autoadvance-viewer:multi-photo)' <<<"$g" || { echo "gate output names the NA: $g" >&2; exit 1; }
if ! grep -q '^DEFAULT_NA_STEPS=""' tool/emulator/plan.sh; then echo "no NA is planned by default" >&2; exit 1; fi
# 9. Per-step timeout: ui_dump refuses once the step is older than the
# budget, the FAIL says so, and the next record_* starts a fresh step.
st4="$(
  export EMULATOR_FLOW=99-step EMULATOR_ARTIFACTS="$r4/st" EMULATOR_PACKAGE=com.example EMULATOR_STEP_BUDGET_S=5
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  STEP_STARTED=$((SECONDS - 10))
  if ui_dump 2>/dev/null; then echo "dump-ran"; fi
  record_fail stuck "never appeared" >/dev/null
  step_budget_ok && echo "reset-ok"
  cat "$RESULTS"
)"
if grep -q dump-ran <<<"$st4" || ! grep -q reset-ok <<<"$st4" ||
   ! grep -qx 'FAIL 99-step: stuck: never appeared \[step timeout 5s\]' <<<"$st4"; then
  echo "step budget: ui_dump stops after EMULATOR_STEP_BUDGET_S, FAIL is tagged, record_* resets" >&2; echo "$st4" >&2; exit 1
fi
if ! grep -q 'STEP_BUDGET_S="${EMULATOR_STEP_BUDGET_S:-150}"' tool/emulator/lib/common.sh; then
  echo "step budget default is 150s" >&2; exit 1
fi
# 10. Long lists (17 Shiva, 29 Madurai gave up at 20-22s): district/deity
# get PICKER_LONG_GIVEUP_S (45) and one slower re-walk after a stall.
pk4="$(
  export EMULATOR_FLOW=99-pick EMULATOR_ARTIFACTS="$r4/pk" EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  wait_out_district_loader() { :; }
  n=0
  seek_option() { n=$((n + 1)); echo "SEEK $n fling=${SEEK_FLING_MS:-120} left=$(( $3 - SECONDS ))" >&2
    if (( n == 1 )); then return 1; fi; UI_CX=1 UI_CY=2 UI_TEXT="Madurai  4"; return 0; }
  ui_tap() { :; }
  sleep() { :; }
  select_labeled '^Madurai( +[0-9]+)?$' DISTRICT 2>&1 && echo "picked $SELECTED_LABEL"
)"
if ! grep -q '^SEEK 1 fling=120 left=30$' <<<"$pk4" || ! grep -q '^SEEK 2 fling=300' <<<"$pk4" || ! grep -q '^picked Madurai' <<<"$pk4"; then
  echo "select_labeled: district walk gets 45s-15s, then one 300ms re-walk after a stall" >&2; echo "$pk4" >&2; exit 1
fi
# 11. Flow 06: combined-deity picks inside the applied state; the city
# check reads chip ids from one dump instead of two 6-scroll misses.
f06=tool/emulator/flows/06_filters.sh
if ! grep -q 'combined_deity_rx="${COMBINED_DEITY_PICK:-^Vishnu( +\[0-9\]+)?$}"' "$f06" ||
   grep -q 'scroll_chips_until --resource-id filter-chip-city' "$f06" ||
   ! grep -q 'for n in $(seq 1 "${FILTER_REPEATS:-2}")' "$f06"; then
  echo "flow 06: in-state combined deity, one-dump city check, 2 repeats" >&2; exit 1
fi
if ! python3 tool/emulator/lib/ui.py find "$fx4/kerala_list.xml" --content-desc-contains 'Vishnu' >/dev/null; then
  echo "fixture: Kerala list offers a Vishnu temple" >&2; exit 1
fi
# 12. Flow 18 waits for the collage before flinging (it flung the loader).
if ! grep -B1 -A3 'ui_wait 45 --content-desc "Discover"' tool/emulator/flows/18_home_reselect.sh | grep -q 'fail_step scrolled'; then
  echo "flow 18: wait for the Home collage before the scroll check" >&2; exit 1
fi
# 13. Flow 17: one entry point per flow (17a-17d took 597s for two).
for part in home_button drawer_all drawer_search list_drawer_all; do
  e17="$(FILTER_MATRIX_PART=$part bash -c 'eval "$(sed -n "/^case \"\${FILTER_MATRIX_PART:-all}\" in/,/^esac/p" tool/emulator/flows/17_entry_matrix.sh)"; echo "${ENTRIES[*]}"')"
  [[ "$e17" == "$part" ]] || { echo "flow 17 part ${part}: wrong entries '${e17}'" >&2; exit 1; }
done
# 14. Seek stall root cause (17 Shiva x2, 29 Madurai): the sheet options
# have no text= (0 in every sheet dump of runs 41306793034 and 41373837994),
# so the old text-only signature was sha256("") for every look and seek
# said "list stopped moving" after 3 looks. The signature now reads
# content-desc and filter-option ids.
for f in deity_sheet_ganesha_stall.xml district_sheet_madurai_sliver.xml; do
  if grep -q ' text="[^"]' "$fx4/$f"; then echo "fixture ${f}: expected no text= values" >&2; exit 1; fi
done
sig4() { DUMP="$fx4/$1" bash -c 'source <(sed -n "/^dump_scroll_sig() {/,/^}/p" tool/emulator/lib/common.sh); dump_scroll_sig'; }
if [[ "$(sig4 deity_sheet_ganesha_stall.xml)" == e3b0c44298fc1c14 || "$(sig4 deity_sheet_ganesha_stall.xml)" == "$(sig4 district_sheet_madurai_sliver.xml)" ]]; then
  echo "dump_scroll_sig: must tell two different sheet positions apart (was sha256 of nothing)" >&2; exit 1
fi
# Replay: Madurai is a 1 px sliver at y 568-569. It must never be tapped
# (option-seek "up near" even with no max-top limit), and a slow drag that
# does not move the frozen list gets its own retry (x=80, 1500 ms).
if [[ "$(python3 tool/emulator/lib/ui.py option-seek "$fx4/district_sheet_madurai_sliver.xml" --kind district --name Madurai --min-top 153 --max-top 640)" != "up near" ]]; then
  echo "option-seek: a 1 px sliver is not tappable" >&2; exit 1
fi
: > "$r4/log"
(R4_SEQ=district_sheet_madurai_sliver.xml lib4 seek_option district Madurai $((SECONDS + 30))) >/dev/null 2>"$r4/seek.err" || true
if ! grep -q 'ADB input swipe 160 537 160 268 900' "$r4/log" || ! grep -q 'ADB input swipe 80 537 80 268 1500' "$r4/log" ||
   ! grep -q 'slow drag did not move the district list; retrying' "$r4/seek.err" || grep -q '^TAP' "$r4/log"; then
  echo "seek_option: slow drag on the Madurai dump, then its own retry; no tap on the sliver" >&2; cat "$r4/log" "$r4/seek.err" >&2; exit 1
fi
# 15. ui_screen_size honours rotation (SurfaceOrientation 1/3 swap).
mkdir -p "$r4/rot"
cat > "$r4/rot/adb" <<'ADB'
#!/usr/bin/env bash
case "$*" in
  "shell wm size") echo "Physical size: 320x640" ;;
  "shell dumpsys input") echo "    SurfaceOrientation: ${R4_ROT:-0}" ;;
esac
ADB
chmod +x "$r4/rot/adb"
rot4() { ( export PATH="$r4/rot:$PATH" R4_ROT="$1" EMULATOR_FLOW=99-rot EMULATOR_ARTIFACTS="$r4/rotart" EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh; ui_screen_size ); }
if [[ "$(rot4 0)" != "320 640" || "$(rot4 1)" != "640 320" || "$(rot4 3)" != "640 320" || "$(rot4 2)" != "320 640" ]]; then
  echo "ui_screen_size: landscape swaps width/height" >&2; exit 1
fi
# 16. Flow 22: the state chip is off the LEFT edge (district first in the
# dump), so the FIRST swipe reveals the left side.
: > "$r4/log"
(R4_SEQ=state_chip_off_left.xml lib4 scroll_chips_until --resource-id filter-chip-state --text-regex '^Tamil Nadu') >/dev/null 2>&1 || true
if ! head -1 <(grep '^ADB input swipe' "$r4/log") | awk '{ exit !($4 < $6) }'; then
  echo "scroll_chips_until: first swipe must go right for a chip left of every visible chip" >&2; cat "$r4/log" >&2; exit 1
fi
# 17. Flow 18: relative scroll check, "scrolled" recorded exactly once.
run18() {
  ( export EMULATOR_FLOW=18-home-reselect EMULATOR_ARTIFACTS="$r4/f18-$1" EMULATOR_PACKAGE=com.example
    # shellcheck disable=SC1091
    source tool/emulator/lib/common.sh
    step_shot() { :; }; dismiss_blockers() { :; }; sleep() { :; }; ui_fling() { R18_N=$((R18_N + 1)); }
    R18_N=0
    ui_dump() { :; }
    ui_wait() { [[ "$R18_COLLAGE" == yes ]] && UI_Y1=357; }
    ui_find() { [[ "$R18_COLLAGE" == yes ]] || return 1; if (( R18_N > 0 )); then UI_Y1="$R18_AFTER"; else UI_Y1=357; fi; }
    eval "$(sed -n '/^HOME_TOP_Y=""$/,/^}$/p' tool/emulator/flows/18_home_reselect.sh)"
    eval "$(sed -n '/^if ! ui_wait 45 --content-desc "Discover"; then$/,/^fi$/p' tool/emulator/flows/18_home_reselect.sh)" >/dev/null 2>&1
    cat "$RESULTS" )
}
o="$(R18_COLLAGE=yes R18_AFTER=330 run18 moved)"; [[ "$o" == "PASS 18-home-reselect: scrolled" ]] || { echo "flow 18: Discover 357 -> 330 is a scroll: $o" >&2; exit 1; }
o="$(R18_COLLAGE=yes R18_AFTER=357 run18 stuck)"; [[ "$(grep -c scrolled <<<"$o")" == 1 && "$o" == "FAIL 18-home-reselect: scrolled: could not scroll"* ]] || { echo "flow 18: unmoved -> one FAIL: $o" >&2; exit 1; }
o="$(R18_COLLAGE=no R18_AFTER=357 run18 never)"; [[ "$(grep -c scrolled <<<"$o")" == 1 && "$o" == *"Home collage never appeared"* ]] || { echo "flow 18: no collage -> exactly one FAIL: $o" >&2; exit 1; }
# 18. Flow 06: Kerala's list (run 41373837994) has a Vishnu-deity temple,
# so the Kerala-scoped deity sheet offers Vishnu.
grep -q 'content-desc="Ambalappuzha Sri Krishna Temple&#10;Ambalappuzha, Kerala&#10;Vishnu"' "$fx4/kerala_list.xml" || { echo "fixture: Kerala/Vishnu evidence" >&2; exit 1; }
# 19. Nits: prepare_avd warns on a missing snapshot hardware.ini; 25 runs
# pm enable once; plan/choose_tier/workflow say the real shard count.
rm -f "$avd4/snapshots/default_boot/hardware.ini"
w4="$(PATH="$r4/bin:$PATH" ANDROID_AVD_HOME="$r4/avd" HOME="$r4" RUNNER_TEMP="" EMULATOR_DISK_SIZE=2048M bash tool/emulator/prepare_avd.sh run 2>&1)"
grep -q '^::warning::prepare_avd (run): no snapshots/default_boot/hardware.ini' <<<"$w4" || { echo "prepare_avd: warn on missing hardware.ini" >&2; echo "$w4" >&2; exit 1; }
[[ "$(grep -c 'pm enable com.google.android.apps.maps' tool/emulator/flows/25_directions_edge.sh)" == 1 ]] || { echo "flow 25: pm enable once" >&2; exit 1; }
sc="$(bash -c 'source tool/emulator/plan.sh; echo $SHARD_COUNT')"
words=(zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen)
if ! grep -q "every flow, ${words[$sc]} parallel shards" tool/emulator/plan.sh || ! grep -q "full (${sc} shards)" tool/emulator/choose_tier.sh ||
   ! grep -q "as ${sc} parallel shards" .github/workflows/emulator-app-test.yml || grep -qE 'six parallel|nine parallel|\((6|8|9) shards\)|as 9 parallel' tool/emulator/plan.sh tool/emulator/choose_tier.sh .github/workflows/emulator-app-test.yml; then
  echo "shard count text must say ${sc}" >&2; exit 1
fi
grep -q 'PICKER_LONG_GIVEUP_S=45' .github/workflows/emulator-app-test.yml && grep -q 'EMULATOR_STEP_BUDGET_S=150' .github/workflows/emulator-app-test.yml || { echo "workflow header: caps" >&2; exit 1; }
# ---------------------------------------------------------------------------
# Round 4.3 (run 41391038302, triage-41391038302/TRIAGE.md)
# ---------------------------------------------------------------------------
r43="$(mktemp -d)"
# 1. Cold boot: replay shard 3's AVD ini files. The flow boot's
# hardware-qemu.ini (2g) against the snapshot (6g) is a mismatch; the old
# EMULATOR_OPTIONS (-partition-size 2048) is refused before launch; the
# new options and the pinned config.ini pass; the create boot's ini passes.
av="tool/emulator/testdata/run41391038302/avdini3"
mkdir -p "$r43/avd"; cp "$av/run-booted/config.ini" "$av/run-booted/hardware-qemu.ini" "$r43/avd/"
snap_env=(EMULATOR_SNAPSHOT_HW="$av/run-booted/snapshot-hardware.ini")
o="$(env "${snap_env[@]}" bash tool/emulator/check_snapshot_config.sh post "$r43/avd")" && { echo "snapcfg: 2g boot vs 6g snapshot must mismatch: $o" >&2; exit 1; }
[[ "$o" == *"disk.dataPartition.size snapshot=6442450944 boot=2147483648"* ]] || { echo "snapcfg post names the disk key: $o" >&2; exit 1; }
old_opts="-no-window -gpu swiftshader_indirect -no-snapshot-save -no-audio -no-boot-anim -camera-back none -camera-front none -partition-size 2048"
o="$(env "${snap_env[@]}" EMULATOR_OPTIONS="$old_opts" bash tool/emulator/check_snapshot_config.sh pre "$r43/avd")" && { echo "snapcfg pre must refuse -partition-size 2048: $o" >&2; exit 1; }
[[ "$o" == *"EMULATOR_OPTIONS -partition-size 2048 (snapshot 6144M)"* ]] || { echo "snapcfg pre names the option: $o" >&2; exit 1; }
new_opts="$(sed -n 's/^  EMULATOR_OPTIONS: //p' "$workflow")"
[[ -n "$new_opts" && "$new_opts" != *partition-size* ]] || { echo "workflow EMULATOR_OPTIONS (top-level env) without -partition-size: '$new_opts'" >&2; exit 1; }
env "${snap_env[@]}" EMULATOR_OPTIONS="$new_opts" bash tool/emulator/check_snapshot_config.sh pre "$r43/avd" >/dev/null || { echo "snapcfg pre: new options + pinned config.ini pass" >&2; exit 1; }
cp "$av/create-booted/hardware-qemu.ini" "$r43/avd/"
env "${snap_env[@]}" bash tool/emulator/check_snapshot_config.sh post "$r43/avd" >/dev/null || { echo "snapcfg post: a 6g boot loads the 6g snapshot" >&2; exit 1; }
rc=0; env EMULATOR_SNAPSHOT_HW="$r43/none.ini" bash tool/emulator/check_snapshot_config.sh pre "$r43/avd" >/dev/null || rc=$?
[[ "$rc" == 2 ]] || { echo "snapcfg: no snapshot exits 2, got $rc" >&2; exit 1; }
grep -q 'check_snapshot_config.sh" pre' tool/emulator/prepare_avd.sh || { echo "prepare_avd run must verify the snapshot config before launch" >&2; exit 1; }
grep -q 'check_snapshot_config.sh post' tool/emulator/run_shard.sh || { echo "run_shard records the post-boot snapshot check" >&2; exit 1; }
# 2. Gate ordering: summarize before the gate, gate gets the shard dir.
sj="$(awk '/^  summary:$/ { j = 1 } j { print }' "$workflow")"
ln_sum="$(grep -n 'name: Write combined summary' <<<"$sj" | cut -d: -f1)"
ln_gate="$(grep -n 'name: Record tested SHA (release gate)' <<<"$sj" | cut -d: -f1)"
if [[ -z "$ln_sum" || -z "$ln_gate" ]] || (( ln_sum > ln_gate )) || ! grep -Fq 'EMULATOR_SHARD_RESULTS: shard-results' <<<"$sj"; then
  echo "summary: summarize.sh before release_gate.sh, with EMULATOR_SHARD_RESULTS" >&2; exit 1
fi
# 3. Upload: names, error on no files, results.txt required.
grep -q 'if-no-files-found: warn' "$workflow" && { echo "upload must use if-no-files-found: error" >&2; exit 1; }
[[ "$(sed -n '/name: Upload emulator artifacts/,/if-no-files-found/p' "$workflow" | grep -c 'if-no-files-found: error')" == 1 ]] || { echo "shard upload: if-no-files-found: error" >&2; exit 1; }
n="$(EMULATOR_FLOW=x EMULATOR_ARTIFACTS="$r43/a0" bash -c 'source tool/emulator/lib/common.sh; artifact_safe_name "30s-filter-matrix-sequences_seq1-deity:select"')"
[[ "$n" == "30s-filter-matrix-sequences_seq1-deity_select" ]] || { echo "artifact_safe_name ':' -> '_': $n" >&2; exit 1; }
( export EMULATOR_FLOW=30s-filter-matrix-sequences EMULATOR_ARTIFACTS="$r43/a1" EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  step_shot() { :; }; dismiss_blockers() { :; }
  echo '<node />' > "$DUMP"
  fail_step "seq1-deity:select" "x" >/dev/null; na_step "seq2:pick" "y" >/dev/null; xfail_step "seq3:clear" "z" >/dev/null )
found="$(cd "$r43/a1/dumps" && ls)"
if grep -q ':' <<<"$found" || ! grep -qx '30s-filter-matrix-sequences_seq1-deity_select.xml' <<<"$found"; then
  echo "step dumps must not contain ':': $found" >&2; exit 1
fi
grep -q 'cp -f "\$DUMP" "\${DUMP_DIR}/\${FLOW}_\${1}.xml"' tool/emulator/lib/common.sh && { echo "raw step-id dump names remain" >&2; exit 1; }
mkdir -p "$r43/up/dumps/sub:dir"; echo x > "$r43/up/dumps/sub:dir/a:b.xml"; echo 'PASS x: y' > "$r43/up/results.txt"
bash tool/emulator/sanitize_artifacts.sh "$r43/up" >/dev/null || { echo "sanitize_artifacts failed" >&2; exit 1; }
[[ -f "$r43/up/dumps/sub_dir/a_b.xml" ]] && ! find "$r43/up" -name '*:*' | grep -q . || { echo "sanitize_artifacts renames ':'" >&2; exit 1; }
mkdir -p "$r43/empty"; bash tool/emulator/sanitize_artifacts.sh "$r43/empty" >/dev/null 2>&1 && { echo "sanitize_artifacts: no results.txt must fail" >&2; exit 1; }
# Workflow-level env must not break the self-test (the build job inherits it).
grep -q '^env:$' "$workflow" || { echo "static emulator env lives at workflow level" >&2; exit 1; }
#R43_MORE
rm -rf "$r43"
echo "round 4.3 checks ok"
rm -rf "$r4"
echo "emulator self-test ok"
