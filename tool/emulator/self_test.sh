#!/usr/bin/env bash
# shellcheck disable=SC2030,SC2031 # test fixtures export env inside subshells on purpose
# Host-side checks for the emulator checklist. No device required.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# Round 4.4.8b (Manu): every mktemp of this run (and of the scripts it
# starts) goes under ONE temp root, removed on exit (pass, fail or signal).
# Earlier runs left ~50 /tmp/tmp.* dirs each.
st_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/emu-self-test.XXXXXX")"
export TMPDIR="$st_tmp_root"
trap 'rm -rf "$st_tmp_root"' EXIT
trap 'exit 130' INT TERM
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
      echo "BOOT full-$1 snapshot"
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
# Round 4.4: run_shard.sh waits up to 90s for system services; the stub
# adbs below never report them, so the self-test caps that wait.
export EMULATOR_SERVICES_WAIT_S="${EMULATOR_SERVICES_WAIT_S:-1}" EMULATOR_SERVICES_POLL_S="${EMULATOR_SERVICES_POLL_S:-0}" \
  EMULATOR_SNAPSHOT_READY_S="${EMULATOR_SNAPSHOT_READY_S:-2}" EMULATOR_SNAPSHOT_SETTLE_S="${EMULATOR_SNAPSHOT_SETTLE_S:-0}"
# Round 4.4.9: run_shard.sh needs the services ready before its BOOT line
# (not ready = dead boot). mk_ready_adb DIR [MARKER]: a stub adb that reports
# them ready, prints MARKER for the snapshot-marker getprop and exits 0 for
# anything else.
mk_ready_adb() {
  mkdir -p "$1"
  cat > "$1/adb" <<ADB
#!/bin/sh
case "\$*" in
  "shell service check "*) echo "Service \$4: found" ;;
  "shell pm path android") echo "package:/system/framework/framework-res.apk" ;;
  "shell getprop sys.boot_completed") echo 1 ;;
  "shell getprop debug.temple.snapshot_marker") echo "${2:-}" ;;
esac
exit 0
ADB
  chmod +x "$1/adb"
}
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
if [[ "$(grep -c 'uses: reactivecircus/android-emulator-runner@' "$workflow")" -ne 4 ]]; then
  echo "expected 4 emulator steps (warm-up snapshot, fallback snapshot, one flow run per shard job and its boot retry)" >&2
  exit 1
fi
# Both boots use the same emulator options (run 41314245431: the flow boot
# could not load the snapshot saved minutes earlier in the same job).
# shellcheck disable=SC2016 # literal workflow text
if [[ "$(grep -F -c 'emulator-options: ${{ env.EMULATOR_OPTIONS }}' "$workflow")" -ne 4 ]] ||
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
if len(cfgs) != 4 or any(c != cfgs[0] for c in cfgs) or None in cfgs[0].values():
    errs.append(f"warm-up, snapshot and flow steps must boot the same AVD config: {cfgs}")
opts = [re.search(r"^          emulator-options: (.*)$", body, re.M).group(1) for body in runners]
# Round 4.4.9c: the boot retry (last runner) adds only -no-snapshot-load.
if len(opts) != 4 or len(set(opts[:3])) != 1 or opts[3] != opts[0] + " -no-snapshot-load":
    errs.append(f"emulator boots must use identical options (retry: + -no-snapshot-load only): {opts}")
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
  EMULATOR_AVD_NAME=emulator-app-test-30 GITHUB_RUN_ID=77 GITHUB_RUN_ATTEMPT=1 EMULATOR_CPUINFO="$key_tmp/cpuA")
# Round 4.4.9b: two hosts, same model name, one AVX-512 flag apart.
printf 'processor\t: 0\nmodel name\t: Intel(R) Xeon(R) Platinum 8370C CPU @ 2.80GHz\nflags\t\t: fpu sse4_2 avx avx2 avx512f hypervisor\n\nprocessor\t: 1\nmodel name\t: Intel(R) Xeon(R) Platinum 8370C CPU @ 2.80GHz\nflags\t\t: fpu sse4_2 avx avx2 avx512f hypervisor\n' > "$key_tmp/cpuA"
sed 's/ avx512f//' "$key_tmp/cpuA" > "$key_tmp/cpuB"
# Same CPU, flags listed in another order: same identity.
sed 's/fpu sse4_2 avx avx2 avx512f hypervisor/hypervisor avx512f avx2 avx sse4_2 fpu/' "$key_tmp/cpuA" > "$key_tmp/cpuA2"
cpuA="$(EMULATOR_CPUINFO="$key_tmp/cpuA" bash tool/emulator/cpu_id.sh)"; cpuB="$(EMULATOR_CPUINFO="$key_tmp/cpuB" bash tool/emulator/cpu_id.sh)"
[[ "$cpuA" =~ ^[0-9a-f]{12}$ && "$cpuB" =~ ^[0-9a-f]{12}$ && "$cpuA" != "$cpuB" && "$(EMULATOR_CPUINFO="$key_tmp/cpuA2" bash tool/emulator/cpu_id.sh)" == "$cpuA" ]] ||
  { echo "4.4.9b cpu_id: 12-hex id, a flag apart -> different, flag order -> same: $cpuA $cpuB" >&2; exit 1; }
env "${key_env[@]}" EMULATOR_NPROC=4 GITHUB_ENV="$key_tmp/env" bash tool/emulator/avd_cache_key.sh > /dev/null 2>&1
if ! grep -qx "EMULATOR_AVD_CACHE_KEY=avd-30-google_apis-x86_64-img6-cores4-disk2048M-emu16740729-emulator-app-test-30-clean-cfg6-${cpuA}" "$key_tmp/env" || ! grep -qx "EMULATOR_CPU_ID=${cpuA}" "$key_tmp/env" ||
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
if ! grep -qx "EMULATOR_AVD_CACHE_KEY=avd-30-google_apis-x86_64-imgunknown-77-1-cores2-disk2048M-emu16740729-emulator-app-test-30-clean-cfg6-${cpuA}" "$key_tmp/env2"; then
  echo "an unknown image revision must give a one-run AVD cache key" >&2
  cat "$key_tmp/env2" >&2
  exit 1
fi
# Round 4.4.9b: a different host CPU -> a different key (the snapshot is
# never restored across CPUs); unreadable cpuinfo -> a one-run key.
printf 'Pkg.Revision=6\n' > "$key_props"
env "${key_env[@]}" EMULATOR_CPUINFO="$key_tmp/cpuB" EMULATOR_NPROC=4 GITHUB_ENV="$key_tmp/envB" bash tool/emulator/avd_cache_key.sh > /dev/null 2>&1
kA="$(sed -n 's/^EMULATOR_AVD_CACHE_KEY=//p' "$key_tmp/env")"; kB="$(sed -n 's/^EMULATOR_AVD_CACHE_KEY=//p' "$key_tmp/envB")"
[[ -n "$kB" && "$kA" != "$kB" && "$kB" == "${kA%-"$cpuA"}-${cpuB}" ]] || { echo "4.4.9b: another CPU must give another AVD cache key: $kA / $kB" >&2; exit 1; }
env "${key_env[@]}" EMULATOR_CPUINFO="$key_tmp/none" EMULATOR_NPROC=4 GITHUB_ENV="$key_tmp/envN" GITHUB_JOB=emulator bash tool/emulator/avd_cache_key.sh > "$key_tmp/outN" 2>&1
grep -Eq '^EMULATOR_AVD_CACHE_KEY=.*-clean-cfg6-cpuunknown-77-1-emulator-[0-9]+$' "$key_tmp/envN" && grep -q 'could not read the host CPU' "$key_tmp/outN" ||
  { echo "4.4.9b: unreadable cpuinfo must give a one-run key: $(cat "$key_tmp/envN")" >&2; exit 1; }
echo "4.4.9b AVD cache key: cpu ${cpuA} vs ${cpuB} -> different keys; flag order irrelevant; unreadable -> one-run key"
rm -rf "$key_tmp"
# Round 4.4.9b: no AVD cache restore may fall back to another key (another
# CPU's snapshot): every step that restores ~/.android/avd uses exactly
# EMULATOR_AVD_CACHE_KEY and no restore-keys; the warm-up and the shard
# job compute the key with the same script; nothing else edits the key.
python3 - "$workflow" <<'PY' || { echo "4.4.9b: AVD cache restore must be exact-key only, same script in warm-up and shards" >&2; exit 1; }
import re, sys
wf = open(sys.argv[1]).read()
steps = re.split(r"\n      - name: ", wf)
avd = [s for s in steps if "~/.android/avd" in s]
restores = [s for s in avd if "actions/cache/restore@" in s]
saves = [s for s in avd if "actions/cache/save@" in s]
ok = len(restores) == 2 and len(saves) >= 1
for s in avd:
    ok &= "restore-keys" not in s and "key: ${{ env.EMULATOR_AVD_CACHE_KEY }}" in s
ok &= wf.count("run: bash tool/emulator/avd_cache_key.sh\n") == 2
ok &= len(re.findall(r"EMULATOR_AVD_CACHE_KEY\s*[:=]", wf)) == 0
sys.exit(0 if ok else 1)
PY
echo "4.4.9b workflow: 2 AVD restores + save on the exact key, no restore-keys, one key script for warm-up and shards"
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
# Job = flow step + setup (checkout, KVM, APK, caches); the shard's own
# snapshot step is counted separately below (round 4.4.5).
if (( job_smoke < step_smoke + 20 || job_full < step_full + 20 )); then
  echo "job timeouts should leave 20 min for setup beyond the flow step" >&2
  exit 1
fi
# Round 4.4.2 (review item 1): the boot retry fits the job timeout:
# setup/post allowance + dead first attempt (action start + boot + ready +
# unlock, no BOOT line) + the boot-death check step + the retry flow step.
read -r jb_setup jb_dead < <(bash -c 'source tool/emulator/plan.sh; echo "$JOB_SETUP_POST_MIN $((SHARD_ACTION_START_S + SHARD_BOOT_S + SHARD_GETPROP_BUDGET_S + SHARD_ACTION_ADB_S + SHARD_PREBOOT_S))"')
bc_min="$(awk '/- name: Check for a boot death/ { f = 1 } f && /timeout-minutes:/ { print $2; exit }' "$workflow")"
jb_create_min="$(awk '/^  emulator:/ { e = 1 } e && /- name: Create AVD snapshot/ { f = 1 } f && /timeout-minutes:/ { print $2; exit }' "$workflow")"
jb_dead_r="$(bash -c 'source tool/emulator/plan.sh; echo "$((SHARD_ACTION_START_S + SHARD_RETRY_BOOT_S + SHARD_GETPROP_BUDGET_S + SHARD_ACTION_ADB_S + SHARD_PREBOOT_S))"')"
# Round 4.4.6: the warn step after a failed create is bounded inside
# (create_warn.sh: kill 4s + 1s kill-after, rm) = E2E_WARN_S 6s.
jb_warn_s="$(bash -c 'source tool/emulator/plan.sh; echo "$E2E_WARN_S"')"
grep -q 'timeout --kill-after=1 4 adb emu kill' tool/emulator/create_warn.sh || { echo "create_warn: kill must be bounded (4s + 1s = E2E_WARN_S - 1)" >&2; exit 1; }
[[ "$jb_create_min" == "$(bash -c 'source tool/emulator/plan.sh; echo "$SHARD_CREATE_STEP_MIN"')" ]] || { echo "shard Create AVD snapshot timeout ${jb_create_min} != plan.sh SHARD_CREATE_STEP_MIN" >&2; exit 1; }
boot_to="$(sed -n 's/^  EMULATOR_BOOT_TIMEOUT: "\([0-9]*\)"$/\1/p' "$workflow")"
[[ "$boot_to" == "$(bash -c 'source tool/emulator/plan.sh; echo "$SHARD_BOOT_S"')" ]] || { echo "EMULATOR_BOOT_TIMEOUT ${boot_to} != plan.sh SHARD_BOOT_S" >&2; exit 1; }
(( boot_to >= 150 )) || { echo "EMULATOR_BOOT_TIMEOUT ${boot_to}s is under Manu's 150s floor" >&2; exit 1; }
for t in smoke full; do
  if [[ "$t" == smoke ]]; then st="$step_smoke" jt="$job_smoke"; else st="$step_full" jt="$job_full"; fi
  need_s=$(( jb_setup * 60 + jb_dead + bc_min * 60 + st * 60 ))
  need_m=$(( (need_s + 59) / 60 ))
  if (( jt * 60 < need_s )); then
    echo "job timeout ${jt} min (${t}) < setup ${jb_setup} + dead attempt ${jb_dead}s + boot check ${bc_min} + retry ${st} = ${need_m} min" >&2; exit 1
  fi
  echo "job budget (${t}): ${jb_setup} + ${jb_dead}s + ${bc_min} + ${st} = ${need_m} min <= ${jt}"
  # Round 4.4.3 (Reviewer): each term of the formula, from its source, and
  # the sum, so a dropped term cannot pass on the 68/101 values alone.
  [[ "$jb_setup" == 20 && "$jb_dead" == 211 && "$bc_min" == 2 ]] || { echo "job budget terms: setup/post 20 min, dead attempt 211s (30 + 150 + 4 getprop budget + 5 keyevent + 22 pre-BOOT incl. readiness, round 4.4.9), boot check 2 min; got ${jb_setup} ${jb_dead} ${bc_min}" >&2; exit 1; }
  if [[ "$t" == smoke ]]; then want_st=75 want_need=6031; else want_st=42 want_need=4051; fi
  [[ "$st" == "$want_st" ]] || { echo "job budget (${t}): retry step cap ${st}, want ${want_st} (same as the flow step)" >&2; exit 1; }
  (( need_s == want_need )) || { echo "job budget (${t}): need ${need_s}s != 20 min + 211s + 2 min + ${want_st} min = ${want_need}s (a term is missing)" >&2; exit 1; }
  # Round 4.4.5 (Manu nit 1): the warm-up-refused path also runs the shard's
  # "Create AVD snapshot" step (its timeout-minutes, from the workflow), and
  # its dead first attempt boots with the retry wait.
  need_r=$(( jb_setup * 60 + jb_create_min * 60 + jb_warn_s + jb_dead_r + bc_min * 60 + st * 60 ))
  (( jt * 60 >= need_r )) || { echo "job timeout ${jt} min (${t}) < refused path: setup ${jb_setup} + create ${jb_create_min} min + dead ${jb_dead_r}s + boot check ${bc_min} + retry ${st} = ${need_r}s" >&2; exit 1; }
  if [[ "$t" == smoke ]]; then want_r=6057; else want_r=4077; fi
  [[ "$jb_create_min" == 2 && "$jb_warn_s" == 6 && "$jb_dead_r" == 111 && "$need_r" == "$want_r" ]] || { echo "job budget (${t}) refused path: create 2 min, warn 6s, dead 111s, need ${want_r}s; got ${jb_create_min} ${jb_dead_r} ${need_r}" >&2; exit 1; }
  # Round 4.4.5 (Satyavrat): explicit limits, not only the job timeout.
  if [[ "$t" == smoke ]]; then lim=6060; else lim=4080; fi
  (( need_s <= lim && need_r <= lim )) || { echo "job budget (${t}): warm ${need_s}s / refused ${need_r}s > ${lim}s" >&2; exit 1; }
  echo "job budget (${t}, warm-up refused): ${jb_setup} + ${jb_create_min} + ${jb_dead_r}s + ${bc_min} + ${st} = ${need_r}s <= $((jt * 60))s"
done
[[ "$job_full" == 68 && "$job_smoke" == 101 ]] || { echo "job timeouts: full 68, smoke 101 (round 4.4.2 retry budget)" >&2; exit 1; }
# Round 4.4.3: end-to-end worst case on every path (Sanu: <= 2700s) and the
# boot-retry path <= 2640s (Satyavrat: 44.0 min), from plan.sh caps and
# the workflow's boot waits; per-shard <= 39 min is checked below.
retry_to="$(sed -n 's/^  EMULATOR_RETRY_BOOT_TIMEOUT: "\([0-9]*\)"$/\1/p' "$workflow")"
[[ -n "$retry_to" && "$retry_to" == "$(bash -c 'source tool/emulator/plan.sh; echo "$SHARD_RETRY_BOOT_S"')" ]] || { echo "EMULATOR_RETRY_BOOT_TIMEOUT ${retry_to:-unset} != plan.sh SHARD_RETRY_BOOT_S" >&2; exit 1; }
(( retry_to * 1000 >= 337 * 148 )) || { echo "retry boot wait ${retry_to}s leaves < 1.48x the slowest cold boot (33.7s)" >&2; exit 1; }
grep -q 'timeout "${SHARD_GETPROP_S:-5}" adb shell getprop debug.temple.snapshot_marker' tool/emulator/run_shard.sh || { echo "run_shard: the getprop before BOOT is capped (SHARD_GETPROP_S)" >&2; exit 1; }
[[ "$(bash -c 'source tool/emulator/plan.sh; echo "$((SHARD_ACTION_START_S + SHARD_BOOT_S + SHARD_GETPROP_BUDGET_S + SHARD_ACTION_ADB_S + SHARD_PREBOOT_S)) $SHARD_GETPROP_S"')" == "211 5" ]] || { echo "dead attempt = 30 start + 150 boot + 5 keyevent + 10 pre-BOOT watchdog = 195s; getprop cap 5s" >&2; exit 1; }
# Round 4.4.4 (Manu nit 1): the watchdog covers all pre-BOOT work. Only the
# capped getprop runs between the watchdog's start and the BOOT write (awk:
# no other adb call, no readiness, unlock or animations there), and
# SHARD_PREBOOT_S >= that sum + 5s margin.
read -r pb_s pb_sum < <(bash -c 'source tool/emulator/plan.sh; echo "$SHARD_PREBOOT_S $((SHARD_GETPROP_S + SHARD_READY_S))"')
(( pb_s >= pb_sum + 5 )) || { echo "SHARD_PREBOOT_S ${pb_s}s < pre-BOOT work ${pb_sum}s + 5s margin" >&2; exit 1; }
awk '/preboot_s="\$\{EMULATOR_PREBOOT_S/ { a = 1 } a && /printf .BOOT / { exit }
     a && /(^|[^_a-z])adb / && !/getprop debug.temple.snapshot_marker/ && !/^ *#/ { bad = bad NR ": " $0 "\n" }
     a && /SHARD_UNLOCK_TRIES|ANIM_OFF_CMD/ { bad = bad NR ": " $0 "\n" }
     END { if (bad != "") { printf "%s", bad; exit 1 } }' tool/emulator/run_shard.sh ||
  { echo "run_shard: pre-BOOT work beyond the capped getprop (watchdog sum)" >&2; exit 1; }
# Round 4.4.6 (Reviewer 3): between the watchdog start and the BOOT line
# only the capped getprop and the claim bookkeeping may run: every other
# command line there fails (an exact allow-list, not a deny-list).
python3 - tool/emulator/run_shard.sh <<'PY' || { echo "run_shard: a command other than the capped getprop runs before BOOT" >&2; exit 1; }
import sys
src = open(sys.argv[1]).read().splitlines()
a = next(i for i, l in enumerate(src) if l.strip() == "preboot_watchdog=$!")
b = next(i for i, l in enumerate(src) if i > a and l.strip().startswith("printf 'BOOT "))
allowed = {
    """marker="$(timeout "${SHARD_GETPROP_S:-5}" adb shell getprop debug.temple.snapshot_marker 2>/dev/null </dev/null | tr -d '\\r' || true)\"""",
    'if [[ "$marker" == 1 ]]; then boot=snapshot; else boot=cold; fi',
    'svc_out="$(wait_services_ready "$services_wait_s" 2>&1)"; svc_rc=$?',
    'if ! mkdir "$claim" 2>/dev/null; then',
    'wait "$preboot_watchdog" 2>/dev/null; rmdir "$claim" 2>/dev/null; exit 1',
    'fi',
    '[[ -n "${EMULATOR_TEST_BOOT_WRITE_DELAY_S:-}" ]] && sleep "$EMULATOR_TEST_BOOT_WRITE_DELAY_S"',
    'kill "$preboot_watchdog" 2>/dev/null; wait "$preboot_watchdog" 2>/dev/null',
    'rmdir "$claim" 2>/dev/null',
    # Round 4.4.9: readiness decides a dead boot before the BOOT line.
    'printf \'%s\\n\' "$svc_out"',
    'host_cpu="$(bash tool/emulator/cpu_id.sh --describe 2>/dev/null || echo unknown) (cache key cpu ${EMULATOR_CPU_ID:-unset})"',
    'if (( svc_rc != 0 )); then',
    '''printf 'DEAD boot %s%s: system services not ready after %ss (%s); host cpu %s\\n' "$tier" "${shard:+-${shard}}" "$services_wait_s" "$(tail -1 <<<"$svc_out")" "$host_cpu" >> "${artifacts}/results.txt"''',
    'echo "::error::emulator ${tier}${shard:+ shard ${shard}}: system services not ready after ${services_wait_s}s; dead boot (no BOOT line), the boot check retries once"',
    'exit 1',
}
bad = [f"{i + 1}: {l}" for i, l in enumerate(src[a + 1:b], a + 1) if l.strip() and not l.strip().startswith("#") and l.strip() not in allowed]
if bad:
    print("\n".join(bad)); sys.exit(1)
PY
# Round 4.4.6 (Reviewer 2): every adb call of the harness lifecycle (not
# the flows, which have their own per-flow caps) runs under a timeout.
for f in tool/emulator/run_shard.sh tool/emulator/services_ready.sh tool/emulator/prepare_avd.sh tool/emulator/snapshot_create.sh tool/emulator/create_warn.sh; do
  awk '/^[[:space:]]*#/ { next } /(^|[^_a-zA-Z.])adb / && !/timeout/ && !/echo / { print FILENAME ":" NR ": " $0; bad = 1 } END { exit bad }' "$f" ||
    { echo "untimed adb call in ${f}" >&2; exit 1; }
done
grep -q 'preboot_s="${EMULATOR_PREBOOT_S:-$SHARD_PREBOOT_S}"' tool/emulator/run_shard.sh || { echo "run_shard: pre-BOOT watchdog uses SHARD_PREBOOT_S" >&2; exit 1; }
read -r e2e_warm e2e_retry e2e_cold e2e_cretry e2e_refused e2e_rretry e2e_cfretry e2e_max < <(bash -c 'source tool/emulator/plan.sh; plan_e2e_s')
# Round 4.4.5 (Manu nit 1): all seven paths, incl. warm-up refused + boot
# death and a failed shard create + boot death.
for pth in "warm $e2e_warm" "retry $e2e_retry" "cold $e2e_cold" "cold_retry $e2e_cretry" "refused $e2e_refused" "refused_retry $e2e_rretry" "create_failed_retry $e2e_cfretry"; do
  (( ${pth#* } <= 2700 )) || { echo "end-to-end ${pth% *} worst case ${pth#* }s > 2700s (45 min); max shard ${e2e_max}s" >&2; exit 1; }
done
(( e2e_retry <= 2640 )) || { echo "boot-retry end-to-end ${e2e_retry}s > 2640s (44.0 min)" >&2; exit 1; }
echo "end-to-end worst (s): warm ${e2e_warm}, retry ${e2e_retry}, cold ${e2e_cold}, cold+retry ${e2e_cretry}, warm-up refused ${e2e_refused}, refused+retry ${e2e_rretry}, create failed+retry ${e2e_cfretry}; max shard ${e2e_max}"
[[ "$e2e_warm $e2e_retry $e2e_cold $e2e_cretry $e2e_refused $e2e_rretry $e2e_cfretry $e2e_max" == "2483 2599 2533 2649 2523 2639 2675 2129" ]] || { echo "end-to-end table changed: $e2e_warm $e2e_retry $e2e_cold $e2e_cretry $e2e_refused $e2e_rretry $e2e_cfretry $e2e_max (update PR body)" >&2; exit 1; }
# Per-flow caps are not lowered to fit (Sanu): FLOW_CAP_S 600, 26/08 at 300.
[[ "$(bash -c 'source tool/emulator/plan.sh; echo "$FLOW_CAP_S $(plan_cap_s 26-drawer-nav-stack) $(plan_cap_s 08-list-detail)"')" == "600 300 300" ]] || { echo "per-flow cap changed" >&2; exit 1; }
# Round 4.4.4 (Satyavrat A): the model's create/warm-up terms follow the workflow.
python3 - "$workflow" "$(bash -c 'source tool/emulator/plan.sh; echo "$SHARD_CREATE_BOOT_S $SHARD_CREATE_READY_S $SHARD_CREATE_SETTLE_S $SHARD_ACTION_ADB_S $WARMUP_CREATE_BOOT_S $SHARD_CREATE_STEP_MIN"')" <<'PY' || exit 1
import re, sys
wf = open(sys.argv[1]).read(); cb, cr, cs, aa, wb, cm = sys.argv[2].split()
assert f'EMULATOR_CREATE_BOOT_TIMEOUT: "{wb}"' in wf and f'EMULATOR_SHARD_CREATE_BOOT_TIMEOUT: "{cb}"' in wf and f'EMULATOR_ACTION_ADB_S: "{aa}"' in wf, "create boot / action adb env"
wj = wf[wf.index("\n  avd-warmup:"):wf.index("\n  emulator:")]; ej = wf[wf.index("\n  emulator:"):]
assert wj.count("emulator-boot-timeout: ${{ env.EMULATOR_CREATE_BOOT_TIMEOUT }}") == 1 and ej.count("emulator-boot-timeout: ${{ env.EMULATOR_SHARD_CREATE_BOOT_TIMEOUT }}") == 1 and "emulator-boot-timeout: 600" not in wf
assert "emulator-boot-timeout: ${{ (steps.create-avd.outcome == 'success' || steps.create-avd.outcome == 'failure') && env.EMULATOR_RETRY_BOOT_TIMEOUT || env.EMULATOR_BOOT_TIMEOUT }}" in ej, "flows boot with the retry wait whenever the shard ran its create step"
assert "EMULATOR_DISABLE_ANIMATIONS: false" in wf and "disable-animations: true" not in wf
job = wf[wf.index("\n  emulator:"):]
i = job.index("\n      - name: Create AVD snapshot\n"); st = job[i:job.find("\n      - name:", i + 1)]
assert f'EMULATOR_SNAPSHOT_READY_S: "{cr}"' in st and f'EMULATOR_SNAPSHOT_SETTLE_S: "{cs}"' in st and f"timeout-minutes: {cm}\n" in st, st
for jn in ("\n  avd-warmup:", "\n  emulator:"):
    names = re.findall(r"\n      - name: (.+)", wf[wf.index(jn):])
    assert names.index("Cap the emulator action's adb calls") < names.index("Create AVD snapshot"), (jn, names)
# Round 4.4.5 (Manu blocker): installed in place in the action's own
# platform-tools dir, never via GITHUB_PATH.
assert wf.count('run: bash tool/emulator/adb_shim/install.sh "${ANDROID_HOME}/platform-tools"') == 2
assert "adb_shim" not in "".join(l for l in wf.splitlines() if "GITHUB_PATH" in l), "adb_shim on GITHUB_PATH loses to the action's addPath"
PY
# Round 4.4.5 (Satyavrat): a shard create that is slow / times out / fails
# warns and never fails the shard: continue-on-error, a warning step on its
# failure, and the flows step does not depend on it.
python3 - "$workflow" <<'PY' || exit 1
import sys
wf = open(sys.argv[1]).read(); job = wf[wf.index("\n  emulator:"):]
def step(name):
    i = job.index(f"\n      - name: {name}\n"); j = job.find("\n      - name:", i + 1)
    return job[i:j]
cr, wn, fl = step("Create AVD snapshot"), step("Warn on a failed shard snapshot create"), step("Run emulator flows")
assert "continue-on-error: true" in cr, cr
assert "steps.create-avd.outcome == 'failure'" in wn and 'run: bash tool/emulator/create_warn.sh "${{ steps.create-avd.outcome }}"' in wn, wn
assert job.index("name: Warn on a failed shard snapshot create") < job.index("name: Run emulator flows\n"), "warning before flows"
assert "if: ${{ !cancelled() && steps.resolve-apk.outcome == 'success' }}" in fl, fl
PY
for oc in failure cancelled; do
  rc=0; o="$(EMULATOR_SHARD=7 EMULATOR_SHARD_CREATE_BOOT_TIMEOUT=50 bash tool/emulator/create_warn.sh "$oc")" || rc=$?
  [[ "$rc" == 0 && "$o" == "::warning::shard 7: snapshot create boot exceeded 50 s or the create step failed (${oc}); flows will cold-boot" ]] ||
    { echo "create_warn ${oc}: rc ${rc}, want a ::warning:: and rc 0: ${o}" >&2; exit 1; }
done
o="$(bash tool/emulator/create_warn.sh success)"; [[ -z "$o" ]] || { echo "create_warn success should be silent: $o" >&2; exit 1; }
echo "shard create failure: ::warning:: and the shard proceeds"
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
  06a1-filters-single
  06a2-filters-single
  06b-filters-combined
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
  29a1-filter-matrix-home-state
  29a2-filter-matrix-home-state
  29b1-filter-matrix-home-district
  29b2-filter-matrix-home-district
  29c1-filter-matrix-home-deity
  29c2-filter-matrix-home-deity
  29d1-filter-matrix-drawer-all-state
  29d2-filter-matrix-drawer-all-state
  29e1-filter-matrix-drawer-all-district
  29e2-filter-matrix-drawer-all-district
  29f1-filter-matrix-drawer-all-deity
  29f2-filter-matrix-drawer-all-deity
  30a1-filter-matrix-drawer-bar-state
  30a2-filter-matrix-drawer-bar-state
  30b1-filter-matrix-drawer-bar-district
  30b2-filter-matrix-drawer-bar-district
  30c1-filter-matrix-drawer-bar-deity
  30c2-filter-matrix-drawer-bar-deity
  30e1-filter-matrix-search-state
  30e2-filter-matrix-search-state
  30f1-filter-matrix-search-district
  30f2-filter-matrix-search-district
  30g1-filter-matrix-search-deity
  30g2-filter-matrix-search-deity
  30s1-filter-matrix-seq1
  30s2-filter-matrix-seq2
  30s3-filter-matrix-seq3
  30s4-filter-matrix-seq4
  30s5-filter-matrix-seq5
  30d-near-me
  31-filter-chain
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
if grep -q 'ui_wait_scrolled 15 --text-regex' tool/emulator/flows/13_licences.sh; then
  echo "flow 13 must scroll the drawer, not fling the whole screen" >&2
  exit 1
fi
if ! grep -q 'ui_wait 15 --text-contains "District boundaries"' tool/emulator/flows/13_licences.sh; then
  echo "flow 13 must see the Licences screen before open-licences passes" >&2
  exit 1
fi
# Run 42681684346 shard 8: the Licences tile is on screen and the drawer
# stays open, so a tap alone must not pass open-licences.
lic13=tool/emulator/testdata/run42681684346
lic_dir="$(mktemp -d)"
eval "$(sed -n '/^open_licences_screen()/,/^}/p' tool/emulator/flows/13_licences.sh)"
run_open_licences() {
  local dump="$1"
  local out="$2"
  (
    set -euo pipefail
    export EMULATOR_FLOW=13-licences EMULATOR_ARTIFACTS="$out" EMULATOR_PACKAGE=com.example
    # shellcheck disable=SC1091
    source tool/emulator/lib/common.sh
    ui_dump() { return 0; }
    ui_tap() { echo TAP >> "$out/log"; return 0; }
    ui_screen_size() { echo 320 640; }
    ui_back() { return 0; }
    step_shot() { :; }
    save_step_dump() { :; }
    dismiss_blockers() { return 0; }
    scroll_drawer_top() { echo TOP >> "$out/log"; return 0; }
    sleep() { echo SLEEP >> "$out/log"; }
    ui_wait() {
      local timeout="$1"
      shift
      echo "WAIT $timeout $*" >> "$out/log"
      ui_find "$@"
    }
    # shellcheck disable=SC1091
    eval "$(sed -n '/^open_licences_screen()/,/^}/p' tool/emulator/flows/13_licences.sh)"
    DUMP="$dump"
    if open_licences_screen; then
      pass_step open-licences
    else
      fail_step open-licences "Licences tile tap did not open the Licences screen"
    fi
  )
}
rm -rf "$lic_dir/fail" "$lic_dir/pass"
mkdir -p "$lic_dir/fail" "$lic_dir/pass"
run_open_licences "$lic13/licences-drawer-open.xml" "$lic_dir/fail"
if ! grep -q 'FAIL 13-licences: open-licences: Licences tile tap did not open the Licences screen' "$lic_dir/fail/results.txt"; then
  echo "a drawer that stays open must fail open-licences" >&2
  cat "$lic_dir/fail/results.txt" "$lic_dir/fail/log" >&2
  exit 1
fi
if ! grep -q 'WAIT 15 --text-contains District boundaries' "$lic_dir/fail/log"; then
  echo "open-licences must wait for District boundaries" >&2
  cat "$lic_dir/fail/log" >&2
  exit 1
fi
taps="$(grep -c '^TAP$' "$lic_dir/fail/log" || true)"
if [[ "$taps" -ne 2 ]]; then
  echo "a no-op Licences tap must be retried once, got ${taps}" >&2
  cat "$lic_dir/fail/log" >&2
  exit 1
fi
run_open_licences "$lic13/licences-screen.xml" "$lic_dir/pass"
if ! grep -q 'PASS 13-licences: open-licences' "$lic_dir/pass/results.txt"; then
  echo "a Licences screen must pass open-licences" >&2
  cat "$lic_dir/pass/results.txt" "$lic_dir/pass/log" >&2
  exit 1
fi
echo "flow 13 dry-run drawer: $(grep open-licences "$lic_dir/fail/results.txt")"
echo "flow 13 dry-run screen: $(grep open-licences "$lic_dir/pass/results.txt")"
echo "flow 13 dry-run log: $(tr '\n' ' ' < "$lic_dir/fail/log")"
rm -rf "$lic_dir"
# Run 42689905451. No-state District leaves Tamil Nadu applied and the
# sheet gone. 06a is still on Choose a state first. Vishnu is not in the
# visible head; Devi is a filter-deity-top row. Repeat-2 is sitting on Murugan.
run899=tool/emulator/testdata/run42689905451
python3 - "$run899" <<'PY' || { echo "run 42689905451 dump shape" >&2; exit 1; }
import sys
from pathlib import Path
from xml.etree import ElementTree as ET
root = Path(sys.argv[1])
def load(name):
    raw = (root / name).read_text(encoding="utf-8", errors="replace")
    return ET.fromstring(raw[raw.find("<"):])
def ids(tree):
    return {n.attrib.get("resource-id") or "" for n in tree.iter("node")}
no_sheet = load("07-no-district-sheet.xml")
no_ids = ids(no_sheet)
assert "filter-sheet" not in no_ids
assert any((n.attrib.get("content-desc") or "") == "Tamil Nadu" and (n.attrib.get("resource-id") or "") == "filter-chip-state" for n in no_sheet.iter("node"))
assert any((n.attrib.get("content-desc") or "") == "District" and (n.attrib.get("resource-id") or "") == "filter-chip-district" for n in no_sheet.iter("node"))
state_gate = ids(load("06a-district-still-state.xml"))
assert "filter-choose-state-first" in state_gate and "filter-sheet-title-state" in state_gate
assert not any(i.startswith("filter-option-district-") for i in state_gate)
vishnu = ids(load("06b-vishnu.xml"))
assert "filter-deity-top-Devi" in vishnu
assert "filter-deity-top-Vishnu" not in vishnu and "filter-option-deity-Vishnu" not in vishnu
repeat = ids(load("06a-deity-repeat-2.xml"))
assert "filter-option-deity-Murugan" in repeat
print("run899 dumps: TN applied with no sheet; district pick still on State; Vishnu not in the head; Murugan is on screen")
PY
if ! grep -q 'filter-sheet-title-district' tool/emulator/lib/common.sh; then
  echo "apply_sheet must not tap Show on the District sheet that follows State" >&2
  exit 1
fi
if ! grep -q 'finish_choose_state_first' tool/emulator/flows/06_filters.sh || ! grep -q 'TN_DISTRICT_PICK' tool/emulator/flows/06_filters.sh; then
  echo "06 district pick must apply Tamil Nadu and then choose Madurai" >&2
  exit 1
fi
if ! grep -q 'select_labeled @first DISTRICT' tool/emulator/flows/21_district_close_then_other_chip.sh || ! grep -q 'step_reset' tool/emulator/flows/21_district_close_then_other_chip.sh; then
  echo "flow 21 must pick @first under a step budget" >&2
  exit 1
fi
(
  set -euo pipefail
  export EMULATOR_FLOW=self-test EMULATOR_ARTIFACTS=/tmp EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  ui_dump() { return 0; }
  ui_tap() { return 0; }
  ui_type() { echo "TYPED $*"; return 0; }
  sleep() { :; }
  adb_shell_capped() { return 0; }
  DUMP="$run899/06b-vishnu.xml"
  sheet_search_pick deity Devi '^Devi( +[0-9]+)?$'
  [[ "$SELECTED_LABEL" == Devi ]] || { echo "top-row deity pick got ${SELECTED_LABEL}" >&2; exit 1; }
  DUMP="$run899/06a-deity-repeat-2.xml"
  sheet_search_pick deity Murugan '^Murugan( +[0-9]+)?$'
  [[ "$SELECTED_LABEL" == Murugan ]] || { echo "repeat pick got ${SELECTED_LABEL}" >&2; exit 1; }
  echo "run899 dry-run: Devi via filter-deity-top; Murugan via filter-option"
)
run990=tool/emulator/testdata/run42699042193
# Run 42699042193: Shiva repeat is the letter list at Durga–Ganesha, not the
# Shiva row. 30s5's Shiva-scoped district sheet has no Madurai id. Flow 21's
# dump has no deity chip (it was scrolled off the 320px row).
python3 - "$run990" <<'PY' || exit 1
import pathlib, sys
root = pathlib.Path(sys.argv[1])
repeat = (root / "06a-deity-repeat-2.xml").read_text()
assert "filter-option-deity-Shiva" not in repeat and "filter-deity-top-Shiva" not in repeat
assert "filter-option-deity-Durga" in repeat
district = (root / "30s5-district-select.xml").read_text()
assert "filter-option-district-Madurai" not in district
assert "filter-sheet-title-district" in district
deity = (root / "21-deity-chip.xml").read_text()
assert "filter-chip-deity" not in deity
assert "filter-chip-district" in deity
print("run990 dumps: Shiva not on the repeat screen; Madurai absent under Shiva; deity chip off the 320px row")
PY
(
  set -euo pipefail
  export EMULATOR_FLOW=self-test EMULATOR_ARTIFACTS=/tmp EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  ui_dump() { return 0; }
  DUMP="$run990/30s2-deity-pick-close.xml"
  declare -A APPLIED=([state]="Tamil Nadu" [deity]="Shiva")
  [[ "$(scoped_pick district)" == @first ]]
  APPLIED=([state]="Tamil Nadu" [district]="Madurai")
  [[ "$(scoped_pick deity)" == @first ]]
  echo "run990 dry-run: Shiva-scoped district and Madurai-scoped deity are @first"
)
topxml="$(mktemp)"
printf '%s\n' '<hierarchy><node resource-id="filter-deity-top-Shiva" content-desc="Shiva  12" bounds="[16,300][300,348]" /></hierarchy>' > "$topxml"
seek_out="$(python3 tool/emulator/lib/ui.py option-seek "$topxml" --kind deity --name Shiva --order deity --min-top 0 --max-top 600)"
[[ "$seek_out" == tap\ * ]] || { echo "filter-deity-top-Shiva must be a deity seek target: $seek_out" >&2; exit 1; }
rm -f "$topxml"
echo "run990 dry-run: filter-deity-top-Shiva is tappable"
run427=tool/emulator/testdata/run42710826857
python3 - "$run427/30s2-state-clear.xml" <<'PY' || exit 1
import pathlib, sys
text = pathlib.Path(sys.argv[1]).read_text()
assert "filter-option-state-any" not in text
assert "filter-option-state-Himachal Pradesh" in text
assert "filter-region-jump-north" in text
print("run427 dump: state sheet is in North, Any state is off screen")
PY
run427_head="$(mktemp)"
python3 - "$run427/30s2-state-clear.xml" "$run427_head" <<'PY'
import pathlib, sys
text = pathlib.Path(sys.argv[1]).read_text()
node = '<node resource-id="filter-option-state-any" content-desc="Any state  4" bounds="[0,300][320,348]" />'
text = text.replace('<hierarchy rotation="0">', '<hierarchy rotation="0">' + node, 1)
pathlib.Path(sys.argv[2]).write_text(text)
PY
run427_out="$(
  export EMULATOR_FLOW=self-test EMULATOR_ARTIFACTS=/tmp EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  n=0
  ui_dump() { n=$((n + 1)); if (( n == 1 )); then cp "$run427/30s2-state-clear.xml" "$DUMP"; else cp "$run427_head" "$DUMP"; fi; }
  ui_sheet_swipe() { echo "SWIPE $*"; return 0; }
  ui_tap() { echo "CLEAR"; }
  sleep() { :; }
  adb_shell_capped() { return 0; }
  ensure_list_head state
)"
grep -q '^SWIPE' <<<"$run427_out" && { echo "run427: clear/jump must reach Any state without a swipe: $run427_out" >&2; exit 1; }
grep -q '^CLEAR' <<<"$run427_out" || { echo "run427: search field should be cleared on the North dump: $run427_out" >&2; exit 1; }
rm -f "$run427_head"
echo "run427 dry-run: Any state returns after search clear, no swipe"
# Short sheet: Any is not pinned, so clearing an empty search leaves the
# North window in place. One bounded fallback swipe then reaches the head.
run427_short_head="$(mktemp)"
python3 - "$run427/30s2-state-clear.xml" "$run427_short_head" <<'PY'
import pathlib, sys
text = pathlib.Path(sys.argv[1]).read_text()
node = '<node resource-id="filter-option-state-any" content-desc="Any state  4" bounds="[0,300][320,348]" />'
text = text.replace('<hierarchy rotation="0">', '<hierarchy rotation="0">' + node, 1)
pathlib.Path(sys.argv[2]).write_text(text)
PY
run427_short="$(
  export EMULATOR_FLOW=self-test EMULATOR_ARTIFACTS=/tmp EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  n=0
  ui_dump() {
    n=$((n + 1))
    if (( n <= 2 )); then cp "$run427/30s2-state-clear.xml" "$DUMP"
    else cp "$run427_short_head" "$DUMP"; fi
  }
  ui_sheet_swipe() { echo "SWIPE $*"; return 0; }
  ui_tap() { echo "CLEAR"; }
  sleep() { :; }
  adb_shell_capped() { return 0; }
  ensure_list_head state
)"
[[ "$(grep -c '^SWIPE ' <<<"$run427_short")" == 1 ]] || {
  echo "run427 short sheet: one fallback swipe must reach Any state: $run427_short" >&2
  exit 1
}
rm -f "$run427_short_head"
echo "run427 dry-run: unpinned short sheet reaches Any state in one fallback swipe"
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
if grep -q 'pick="\$ALL_INDIA_DEITY_PICK"' tool/emulator/flows/17_entry_matrix.sh; then
  echo "flow 17 district fallback must be the chip's own pick, not a deity name" >&2
  exit 1
fi
if ! grep -q 'pick="\${PICK\[\$f\]}"' tool/emulator/flows/17_entry_matrix.sh; then
  echo "flow 17 must fall back to PICK[\$f] when scoped_pick fails" >&2
  exit 1
fi
if ! grep -q 'state chip check skipped' tool/emulator/flows/17_entry_matrix.sh; then
  echo "flow 17 must fail when the state-chip reset check is skipped" >&2
  exit 1
fi
if grep -q "text-regex '\\^DISTRICT\\$'" tool/emulator/flows/07_district.sh tool/emulator/flows/29_filter_matrix.sh; then
  echo "flows 07 and 29 must use the new District sheet title, not DISTRICT" >&2
  exit 1
fi
if grep -q "text-regex '\\^(District|All districts)'" tool/emulator/flows/07_district.sh; then
  echo "flow 07 must not treat the District chip label as an open sheet" >&2
  exit 1
fi
if ! grep -q 'district_sheet_lists_rows' tool/emulator/flows/07_district.sh; then
  echo "flow 07 must wait for filter-option-district-any" >&2
  exit 1
fi
if [[ "$(grep -c 'CHOOSE_STATE_APPLIED=""' tool/emulator/flows/29_filter_matrix.sh)" -lt 2 ]]; then
  echo "flow 29 must clear CHOOSE_STATE_APPLIED with each APPLIED reset" >&2
  exit 1
fi
if grep -q 'adb shell input keyevent 66' tool/emulator/flows/31_filter_chain.sh; then
  echo "flow 31 search submit must use adb_shell_capped" >&2
  exit 1
fi
if ! grep -q 'adb_shell_capped 8 input keyevent 66' tool/emulator/flows/31_filter_chain.sh; then
  echo "flow 31 must cap the search keyevent" >&2
  exit 1
fi
if ! grep -q 'filter_chips_idle' tool/emulator/flows/31_filter_chain.sh; then
  echo "flow 31 must assert chips reset after Clear all" >&2
  exit 1
fi
if grep -q -- '--text "Choose a state first"' tool/emulator/lib/common.sh tool/emulator/flows/07_district.sh tool/emulator/flows/31_filter_chain.sh; then
  echo "Choose a state first must be found by resource-id" >&2
  exit 1
fi
# A dump that only has the District chip (even with the words "All districts")
# must not pass sheet-lists-districts. The Any-district row must.
nit_dir="$(mktemp -d)"
cat > "$nit_dir/chip.xml" <<'XML'
<hierarchy rotation="0">
  <node text="District" resource-id="filter-chip-district" bounds="[10,20][180,70]" />
  <node text="All districts" resource-id="filter-chip-district" bounds="[10,20][180,70]" />
</hierarchy>
XML
cat > "$nit_dir/rows.xml" <<'XML'
<hierarchy rotation="0">
  <node text="District" resource-id="filter-chip-district" bounds="[10,20][180,70]" />
  <node text="All districts" resource-id="filter-option-district-any" bounds="[20,400][400,480]" />
</hierarchy>
XML
cat > "$nit_dir/idle.xml" <<'XML'
<hierarchy rotation="0">
  <node text="State" resource-id="filter-chip-state" bounds="[10,10][90,50]" />
  <node text="District" resource-id="filter-chip-district" bounds="[100,10][200,50]" />
  <node text="Deity" resource-id="filter-chip-deity" bounds="[210,10][280,50]" />
</hierarchy>
XML
cat > "$nit_dir/stuck.xml" <<'XML'
<hierarchy rotation="0">
  <node text="State" resource-id="filter-chip-state" bounds="[10,10][90,50]" />
  <node text="District" resource-id="filter-chip-district" bounds="[100,10][200,50]" />
  <node text="Deity" resource-id="filter-chip-deity" bounds="[210,10][280,50]" />
  <node text="" content-desc="Clear state filter" resource-id="filter-chip-state-clear" bounds="[70,10][110,50]" />
</hierarchy>
XML
(
  set -euo pipefail
  export EMULATOR_FLOW=self-test EMULATOR_ARTIFACTS="$nit_dir" EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  ui_dump() { return 0; }
  sleep() { :; }
  DUMP="$nit_dir/chip.xml"
  if district_sheet_lists_rows; then
    echo "chip-only dump must not pass sheet-lists-districts" >&2
    exit 1
  fi
  DUMP="$nit_dir/rows.xml"
  district_sheet_lists_rows || {
    echo "Any-district row must pass sheet-lists-districts" >&2
    exit 1
  }
  DUMP="$nit_dir/idle.xml"
  filter_chips_idle || { echo "idle chips must pass filter_chips_idle" >&2; exit 1; }
  DUMP="$nit_dir/stuck.xml"
  if filter_chips_idle; then
    echo "a leftover Clear state filter must fail filter_chips_idle" >&2
    exit 1
  fi
)
rm -rf "$nit_dir"
# Run 42675181050 shard 6: the sheet was open, but the title was not a text
# node. These waits must take the title id, sheet_open, or Close filters,
# and each names a timeout.
for sheet_wait in \
  'tool/emulator/flows/06_filters.sh:wait_filter_sheet 12' \
  'tool/emulator/flows/07_district.sh:wait_filter_sheet 20' \
  'tool/emulator/flows/17_entry_matrix.sh:wait_filter_sheet 20' \
  'tool/emulator/flows/29_filter_matrix.sh:wait_filter_sheet 20' \
  'tool/emulator/flows/31_filter_chain.sh:wait_filter_sheet 15'
do
  file="${sheet_wait%%:*}"
  needle="${sheet_wait#*:}"
  if ! grep -q "$needle" "$file"; then
    echo "sheet-open wait missing: $file should call $needle" >&2
    exit 1
  fi
  if grep -q 'ui_wait .*FILTER_SHEET_TITLE_RX' "$file"; then
    echo "$file still waits only on the title text regex" >&2
    exit 1
  fi
done
shard6=tool/emulator/testdata/run42675181050
(
  set -euo pipefail
  export EMULATOR_FLOW=self-test EMULATOR_ARTIFACTS="$shard6" EMULATOR_PACKAGE=com.shradhaventures.temple
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  ui_dump() { return 0; }
  sleep() { :; }
  DUMP="$shard6/sheet-open-merged.xml"
  if ui_find --text-regex "$FILTER_SHEET_TITLE_RX"; then
    echo "shard 6 merged dump must not match the title text regex" >&2
    exit 1
  fi
  ui_find --content-desc "Close filters" || { echo "shard 6 dump has no Close filters" >&2; exit 1; }
  ui_find --resource-id filter-choose-state-first || { echo "shard 6 dump missing filter-choose-state-first" >&2; exit 1; }
  ui_find --resource-id filter-option-state-any || { echo "shard 6 dump missing filter-option-state-any" >&2; exit 1; }
  if ui_find --resource-id filter-option-district-any; then
    echo "shard 6 state sheet must not already show a district row" >&2
    exit 1
  fi
  sheet_open || { echo "shard 6 merged sheet must count as open" >&2; exit 1; }
  wait_filter_sheet 2 || { echo "wait_filter_sheet must accept the shard 6 sheet" >&2; exit 1; }
  DUMP="$shard6/chip-bar.xml"
  ui_find --resource-id filter-chip-state || { echo "bar dump missing filter-chip-state" >&2; exit 1; }
  ui_find --resource-id filter-chip-district || { echo "bar dump missing filter-chip-district" >&2; exit 1; }
  ui_find --resource-id filter-chip-deity || { echo "bar dump missing filter-chip-deity" >&2; exit 1; }
  if sheet_open; then
    echo "idle State/District/Deity chips must not count as an open sheet" >&2
    exit 1
  fi
  DUMP="$shard6/title-node.xml"
  ui_find --resource-id filter-sheet-title-state --content-desc "State" || {
    echo "title id must be its own node labelled State" >&2
    exit 1
  }
  sheet_open || { echo "a separate title node must open the sheet" >&2; exit 1; }
  echo "shard6 dry-run: merged sheet opens via Close filters; chips do not; title id is its own node"
)
# Run 42681684346. Outside tap at y=40 is above the sheet (top 141).
# Kerala is further down this separate state sheet ("up near"), not absent
# in a district section. Landscape Apply is not in the tree.
run4268=tool/emulator/testdata/run42681684346
seek_kerala="$(python3 tool/emulator/lib/ui.py option-seek "$run4268/outside-empty.xml" --kind state --name Kerala --order state --min-top 150 --max-top 530)"
[[ "$seek_kerala" == "up near" ]] || { echo "Kerala on the separate state sheet should be up near, got ${seek_kerala}" >&2; exit 1; }
python3 - "$run4268/outside-empty.xml" "$run4268/land-apply.xml" <<'PY' || { echo "run 42681684346 dump shape" >&2; exit 1; }
import sys
from xml.etree import ElementTree as ET
def load(path):
    raw = open(path, encoding="utf-8", errors="replace").read()
    return ET.fromstring(raw[raw.find("<"):])
out = load(sys.argv[1])
sheet = next(n for n in out.iter("node") if n.attrib.get("resource-id") == "filter-sheet")
top = int(sheet.attrib["bounds"].split("][")[0].split(",")[1])
assert top > 40, top
assert any(n.attrib.get("resource-id") == "filter-option-state-Delhi" for n in out.iter("node"))
land = load(sys.argv[2])
descs = [n.attrib.get("content-desc") or "" for n in land.iter("node")]
assert not any(d.startswith("Show ") for d in descs), descs
print(f"run4268 dry-run: sheet top {top} > 40; Kerala up near; landscape has no Show button")
PY
if grep -q 'exercise_filter district .* "All districts"' tool/emulator/flows/06_filters.sh; then
  echo "06 district idle label is District, not All districts" >&2
  exit 1
fi
if ! grep -q 'exercise_filter district .* "District"' tool/emulator/flows/06_filters.sh; then
  echo "06 must expect the idle district chip to read District" >&2
  exit 1
fi
if ! grep -q "identifier: 'filter-sheet-search'" lib/widgets/filter_sheet.dart; then
  echo "the sheet search field needs resource-id filter-sheet-search" >&2
  exit 1
fi
if ! grep -q 'step_reset' tool/emulator/flows/29_filter_matrix.sh; then
  echo "29 matrix cells must start a step budget" >&2
  exit 1
fi
(
  set -euo pipefail
  export EMULATOR_FLOW=self-test EMULATOR_ARTIFACTS=/tmp EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  ui_dump() { return 0; }
  ui_tap() { return 0; }
  ui_type() { echo "TYPED $*"; return 0; }
  sleep() { :; }
  adb_shell_capped() { return 0; }
  DUMP="$run4268/outside-empty.xml"
  # The real dump has no search id yet. Adding the id and Kerala row is the
  # post-fix shape of this same sheet.
  python3 - "$DUMP" /tmp/run4268-with-search.xml <<'PY'
import sys
raw = open(sys.argv[1], encoding="utf-8", errors="replace").read()
extra = (
    '<node text="" resource-id="filter-sheet-search" class="android.widget.EditText" '
    'content-desc="Search state" bounds="[16,230][304,280]" />'
    '<node text="" resource-id="filter-option-state-Kerala" class="android.widget.Button" '
    'content-desc="Kerala  40" bounds="[0,300][320,348]" />'
)
raw = raw.replace("</hierarchy>", extra + "</hierarchy>")
open(sys.argv[2], "w", encoding="utf-8").write(raw)
PY
  DUMP=/tmp/run4268-with-search.xml
  sheet_search_pick state Kerala '^Kerala( +[0-9]+)?$'
  [[ "$SELECTED_LABEL" == Kerala ]] || { echo "search pick label ${SELECTED_LABEL}" >&2; exit 1; }
  echo "run4268 dry-run: sheet search taps filter-option-state-Kerala"
)
rm -f /tmp/run4268-with-search.xml
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
if [[ "$unstarted_n" -ne 61 || "$skipped_n" -ne 3 ]] ||
   ! grep -q '^SKIPPED 30d-near-me: ' "${summary_dir}/results.txt" ||
   grep -q '^FAIL ' "${summary_dir}/results.txt" ||
   ! grep -q '^SKIPPED 11-near-me: ' "${summary_dir}/results.txt" ||
   ! grep -q '^SKIPPED 23-near-me-settings-roundtrip: ' "${summary_dir}/results.txt" ||
   ! grep -q '0 failed, 0 expected failures, 0 unexpected passes, 61 not run, 3 skipped' "${summary_dir}/fail.out" ||
   ! grep -q 'did not start' "${summary_dir}/fail.out"; then
  echo "unstarted flows: 61 NOT RUN, 3 SKIPPED (11, 23, 30d), no FAIL, job not green" >&2
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

printf 'XFAIL 06b-filters-combined: force-stop-keeps-filter: filters live in memory and reset after force-stop\n' >> "${summary_dir}/results.txt"
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
if [[ "$not_run" -ne 61 ]] || [[ "$(grep -c '^SKIPPED ' "${not_run_dir}/results.txt")" -ne 3 ]]; then
  echo "expected 61 NOT RUN and 3 SKIPPED lines, found ${not_run} NOT RUN" >&2
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
printf 'NOT RUN 06b-filters-combined: combined-state: state-select did not apply a state\n' >> "${step_dir}/results.txt"
if ! EMULATOR_ARTIFACTS="$step_dir" GITHUB_STEP_SUMMARY="${step_dir}/summary.md" \
  bash tool/emulator/summarize.sh >"${step_dir}/out"; then
  echo "a skipped step should not fail the summary" >&2
  cat "${step_dir}/out" >&2
  exit 1
fi
if grep -q 'FAIL 06b-filters-combined: missing' "${step_dir}/results.txt"; then
  echo "a skipped step should count as the flow reporting" >&2
  exit 1
fi
rm -rf "$step_dir"

only_skip_dir="$(mktemp -d)"
: > "${only_skip_dir}/results.txt"
for flow in "${flows[@]}"; do
  if [[ "$flow" == "06b-filters-combined" ]]; then
    printf 'NOT RUN 06b-filters-combined: combined-state: state-select did not apply a state\n' >> "${only_skip_dir}/results.txt"
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
if ! grep -qx 'FAIL 06b-filters-combined: missing: flow did not pass any step' "${only_skip_dir}/results.txt"; then
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
  if [[ "$flow" != "06b-filters-combined" ]]; then
    printf 'DONE %s\n' "$flow" >> "${started_dir}/results.txt"
  fi
done
if EMULATOR_ARTIFACTS="$started_dir" GITHUB_STEP_SUMMARY="${started_dir}/summary.md" \
  bash tool/emulator/summarize.sh >"${started_dir}/out" 2>&1; then
  echo "summarize.sh should fail a flow that has START and no DONE" >&2
  cat "${started_dir}/out" >&2
  exit 1
fi
if ! grep -qx 'FAIL 06b-filters-combined: timeout: started but did not finish' "${started_dir}/results.txt"; then
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
  export EMULATOR_FLOW=06b-filters-combined
  export EMULATOR_ARTIFACTS="$skip_dir"
  export EMULATOR_PACKAGE=com.shradhaventures.temple
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  step_shot() { :; }
  dismiss_blockers() { return 0; }
  eval "$(sed -n '/^skip_if_failed()/,/^}/p' tool/emulator/flows/06_filters.sh)"
  : > "$RESULTS"

  skip_step combined-state "state-select did not apply a state"
  grep -q '^FAIL 06b-filters-combined: combined-state: no failed prerequisite: state-select did not apply a state$' "$RESULTS"
  if grep -q '^NOT RUN ' "$RESULTS"; then
    echo "skip_step without a failed prerequisite must not record NOT RUN" >&2
    exit 1
  fi

  : > "$RESULTS"
  skip_if_failed combined-chips "no combined filter was applied" state-select
  grep -q '^FAIL 06b-filters-combined: combined-chips: no combined filter was applied$' "$RESULTS"
  if grep -q '^NOT RUN ' "$RESULTS"; then
    echo "skip_if_failed without a prerequisite FAIL must not record NOT RUN" >&2
    exit 1
  fi

  printf 'FAIL 06b-filters-combined: state-select: could not find Kerala\n' >> "$RESULTS"
  skip_if_failed combined-state "state-select did not apply a state" state-open state-reopen state-select
  grep -q '^NOT RUN 06b-filters-combined: combined-state: state-select did not apply a state$' "$RESULTS"
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
  export EMULATOR_PACKAGE=com.shradhaventures.temple
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
  if grep -q "|${script}|" tool/emulator/plan.sh; then
    continue
  fi
  # PR 124 slice wrappers (17a/17b, 29a-29m, 30a-30d) source the shared
  # matrix/entry libs. plan.sh already runs the same cells under the
  # 17a-d / 29a1 / 30f2 / 30sN ids, so adding the wrappers as extra rows
  # would blow SHARD_WORST_MAX_S. They stay in the tree as entry points.
  if grep -Eq 'lib/filter_matrix(_b)?\.sh|lib/entry_matrix\.sh' "$script"; then
    continue
  fi
  echo "plan.sh does not run ${script}" >&2
  exit 1
done
# Round 4 (run 41373837994: 17/29/30 at the 600s cap): 17 in parts a/b,
# the filter matrix one entry x chip per flow, every cell covered once.
if [[ "$(plan_flows all | awk '$2 ~ /17_entry_matrix.sh$/ { print $3 }' | sort | paste -sd' ')" != "drawer_all drawer_search home_button list_drawer_all" ||
      "$(plan_flows all | awk '$1 == "29a1-filter-matrix-home-state" { print $3 }')" != home_browse:state:1 ||
      "$(plan_flows all | awk '$1 ~ /^30s[1-5]-filter-matrix-seq[1-5]$/ { print $3 }' | paste -sd' ')" != "seqs:1 seqs:2 seqs:3 seqs:4 seqs:5" ]]; then
  echo "flow 17 must run one entry per flow (17a-17d) and the matrix entry:chip parts" >&2
  exit 1
fi
want_cells="$(for e in home_browse drawer_all drawer_bar search; do for c in state district deity; do echo "$e:$c"; done; done | sort)"
got_cells="$(plan_flows all | awk '$2 ~ /29_filter_matrix.sh$/ && $3 ~ /:/ && $3 !~ /^(near_me|seqs):/ { print $3 }' | sed -E 's/:[12]$//' | sort -u)"
# The near-me cells are a planned-skip row (30d), never silently dropped.
if [[ "$(plan_flows all | awk '$1 == "30d-near-me" { print $3 }')" != near_me:all ]] || ! (unset EMULATOR_SKIP_FLOWS; plan_is_skipped 30d-near-me); then
  echo "30d-near-me must be a planned-skip row running near_me:all" >&2; exit 1
fi
if [[ "$want_cells" != "$got_cells" ]]; then
  echo "filter matrix parts must cover every entry x chip exactly once: ${got_cells}" >&2
  exit 1
fi
halves="$(plan_flows all | awk '$2 ~ /29_filter_matrix.sh$/ && $3 ~ /:[12]$/ && $3 !~ /^seqs:/ { print $3 }' | sort)"
want_halves="$(for e in home_browse drawer_all drawer_bar search; do for c in state district deity; do echo "$e:$c:1"; echo "$e:$c:2"; done; done | sort)"
if [[ "$halves" != "$want_halves" ]]; then
  echo "each matrix cell must be two flows (:1 select/pick-close/dismiss, :2 back/outside/clear): ${halves}" >&2
  exit 1
fi
for n in $(seq 1 "$SHARD_COUNT"); do
  active=0
  for id in $(plan_ids full "$n"); do
    plan_is_skipped "$id" || active=$((active + 1))
  done
  if (( active == 0 )); then
    echo "shard ${n} runs no flow" >&2; exit 1
  fi
  # Round 4.3.1: worst case from the actual per-row caps, boot, kill-after,
  # reset and run_shard.sh's outer --kill-after, recomputed here.
  want=$((SHARD_BOOT_S + SHARD_GETPROP_BUDGET_S + SHARD_ACTION_ADB_S + SHARD_GETPROP_S + SHARD_READY_S + SHARD_UNLOCK_S + SHARD_ANIM_S))
  for id in $(plan_ids full "$n"); do
    plan_is_skipped "$id" || want=$((want + $(plan_cap_s "$id") + FLOW_KILL_AFTER_S + FLOW_RESET_S + FLOW_OUTER_KILL_S))
  done
  if [[ "$(plan_need_s full "$n")" != "$want" ]]; then
    echo "shard ${n}: plan_need_s $(plan_need_s full "$n") != caps+boot+kill-afters ${want}" >&2; exit 1
  fi
  if (( want > SHARD_WORST_MAX_S || want > 39 * 60 )); then
    echo "shard ${n} worst case ${want}s is over 39 min (incl. boot)" >&2
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
if ! grep -qx 'PLAN 29b1-filter-matrix-home-district tool/emulator/flows/29_filter_matrix.sh home_browse:district:1' <<<"$dry" ||
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
    export EMULATOR_FLOW=06b-filters-combined EMULATOR_ARTIFACTS="$replay_dir/art" EMULATOR_PACKAGE=com.example
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
  export EMULATOR_FLOW=06b-filters-combined EMULATOR_ARTIFACTS="$replay_dir/abort" EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  eval "$(sed -n '/^COMBINED_REST=/p; /^abort_after_combined_fail() {/,/^}/p' tool/emulator/flows/06_filters.sh)"
  abort_after_combined_fail combined-deity >/dev/null
  cat "$RESULTS"
)"
if [[ "$(grep -c '^NOT RUN 06b-filters-combined: ' <<<"$abort_out")" -ne 7 ]] || grep -q '^NOT RUN 06b-filters-combined: combined-deity:' <<<"$abort_out"; then
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
   ! grep -q '^  pass_step recover$' "$f27" || ! grep -q 'pass_step chips-after-flap ||' "$f27"; then
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
mk_ready_adb "${stub_dir}/readybin" 1
tier_shards=(smoke); for n in $(seq 1 "$SHARD_COUNT"); do tier_shards+=("full $n"); done
for tier_shard in "${tier_shards[@]}"; do
  : >"${stub_dir}/ran"
  # shellcheck disable=SC2086 # split tier and shard on purpose
  STUB_LOG="${stub_dir}/ran" EMULATOR_FLOW_RUNNER="${stub_dir}/flow.sh" PATH="${stub_dir}/readybin:$PATH" \
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
  "shell pm path com.shradhaventures.temple") echo "package:/data/app/base.apk" ;;
  "shell pm clear com.shradhaventures.temple") [[ -n "${STUB_PM_FAIL:-}" ]] && echo "Failed" || echo "Success" ;;
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
  export EMULATOR_PACKAGE=com.shradhaventures.temple
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  : > "$RESULTS"
  app_installed
  reset_device_state
  clear_app_data
  for want in "shell wm size reset" "shell settings put system user_rotation 0" \
    "shell settings put secure location_mode 3" "shell pm clear com.shradhaventures.temple" \
    "shell cmd connectivity airplane-mode disable" "shell svc wifi enable" "shell svc data enable" \
    "shell pm enable com.google.android.apps.maps" "shell settings put global animator_duration_scale 0" \
    "shell pm revoke com.shradhaventures.temple android.permission.ACCESS_FINE_LOCATION" \
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
printf '#!/bin/sh\n[ "$*" = "shell getprop debug.temple.snapshot_marker" ] && echo "${STUB_MARKER:-}"\ncase "$*" in "shell service check "*) echo "Service $4: found" ;; "shell pm path android") echo package:x ;; "shell getprop sys.boot_completed") echo 1 ;; esac\nexit 0\n' > "${boot_dir}/bin/adb"
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
   ! grep -q -- '-clean-cfg6-${cpu}"' tool/emulator/avd_cache_key.sh; then
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
printf '#!/bin/sh\ncase "$*" in "emu avd snapshot save default_boot") echo "${STUB_SAVE:-KO: failed}";; "shell service check "*) echo "Service $4: found" ;; "shell pm path android") echo package:x ;; "shell getprop sys.boot_completed") echo 1 ;; esac\nexit 0\n' > "${sc_dir}/bin/adb"
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
crash_in() { rs eval "app_crashed_in_log com.shradhaventures.temple" <<< "$1"; }
if ! crash_in "11-01 14:17:00.000 300 300 E AndroidRuntime: Process: com.shradhaventures.temple, PID: 300" ||
   ! crash_in "11-01 14:17:00.000 1 1 E ActivityManager: ANR in com.shradhaventures.temple (com.shradhaventures.temple/.MainActivity)" ||
   ! crash_in "11-01 14:17:00.000 1 1 W ActivityTaskManager: Force finishing activity com.shradhaventures.temple/.MainActivity" ||
   crash_in "11-01 14:17:00.000 1 1 E AndroidRuntime: Process: com.google.android.apps.maps, PID: 9" ||
   crash_in "11-01 14:17:00.000 1 1 I ActivityTaskManager: Displayed com.shradhaventures.temple/.MainActivity"; then
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
if [[ "$rc" != 1 || "$g" != *"4 NOT RUN (no result: 30g1-filter-matrix-search-deity 30g2-filter-matrix-search-deity 30s2-filter-matrix-seq2 19-rotation-state)"* ||
      "$g" != *"missing shard artifacts: 11 (need 15)"* ]]; then
  echo "strict gate must refuse a run with shard 11 missing (4 silent NOT RUN + missing artifact): rc=${rc} ${g}" >&2; exit 1
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
  bash tool/emulator/release_gate.sh full "$gate_sha" build >/dev/null 2>&1 || { echo "gate: clean 15-shard run must pass" >&2; exit 1; }
rm -f "${ms}/shards/emulator-app-test-7/results.txt"
if EMULATOR_GATE_MODE=strict EMULATOR_SHARD_RESULTS="${ms}/shards" EMULATOR_ARTIFACTS="$ms" GITHUB_STEP_SUMMARY=/dev/null \
  bash tool/emulator/release_gate.sh full "$gate_sha" build >/dev/null 2>&1; then echo "gate: missing shard 7 artifact must refuse" >&2; exit 1; fi
# Round 4.4.3: shard 15 is required too (a 14-artifact run is refused).
rm -rf "${ms}/shards"; gate_clean_results "$ms" 15
rc=0; g="$(EMULATOR_GATE_MODE=strict EMULATOR_SHARD_RESULTS="${ms}/shards" EMULATOR_ARTIFACTS="$ms" GITHUB_STEP_SUMMARY=/dev/null \
  bash tool/emulator/release_gate.sh full "$gate_sha" build 2>&1)" || rc=$?
[[ "$rc" == 1 && "$g" == *"missing shard artifacts: 15 (need 15)"* ]] || { echo "gate: a run with 14 artifacts (no shard 15) must refuse: rc=${rc} ${g}" >&2; exit 1; }
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
    ui_dump() { cp "${R24_DUMP_PATH:-${fx4}/${R24_DUMP}}" "$DUMP"; }
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
# Round 4.4.9e (run 41781519101 shard 9): the timer had advanced to '2 / 5'
# before the dump (real dump); still a multi-photo gallery.
o="$(R24_DUMP_PATH=tool/emulator/testdata/run41781519101/detail_multi_2of5.xml run24 multi2 2>/dev/null)"
grep -qx 'PASS 24-gallery-autoadvance-viewer: multi-photo' <<<"$o" || { echo "flow 24: '2 / 5' (auto-advanced) -> PASS: $o" >&2; exit 1; }
# Round 4.4.9f (Reviewer): k must be 1..N; '6 / 5' and '7 / 5' are not proof.
for bad in 6 7; do
  sed "s|\"2 / 5\"|\"${bad} / 5\"|" tool/emulator/testdata/run41781519101/detail_multi_2of5.xml > "$r4/f24_${bad}of5.xml"
  grep -q "\"${bad} / 5\"" "$r4/f24_${bad}of5.xml" || { echo "flow 24: could not build the '${bad} / 5' dump" >&2; exit 1; }
  o="$(R24_DUMP_PATH="$r4/f24_${bad}of5.xml" run24 "bad${bad}" 2>/dev/null)"
  if ! grep -q '^FAIL 24-gallery-autoadvance-viewer: multi-photo: detail page shows no readable photo counter' <<<"$o" ||
     grep -q '^PASS 24-gallery-autoadvance-viewer: multi-photo' <<<"$o"; then
    echo "flow 24: '${bad} / 5' must FAIL multi-photo: $o" >&2; exit 1
  fi
done
o="$(R24_DUMP=detail_single_1of1.xml run24 single2 2>/dev/null)"
grep -q "^NA 24-gallery-autoadvance-viewer: multi-photo: 'Aazhimala' has a single photo" <<<"$o" || { echo "flow 24: '1 / 1' stays NA: $o" >&2; exit 1; }
echo "4.4.9f flow 24: '2 / 5' PASS, '6 / 5' and '7 / 5' FAIL, '1 / 1' NA"
# Round 4.4.9g (run 41825986479 shard 13): Get Directions came into view
# with the 3rd fling; the loop must look once more after its last fling.
# Real dumps: 3 looks without the button, the 4th with it.
# #138: KAN-197 dress-code raised the cold-open seek; budget is 8 flings /
# 9 looks (still finds the 3rd-fling case; never-in-view exhausts at 8).
f25=tool/emulator/flows/25_directions_edge.sh
fx25=tool/emulator/testdata/run41825986479
# shellcheck disable=SC2016,SC2034,SC2154,SC2178,SC2329 # stubs and eval of the flow block
o25="$( ( export EMULATOR_FLOW=25-directions-edge EMULATOR_ARTIFACTS="$r4/f25" EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  n25=0
  ui_dump() { n25=$((n25 + 1)); if (( n25 <= 3 )); then cp "$fx25/detail_no_directions.xml" "$DUMP"; else cp "$fx25/detail_directions_in_view.xml" "$DUMP"; fi; }
  flings=0; ui_fling() { flings=$((flings + 1)); }
  eval "$(sed -n '/^directions_found=0$/,/^done$/p' "$f25")"
  echo "found=$directions_found flings=$flings looks=$n25" ) 2>/dev/null )"
[[ "$o25" == "found=1 flings=3 looks=4" ]] || { echo "4.4.9g flow 25: button after the 3rd fling must be found (3 flings, 4 looks): $o25" >&2; exit 1; }
# shellcheck disable=SC2016,SC2034,SC2154,SC2178,SC2329 # stubs and eval of the flow block
o25="$( ( export EMULATOR_FLOW=25-directions-edge EMULATOR_ARTIFACTS="$r4/f25b" EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  n25=0; ui_dump() { n25=$((n25 + 1)); cp "$fx25/detail_no_directions.xml" "$DUMP"; }
  flings=0; ui_fling() { flings=$((flings + 1)); }
  eval "$(sed -n '/^directions_found=0$/,/^done$/p' "$f25")"
  echo "found=$directions_found flings=$flings looks=$n25" ) 2>/dev/null )"
[[ "$o25" == "found=0 flings=8 looks=9" ]] || { echo "4.4.9g flow 25: never in view -> not found after 8 flings, no 9th fling: $o25" >&2; exit 1; }
# shellcheck disable=SC2016,SC2034,SC2154,SC2178,SC2329 # stubs and eval of the flow block
o25="$( ( export EMULATOR_FLOW=25-directions-edge EMULATOR_ARTIFACTS="$r4/f25c" EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  n25=0
  ui_dump() { n25=$((n25 + 1)); if (( n25 <= 7 )); then cp "$fx25/detail_no_directions.xml" "$DUMP"; else cp "$fx25/detail_directions_in_view.xml" "$DUMP"; fi; }
  flings=0; ui_fling() { flings=$((flings + 1)); }
  eval "$(sed -n '/^directions_found=0$/,/^done$/p' "$f25")"
  echo "found=$directions_found flings=$flings looks=$n25" ) 2>/dev/null )"
[[ "$o25" == "found=1 flings=7 looks=8" ]] || { echo "4.4.9g flow 25: button on the 7th fling must be found within the 8-fling budget: $o25" >&2; exit 1; }
echo "4.4.9g flow 25: a look after the last fling finds Get Directions (real 41825986479 dumps; 8-fling budget)"
# Round 4.4.9g (run 41825986479 shard 9): each sequence action gets its own
# step budget (the 150s clock ran across install + Home + 3 actions).
f29=tool/emulator/flows/29_filter_matrix.sh
# shellcheck disable=SC2016,SC2034,SC2154,SC2178,SC2329 # stubs and eval of the flow block
o29="$( ( export EMULATOR_FLOW=30s5-filter-matrix-seq5 EMULATOR_ARTIFACTS="$r4/f29seq" EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  STEP_BUDGET_S=2
  do_action() { sleep 1.2; step_budget_ok; }
  recover_sheet() { :; }
  seq="deity:select district:select state:outside-empty district:clear"; n=5; ok=1
  eval "$(sed -n '/^  for st in \$seq; do$/,/^  done$/p' "$f29")"
  echo "ok=$ok" ) 2>/dev/null )"
[[ "$o29" == "ok=1" ]] || { echo "4.4.9g flow 29: each sequence action must get its own step budget: $o29" >&2; exit 1; }
echo "4.4.9g flow 29: sequence actions each get a fresh step budget"
# Round 4.4.9h (run 41872598981 30s5): the deity chip had scrolled off the
# chip row, so scoped_pick sent district:clear back to 24 Paraganas North
# (not offered under the applied deity). What the flow applied counts first.
o9h="$(bash tool/emulator/testdata/run41872598981/replay_seq5.sh "$PWD" 2>/dev/null)"
if ! grep -qx "STEP district:select chip-bar=browse_deity_applied.xml pick=@first -> 'Jabalpur'" <<<"$o9h" ||
   ! grep -qx "STEP district:clear chip-bar=browse_deity_chip_offscreen.xml pick=@first -> 'Jabalpur'" <<<"$o9h"; then
  echo "4.4.9h: seq5 replay must pick the first shown district for select and clear: $o9h" >&2; exit 1
fi
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # stubs
o9h="$( ( export EMULATOR_FLOW=99-sp9h EMULATOR_ARTIFACTS="$r4/sp9h" EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  ui_dump() { cp tool/emulator/testdata/run41872598981/browse_deity_chip_offscreen.xml "$DUMP"; }
  declare -A APPLIED=([district]=Jabalpur)
  printf '%s|' "$(scoped_pick state)"
  APPLIED=(); printf '%s|' "$(scoped_pick deity)"
  APPLIED=([state]='Tamil Nadu'); printf '%s|' "$(scoped_pick district)" ) 2>/dev/null )"
[[ "$o9h" == '@first|@first|^Madurai( +[0-9]+)?$|' ]] ||
  { echo "4.4.9h scoped_pick: state under an applied district -> @first; Tamil Nadu from APPLIED: $o9h" >&2; exit 1; }
# Round 4.4.9i (Reviewer): a non-Tamil Nadu state applied, no deity ->
# district @first (24 Paraganas North may be hidden); nothing applied -> head pick.
# shellcheck disable=SC2034,SC2329 # stubs
o9i="$( ( export EMULATOR_FLOW=99-sp9i EMULATOR_ARTIFACTS="$r4/sp9i" EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  ui_dump() { printf '<hierarchy><node text="" resource-id="filter-chip-state" content-desc="State" bounds="[14,184][114,219]" /><node text="" resource-id="filter-chip-deity" content-desc="Deity" bounds="[230,184][300,219]" /></hierarchy>' > "$DUMP"; }
  declare -A APPLIED=([state]='Madhya Pradesh'); printf '%s|' "$(scoped_pick district)"
  APPLIED=(); printf '%s|' "$(scoped_pick district)" ) 2>/dev/null )"
[[ "$o9i" == '@first|^24 Paraganas North( +[0-9]+)?$|' ]] ||
  { echo "4.4.9i scoped_pick: non-TN state applied -> district @first; nothing applied -> head pick: $o9i" >&2; exit 1; }
echo "4.4.9i: district pick is @first under any applied state or deity"
# Round 4.4.9i (Manu): two matrix cells; cell 1 applies a deity, cell 2
# (district) must get the all-India head pick again after the per-cell
# APPLIED reset in flow 29 (fails if that reset line is removed).
f29=tool/emulator/flows/29_filter_matrix.sh
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # stubs and eval of the flow blocks
o9c="$( ( set +eu; export EMULATOR_FLOW=29a-two-cells EMULATOR_ARTIFACTS="$r4/sp9c" EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  ui_dump() { printf '<hierarchy><node text="" resource-id="filter-chip-state" content-desc="State" bounds="[14,184][114,219]" /><node text="" resource-id="filter-chip-deity" content-desc="Deity" bounds="[230,184][300,219]" /></hierarchy>' > "$DUMP"; }
  declare -A APPLIED=() PICK=() SECTION=()
  enter_home_browse() { :; }; open_chip() { :; }; apply_sheet() { :; }; probe_others() { :; }
  select_labeled() { echo "PICK $1" >&2; SELECTED_LABEL=X; }
  eval "$(sed -n '/^do_action() {$/,/^}$/p' "$f29")"
  ENTRIES=(home_browse); MATRIX_CHIPS=(deity district); ACTIONS=(select)
  eval "$(sed -n '/^for entry in "\${ENTRIES\[@\]}"; do$/,/^done$/p' "$f29")"; true ) 2>&1 >/dev/null | { grep '^PICK ' || true; } | paste -sd'|' )"
[[ "$o9c" == 'PICK @first|PICK ^24 Paraganas North( +[0-9]+)?$' ]] ||
  { echo "4.4.9i flow 29: cell 2 must not see cell 1's deity (per-cell APPLIED reset): $o9c" >&2; exit 1; }
echo "4.4.9i flow 29: each matrix cell starts with APPLIED empty"
echo "4.4.9h: seq5 replay resolves every step; picks use what the flow applied, not only the visible chips"
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
  # Frozen picker clock. A wall-clock tick between the deadline and this
  # stub used to print left=29 instead of left=30.
  EMULATOR_NOW_S=1000
  wait_out_district_loader() { :; }
  ui_dump() { return 0; }
  # sheet_search_pick and ui_find used to run here, between the deadline
  # and seek_option, and a wall-clock tick made left=29 (runs
  # 42717632241 and 42718876928).
  sheet_search_pick() { return 1; }
  ui_find() { return 1; }
  n=0
  seek_option() {
    if [[ -n "${EMULATOR_SEEK_STUB_DELAY:-}" ]]; then command sleep "$EMULATOR_SEEK_STUB_DELAY"; fi
    n=$((n + 1))
    echo "SEEK $n fling=${SEEK_FLING_MS:-120} left=$(( $3 - $(emulator_now) ))" >&2
    if (( n == 1 )); then return 1; fi; UI_CX=1 UI_CY=2 UI_TEXT="Madurai  4"; return 0;
  }
  ui_tap() { :; }
  # Two-dump confirmation is tested on its own (round 4.3); here only the budget.
  stable_option_tap() { SELECTED_LABEL="$(chip_label "$UI_TEXT")"; }
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
# 4. Pickers on the sheet simulator (testdata/sim, SEEK_TRACE=1): the state
# picker has the long budget and reaches Tamil Nadu; a slow-drag look costs
# 2 dumps (the post-drag dump is settle dump 1), not 3; Shiva from a
# Tamil Nadu-scoped list fits; scoped_pick never sends Shiva to an
# all-India list.
sim="tool/emulator/testdata/sim/seek_dryrun.sh"
o="$(bash "$sim" STATE '^Tamil Nadu( +[0-9]+)?$' state,district,deity all "$r43/simst")"
grep -q "^RESULT rc=0 .* label='Tamil Nadu'" <<<"$o" || { echo "sim: state Tamil Nadu within the long budget: $o" >&2; exit 1; }
# After each slow drag (900ms swipe from seek_option) count the dumps before the next swipe.
per_look="$(awk '/^SWIPE .* 900 seek_option/ { if (n) print c; n = 1; c = 0; next } /^SWIPE/ { if (n) print c; n = 0 } /^DUMP/ && n && $2 !~ /^stable_option_tap/ { c++ } END { if (n) print c }' "$r43/simst/calls.log" | sort -n | tail -1)"
[[ "$per_look" -le 2 ]] || { echo "sim: a slow-drag look must cost <= 2 dumps (post-drag dump reused), got ${per_look}" >&2; cat "$r43/simst/calls.log" >&2; exit 1; }
o="$(bash "$sim" DEITY '^Shiva( +[0-9]+)?$' deity,state,district tn "$r43/simsh")"
grep -q "^RESULT rc=0 .* label='Shiva'" <<<"$o" || { echo "sim: Tamil Nadu-scoped Shiva: $o" >&2; exit 1; }
o="$(bash "$sim" DEITY '^Ahalya( +[0-9]+)?$' deity,state,district all "$r43/simah")"
grep -q "^RESULT rc=0 .* label='Ahalya'" <<<"$o" || { echo "sim: all-India head pick Ahalya: $o" >&2; exit 1; }
sp() { ( export EMULATOR_FLOW=99-sp EMULATOR_ARTIFACTS="$r43/sp" EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  ui_dump() { printf '<hierarchy><node text="" resource-id="filter-chip-state" content-desc="%s" bounds="[0,100][120,140]" /></hierarchy>' "$SP_STATE" > "$DUMP"; }
  scoped_pick "$1" ); }
[[ "$(CHOOSE_STATE_APPLIED='Tamil Nadu' SP_STATE='State' sp deity)" == '^Shiva( +[0-9]+)?$' && "$(CHOOSE_STATE_APPLIED='Tamil Nadu' SP_STATE='State' sp district)" == '^Madurai( +[0-9]+)?$' ]] || { echo "scoped_pick: Tamil Nadu recorded by choose-a-state-first scopes deity and district" >&2; exit 1; }
python3 - <<'PY'
import importlib.util
spec = importlib.util.spec_from_file_location("ui", "tool/emulator/lib/ui.py")
ui = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ui)
regions = ui._state_regions()
alias = ui._state_sort_key("Andaman and Nicobar Islands", regions)
canonical = ui._state_sort_key("Andaman & Nicobar Islands", regions)
assert alias[0] == canonical[0] == 1, (alias, canonical)
assert ui._state_sort_key("Atlantis", regions)[0] == 6
PY
[[ "$(SP_STATE='Tamil Nadu' sp deity)" == '^Shiva( +[0-9]+)?$' && "$(SP_STATE='State' sp deity)" == '@first' &&
   "$(SP_STATE='Tamil Nadu' sp district)" == '^Madurai( +[0-9]+)?$' && "$(SP_STATE='Kerala' sp district)" == '^24 Paraganas North( +[0-9]+)?$' &&
   "$(SP_STATE='State' sp state)" == '^Tamil Nadu( +[0-9]+)?$' ]] || { echo "scoped_pick: Shiva/Madurai only when Tamil Nadu is the state" >&2; exit 1; }
# Round 4.4.9e (run 41781519101 30s5): with a deity on the chip bar the
# district list is faceted, so the district pick is @first (real dump);
# no deity -> the all-India head district. A deity wins over Tamil Nadu:
# Shiva in Tamil Nadu does not list Madurai (run 42699042193, 30s5).
spd() { ( export EMULATOR_FLOW=99-spd EMULATOR_ARTIFACTS="$r43/spd" EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  ui_dump() { if [[ -n "${SPD_FILE:-}" ]]; then cp "$SPD_FILE" "$DUMP"; else printf '<hierarchy><node text="" resource-id="filter-chip-state" content-desc="%s" bounds="[0,100][120,140]" /><node text="" resource-id="filter-chip-deity" content-desc="%s" bounds="[130,100][200,140]" /></hierarchy>' "$SP_STATE" "$SP_DEITY" > "$DUMP"; fi; }
  scoped_pick "$1" ); }
[[ "$(SPD_FILE=tool/emulator/testdata/run41781519101/browse_deity_applied.xml spd district)" == '@first' &&
   "$(SP_STATE='State' SP_DEITY='Deity' spd district)" == '^24 Paraganas North( +[0-9]+)?$' &&
   "$(SP_STATE='State' SP_DEITY='Shiva' spd district)" == '@first' &&
   "$(SP_STATE='Tamil Nadu' SP_DEITY='Shiva' spd district)" == '@first' &&
   "$(SP_STATE='State' SP_DEITY='Shiva' spd deity)" == '@first' ]] || { echo "4.4.9e scoped_pick: district must be @first when a deity is applied" >&2; exit 1; }
echo "4.4.9e: district pick is @first under an applied deity (real 41781519101 dump)"
if grep -n 'select_labeled "\${PICK\[' tool/emulator/flows/29_filter_matrix.sh tool/emulator/flows/17_entry_matrix.sh; then
  echo "flows 17/29 must pick through scoped_pick, not PICK[] directly" >&2; exit 1
fi
grep -q 'kind" =~ ^(state|district|deity)\$ ]] && (( PICKER_LONG_GIVEUP_S' tool/emulator/lib/common.sh || { echo "state picker gets PICKER_LONG_GIVEUP_S" >&2; exit 1; }
# 5. Flow 06 (run 41391038302 dumps): the DISTRICT scan never taps a STATE
# row; chip lookups match only filter-chip-* nodes (not the app bar title);
# the state chip check catches "Bihar"; a row that moved between two dumps
# is not tapped; 06 is split 06a/06b and picks a real district.
T41=tool/emulator/testdata/run41391038302
r5lib() { ( export EMULATOR_FLOW=06b-filters-combined EMULATOR_ARTIFACTS="$r43/r5" EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  sleep() { :; }; step_shot() { :; }; adb_shell_capped() { :; }
  ui_screen_size() { echo "${R5_SIZE:-320 640}"; }
  ui_dump() { cp "$R5_FX" "$DUMP"; }
  ui_tap() { echo "TAP ${UI_TEXT}"; }
  PICKER_GIVEUP_S=3; PICKER_LONG_GIVEUP_S=3
  "$@" ); }
o="$(R5_FX="$T41/sheet_district_then_state.xml" r5lib select_labeled '^(?!All districts).+[0-9]+$' DISTRICT 2>&1)" && { echo "flow 06: DISTRICT scan must not tap a STATE row: $o" >&2; exit 1; }
grep -q '^TAP' <<<"$o" && { echo "flow 06: no tap outside DISTRICT: $o" >&2; exit 1; }
o="$(R5_FX="$T41/sheet_district_then_state.xml" r5lib select_labeled '^Bihar( +[0-9]+)?$' STATE 2>&1)" || { echo "STATE scan still taps Bihar in STATE: $o" >&2; exit 1; }
grep -q '^TAP Bihar 14' <<<"$o" || { echo "STATE scan tap: $o" >&2; exit 1; }
if R5_SIZE="640 320" R5_FX="$T41/title_kerala_chip_bihar.xml" r5lib bash -c 'CHIP_LABEL_RX="^Kerala$" find_filter_chip "" "^Kerala$"' >/dev/null 2>&1; then
  echo "find_filter_chip: the app bar title 'Kerala' is not a chip" >&2; exit 1
fi
R5_SIZE="640 320" R5_FX="$T41/title_kerala_chip_bihar.xml" r5lib find_filter_chip filter-chip-state "" "" >/dev/null 2>&1 || { echo "find_filter_chip by id still works" >&2; exit 1; }
if R5_FX="$T41/combined_chips_state_bihar.xml" r5lib state_chip_is Kerala >/dev/null 2>&1; then echo "state_chip_is: Bihar is not Kerala" >&2; exit 1; fi
R5_FX="$T41/combined_chips_state_bihar.xml" r5lib state_chip_is Bihar >/dev/null 2>&1 || { echo "state_chip_is Bihar" >&2; exit 1; }
sed 's/\[16,471\]\[200,511\]/[16,431][200,471]/' "$T41/sheet_district_then_state.xml" > "$r43/moved.xml"
o="$( ( export EMULATOR_FLOW=x EMULATOR_ARTIFACTS="$r43/r5m"
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh; sleep() { :; }; n=0
  ui_dump() { n=$((n + 1)); if (( n == 1 )); then cp "$T41/sheet_district_then_state.xml" "$DUMP"; else cp "$r43/moved.xml" "$DUMP"; fi; }
  ui_tap() { echo TAPPED; }
  ui_dump; ui_find --resource-id filter-option-state-Bihar; stable_option_tap '^Bihar( +[0-9]+)?$' '^filter-option-state-' ) 2>&1)" && { echo "stable_option_tap: moved row must not be tapped: $o" >&2; exit 1; }
grep -q TAPPED <<<"$o" && { echo "stable_option_tap tapped a moving row" >&2; exit 1; }
grep -q '"06a1-filters-single|tool/emulator/flows/06_filters.sh|single:1|12|400"' tool/emulator/plan.sh &&
  grep -q '"06a2-filters-single|tool/emulator/flows/06_filters.sh|single:2|12|400"' tool/emulator/plan.sh &&
  grep -q '"06b-filters-combined|tool/emulator/flows/06_filters.sh|combined|12"' tool/emulator/plan.sh &&
  ! grep -q '"06-filters|' tool/emulator/plan.sh || { echo "plan.sh: 06 split into 06a single / 06b combined" >&2; exit 1; }
f06=tool/emulator/flows/06_filters.sh
grep -q "select_labeled '^(?!All districts)" "$f06" && { echo "flow 06: no name-less lookahead district pick" >&2; exit 1; }
grep -q 'COMBINED_DISTRICT_PICK:-^Alappuzha' "$f06" && grep -q 'state_chip_is "$COMBINED_STATE"' "$f06" || { echo "flow 06: real district (Alappuzha) and the state-chip check" >&2; exit 1; }
grep -q ': "${_section}"' tool/emulator/lib/common.sh && { echo "select_labeled must use its section" >&2; exit 1; }
[[ "$(bash -c 'source tool/emulator/plan.sh; plan_cap_s 26-drawer-nav-stack; plan_cap_s 06b-filters-combined; plan_cap_s 06a1-filters-single; plan_need_s full 12')" == $'300\n600\n400\n2089' ]] || { echo "plan: 26=300, 06b=600, 06a1=400, shard 12 = 2089s" >&2; exit 1; }
# 6-8. Replays of run 41391038302 (testdata/run41391038302/replay_*.sh):
# 27 waits for validation, re-taps Try again, flaps only after recover; 17c
# clears "temple" before typing; 24 sends one fling and compares.
o="$(bash "$T41/replay_27.sh" tool/emulator/flows/27_offline_cold_start.sh)"
grep -q '^PASS 27-offline-cold-start: recover$' <<<"$o" && grep -q '^PASS 27-offline-cold-start: chips-after-flap$' <<<"$o" ||
  { echo "flow 27: recover within 60s of validation, then flaps: $o" >&2; exit 1; }
o="$(LOAD_S=200 bash "$T41/replay_27.sh" tool/emulator/flows/27_offline_cold_start.sh)"
grep -q '^FAIL 27-offline-cold-start: recover: did not recover within 60s' <<<"$o" && grep -q '^NOT RUN 27-offline-cold-start: chips-after-flap' <<<"$o" &&
  ! grep -q 'network on' <<<"$(sed -n '/^--- events/,$p' <<<"$o" | sed 1,2d)" ||
  { echo "flow 27: no flap after a failed recover; Try again re-tapped every 15s: $o" >&2; exit 1; }
[[ "$(grep -c 'tapped Try again' <<<"$o")" -ge 4 ]] || { echo "flow 27: Try again re-tapped every 15s in 60s: $o" >&2; exit 1; }
grep -q 'wait_network_validated 60' tool/emulator/flows/27_offline_cold_start.sh || { echo "flow 27 waits for VALIDATED" >&2; exit 1; }
o="$(bash "$T41/replay_17c.sh" tool/emulator/flows/17_entry_matrix.sh)"
grep -q "typed 'zzzqqq' -> field 'zzzqqq'" <<<"$o" && grep -q '^PASS 17c-entry-matrix-drawer-search: drawer_search-empty-clear$' <<<"$o" ||
  { echo "flow 17c: clear 'temple' before typing zzzqqq: $o" >&2; exit 1; }
# Round 4.3.1: flow 24 must prove the swipe with a fling BACK (the timer
# only moves forward). Auto-advance alone (NOSWIPE=1: flings do nothing)
# must FAIL at every start page and phase, including the window where the
# timer moves the page forward between the two dumps (phase 2, which the
# round-4.3 one-fling check passed); a page that does not move ("1 -> 1",
# run 41391038302) must FAIL; a working swipe must PASS everywhere.
f24=tool/emulator/flows/24_gallery_autoadvance_viewer.sh
o="$(NOSWIPE=1 bash "$T41/replay_24.sh" "$f24" 1 2 2>&1)"
grep -q 'auto-advance -> page 2' <<<"$o" && grep -q '^FAIL 24-gallery-autoadvance-viewer: swipe-pages: fling back did not move the page back (1 -> 2 ' <<<"$o" ||
  { echo "flow 24: auto-advance alone (forward change between dumps) must FAIL: $o" >&2; exit 1; }
o="$(NOSWIPE=1 NOAUTO=1 bash "$T41/replay_24.sh" "$f24" 1 1 2>&1)"
grep -q '^FAIL 24-gallery-autoadvance-viewer: swipe-pages: one fling did not change the page (1 -> 1)$' <<<"$o" ||
  { echo "flow 24: an unchanged page (the old 1 -> 1 case) must FAIL: $o" >&2; exit 1; }
for st in 0 1 2 3 4; do
  for ph in 0 1.5 3.5; do
    o="$(bash "$T41/replay_24.sh" "$f24" "$st" "$ph" 2>&1)"
    grep -q '^PASS 24-gallery-autoadvance-viewer: swipe-pages$' <<<"$o" || { echo "flow 24: working swipe start=$st phase=$ph must PASS: $o" >&2; exit 1; }
    o="$(NOSWIPE=1 bash "$T41/replay_24.sh" "$f24" "$st" "$ph" 2>&1)"
    grep -q '^FAIL 24-gallery-autoadvance-viewer: swipe-pages' <<<"$o" || { echo "flow 24: auto-advance only start=$st phase=$ph must FAIL: $o" >&2; exit 1; }
  done
done
# Round 4.3.3: the gallery counter is in content-desc on real dumps
# (text=""); gallery_count reads both attributes, and gallery_page reads the
# detail-gallery-N id either way.
gc() { ( EMULATOR_ARTIFACTS="$(mktemp -d)"; export EMULATOR_ARTIFACTS EMULATOR_FLOW=gc EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh; DUMP="$1"; "$2" ); }
for fx in "tool/emulator/testdata/run41373837994/detail_multi_1of5.xml:5:0" "tool/emulator/testdata/run41314245431/gallery_burst_5of5.xml:5:4"; do
  IFS=: read -r fxf fxn fxp <<<"$fx"
  [[ "$(gc "$fxf" gallery_count)" == "$fxn" && "$(gc "$fxf" gallery_page)" == "$fxp" ]] ||
    { echo "gallery_count/gallery_page on $fxf: $(gc "$fxf" gallery_count)/$(gc "$fxf" gallery_page), want $fxn/$fxp" >&2; exit 1; }
done
printf '<hierarchy><node text="2 / 3" resource-id="" content-desc="" /></hierarchy>' > "$r43/counter_text.xml"
[[ "$(gc "$r43/counter_text.xml" gallery_count)" == 3 ]] || { echo "gallery_count reads a text= counter too" >&2; exit 1; }
grep -q '^gallery_count()' tool/emulator/flows/24_gallery_autoadvance_viewer.sh && { echo "flow 24 must use common.sh gallery_count" >&2; exit 1; }
# Replays default to content-desc counters; the text= form still passes.
for st in 0 4; do
  o="$(COUNTER_ATTR=text bash "$T41/replay_24.sh" "$f24" "$st" 1 2>&1)"
  grep -q '^PASS 24-gallery-autoadvance-viewer: swipe-pages$' <<<"$o" || { echo "flow 24: text= counter start=$st must PASS: $o" >&2; exit 1; }
done
# Last-page step-back runs on content-desc counters (5 pages, start on 4).
o="$(bash "$T41/replay_24.sh" "$f24" 4 0 2>&1)"
[[ "$(sed -n '/dump: page 4/,/fling left/p' <<<"$o" | grep -c 'fling right')" -ge 2 ]] && grep -q '^PASS 24-gallery-autoadvance-viewer: swipe-pages$' <<<"$o" ||
  { echo "flow 24: last page steps back before the forward fling: $o" >&2; exit 1; }
# A fling+dump window over 5s (slow dumps) is not trusted: NA (weak).
o="$(DUMP_S=4.5 bash "$T41/replay_24.sh" "$f24" 1 1 2>&1)"
grep -q '^NA 24-gallery-autoadvance-viewer: swipe-pages: weak: fling+dump window(s) 6.5s over the 5s timer period' <<<"$o" || { echo "flow 24: slow window must be NA (weak): $o" >&2; exit 1; }
o="$(DUMP_S=4.5 NOSWIPE=1 bash "$T41/replay_24.sh" "$f24" 1 1 2>&1)"
! grep -q '^PASS 24-gallery-autoadvance-viewer: swipe-pages' <<<"$o" || { echo "flow 24: slow window auto-only never PASSes: $o" >&2; exit 1; }
# Snapshot boot with a config mismatch prints ::warning::.
grep -q 'snapshot boot, but the AVD config differs from the snapshot' tool/emulator/run_shard.sh || { echo "run_shard warns on mismatch + snapshot boot" >&2; exit 1; }
# Round 4.3.2: small galleries. 3 pages: from page 1 a back window must
# show 0 (the timer needs 1 -> 2 -> 0); 4 pages: start in [2, 2]. Both pass
# with a real swipe and fail on auto-advance only. 2 pages: always NA (a
# swipe and the wrap give the same pages), never PASS.
for np in 3 4; do
  for st in 0 $((np - 1)); do
    for ph in 0 2.5; do
      o="$(NPAGES=$np bash "$T41/replay_24.sh" "$f24" "$st" "$ph" 2>&1)"
      grep -q '^PASS 24-gallery-autoadvance-viewer: swipe-pages$' <<<"$o" || { echo "flow 24: ${np}-page swipe start=$st phase=$ph must PASS: $o" >&2; exit 1; }
      o="$(NPAGES=$np NOSWIPE=1 bash "$T41/replay_24.sh" "$f24" "$st" "$ph" 2>&1)"
      grep -q '^FAIL 24-gallery-autoadvance-viewer: swipe-pages' <<<"$o" || { echo "flow 24: ${np}-page auto-advance only start=$st phase=$ph must FAIL: $o" >&2; exit 1; }
    done
  done
done
o="$(NPAGES=2 bash "$T41/replay_24.sh" "$f24" 0 1 2>&1)"
grep -q '^NA 24-gallery-autoadvance-viewer: swipe-pages: 2-page gallery' <<<"$o" || { echo "flow 24: 2-page gallery is NA: $o" >&2; exit 1; }
o="$(NPAGES=2 NOSWIPE=1 bash "$T41/replay_24.sh" "$f24" 0 1 2>&1)"
! grep -q '^PASS 24-gallery-autoadvance-viewer: swipe-pages' <<<"$o" || { echo "flow 24: 2-page auto-advance only never PASSes: $o" >&2; exit 1; }
for ph in 0 1.5 2 4.5; do
  o="$(NPAGES=2 bash "$T41/replay_24.sh" "$f24" 1 "$ph" 2>&1)"
  grep -q '^NA 24-gallery-autoadvance-viewer: swipe-pages: 2-page gallery' <<<"$o" || { echo "flow 24: 2-page gallery phase=$ph is NA, never FAIL/PASS: $o" >&2; exit 1; }
done
# Round 4.3.2: initPath is written only by the boot that creates
# userdata-qemu.img, so its absence is info, not a mismatch; the 2g-vs-6g
# size mismatch still is. run_shard fails fast only on mismatch + cold boot.
mkdir -p "$r43/avd431"; cp "$av/run-booted/config.ini" "$r43/avd431/"
sed '/disk.dataPartition.initPath/d' "$av/create-booted/hardware-qemu.ini" > "$r43/avd431/hardware-qemu.ini"
o="$(EMULATOR_SNAPSHOT_HW="$av/create-booted/snapshot-hardware.ini" bash tool/emulator/check_snapshot_config.sh post "$r43/avd431" 2>&1)" || { echo "snapcfg post: missing initPath alone is not a mismatch: $o" >&2; exit 1; }
[[ "$o" == *"SNAPSHOT_CONFIG info: disk.dataPartition.initPath snapshot=/home/runner/.android/avd/emulator-app-test-30.avd/userdata.img boot=<unset>"* && "$o" == *"SNAPSHOT_CONFIG ok (post)"* ]] || { echo "snapcfg post logs initPath as info: $o" >&2; exit 1; }
o="$(EMULATOR_SNAPSHOT_HW="$av/run-booted/snapshot-hardware.ini" bash tool/emulator/check_snapshot_config.sh post "$av/run-booted" 2>/dev/null)" && { echo "snapcfg post: run 41391038302 shard 3 boot (2g vs 6g) must mismatch" >&2; exit 1; }
[[ "$o" == *"disk.dataPartition.size snapshot=6442450944 boot=2147483648"* && "$o" != *initPath* ]] || { echo "snapcfg post: size is the fatal key, initPath is not: $o" >&2; exit 1; }
EMULATOR_SNAPSHOT_HW="$av/create-booted/snapshot-hardware.ini" bash tool/emulator/check_snapshot_config.sh post "$av/create-booted" >/dev/null 2>&1 || { echo "snapcfg post: matching create boot passes" >&2; exit 1; }
# run_shard with a stub adb: marker 1 = snapshot boot, empty = cold.
mkdir -p "$r43/bin431s" "$r43/bin431c"
mk_ready_adb "$r43/bin431s" 1; mk_ready_adb "$r43/bin431c" ""
stub_runner="$r43/runner431.sh"; printf '#!/bin/sh\necho "PASS $1: stub" >> "$EMULATOR_ARTIFACTS/results.txt"\n' > "$stub_runner"; chmod +x "$stub_runner"
shard_case() { # bin_dir art_dir run_hw -> rc
  local rc=0; rm -rf "$2"; mkdir -p "$2"
  PATH="$1:$PATH" EMULATOR_ARTIFACTS="$2" EMULATOR_SNAPSHOT_HW="$av/create-booted/snapshot-hardware.ini" EMULATOR_RUN_HW="$3" \
    EMULATOR_FLOW_RUNNER="$stub_runner" bash tool/emulator/run_shard.sh full 1 >"$2.out" 2>&1 || rc=$?
  echo "$rc"
}
# initPath absent + BOOT snapshot: continues (flows run).
rc="$(shard_case "$r43/bin431s" "$r43/art431a" "$r43/avd431/hardware-qemu.ini")"
grep -q '^BOOT full-1 snapshot$' "$r43/art431a/results.txt" && grep -q '^TIME ' "$r43/art431a/results.txt" && ! grep -q '^FAIL boot-' "$r43/art431a/results.txt" ||
  { echo "run_shard: initPath absent on a snapshot boot must continue (rc=$rc): $(cat "$r43/art431a/results.txt")" >&2; exit 1; }
# 2g-vs-6g size mismatch + cold: fails fast, no flow ran.
rc="$(shard_case "$r43/bin431c" "$r43/art431b" "$av/run-booted/hardware-qemu.ini")"
[[ "$rc" == 1 ]] && grep -q '^FAIL boot-full-1: snapshot config mismatch, cold boot: SNAPSHOT_CONFIG mismatch: disk.dataPartition.size snapshot=6442450944 boot=2147483648' "$r43/art431b/results.txt" && ! grep -q '^TIME ' "$r43/art431b/results.txt" ||
  { echo "run_shard must fail fast on size mismatch + cold boot (rc=$rc): $(cat "$r43/art431b/results.txt")" >&2; exit 1; }
# size mismatch but the snapshot marker is set: recorded, not fatal.
rc="$(shard_case "$r43/bin431s" "$r43/art431c" "$av/run-booted/hardware-qemu.ini")"
grep -q '^SNAPCFG full-1 SNAPSHOT_CONFIG mismatch' "$r43/art431c/results.txt" && grep -q '^TIME ' "$r43/art431c/results.txt" && ! grep -q '^FAIL boot-' "$r43/art431c/results.txt" ||
  { echo "run_shard: mismatch on a snapshot boot is recorded, not fatal (rc=$rc): $(cat "$r43/art431c/results.txt")" >&2; exit 1; }
grep -q '^::warning::emulator full shard 1: snapshot boot, but the AVD config differs from the snapshot: SNAPSHOT_CONFIG mismatch: disk.dataPartition.size' "$r43/art431c.out" ||
  { echo "run_shard: mismatch on a snapshot boot prints ::warning:: (round 4.3.3): $(cat "$r43/art431c.out")" >&2; exit 1; }
# (a)/(3): worst case counts the outer kill-after; avd-warmup runs beside build.
[[ "$(plan_need_s full 12)" == 2089 && "$(plan_need_s full 15)" == 1829 && "$(plan_need_s full 11)" == 2129 && "$(plan_need_s full 10)" == 2129 && "$(plan_need_s full 1)" == 2129 ]] || { echo "plan_need_s: shard 12 2089s (06a1 06a2 06b 31), 15 1829s, shards 1/10/11 2129s" >&2; exit 1; }
grep -q 'timeout --kill-after="$FLOW_OUTER_KILL_S"' tool/emulator/run_shard.sh || { echo "run_shard outer kill-after must be FLOW_OUTER_KILL_S" >&2; exit 1; }
awk '/^  avd-warmup:/ { w = 1 } w && /needs:/ { print; exit }' "$workflow" | grep -qx '    needs: \[gate\]' || { echo "avd-warmup must need only the gate (parallel with build)" >&2; exit 1; }
#R43_MORE
rm -rf "$r43"
echo "round 4.3 checks ok"
# ---------------------------------------------------------------------------
# Round 4.4 (run 41461260068, run126/r6/triage.md)
# ---------------------------------------------------------------------------
r44="$(mktemp -d)"
# A. Boot readiness. Stub adb: "service check input" reports not found the
# first SVC_NOT_FOUND times (always, with -1); every call is logged.
mk_svc_adb() { # dir
  mkdir -p "$1"
  cat > "$1/adb" <<'ADB'
#!/usr/bin/env bash
echo "$*" >> "$STUB_DIR/calls"
case "$*" in
  "shell service check input")
    n=$(( $(cat "$STUB_DIR/n" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$STUB_DIR/n"
    if [[ "$SVC_NOT_FOUND" == -1 || "$n" -le "$SVC_NOT_FOUND" ]]; then echo "Service input: not found"; else echo "Service input: found"; fi ;;
  "shell service check "*) echo "Service ${4}: found" ;;
  "shell pm path android") echo "package:/system/framework/framework-res.apk" ;;
  "shell getprop sys.boot_completed") echo 1 ;;
  "shell getprop debug.temple.snapshot_marker") echo 1 ;;
  "emu avd snapshot save default_boot") echo OK ;;
  *) : ;;
esac
ADB
  chmod +x "$1/adb"
}
mk_svc_adb "$r44/bin"
svc() { # not_found_count cmd... -> runs with the stub on PATH
  local nf="$1"; shift
  rm -f "$r44/calls" "$r44/n"
  PATH="$r44/bin:$PATH" STUB_DIR="$r44" SVC_NOT_FOUND="$nf" EMULATOR_SERVICES_POLL_S=0 "$@"
}
o="$(svc 2 bash tool/emulator/services_ready.sh 10)" && [[ "$o" == *"services ready after 3 poll(s)"* ]] ||
  { echo "services_ready: not found twice then found must pass after 3 polls: $o" >&2; exit 1; }
o="$(svc -1 bash tool/emulator/services_ready.sh 1)" && { echo "services_ready: never found must fail: $o" >&2; exit 1; }
[[ "$o" == *"services not ready after 1s"*input* ]] || { echo "services_ready names the missing service: $o" >&2; exit 1; }
# snapshot_create: never ready -> exit 1 and no save; ready on poll 3 -> saved after the checks.
rc=0; svc -1 env EMULATOR_SNAPSHOT_READY_S=1 EMULATOR_SNAPSHOT_SETTLE_S=0 bash tool/emulator/snapshot_create.sh >"$r44/snap.out" 2>&1 || rc=$?
[[ "$rc" == 1 ]] && ! grep -q 'snapshot save' "$r44/calls" && ! grep -q 'setprop' "$r44/calls" ||
  { echo "snapshot_create: services never ready must exit 1 without saving (rc=$rc): $(cat "$r44/calls" "$r44/snap.out")" >&2; exit 1; }
rc=0; svc 2 env EMULATOR_SNAPSHOT_READY_S=10 EMULATOR_SNAPSHOT_SETTLE_S=0 bash tool/emulator/snapshot_create.sh >"$r44/snap.out" 2>&1 || rc=$?
[[ "$rc" == 0 && "$(grep -c 'service check input' "$r44/calls")" == 3 ]] &&
  awk '/service check input/ { s = NR } /emu avd snapshot save/ { v = NR } END { exit !(s && v > s) }' "$r44/calls" ||
  { echo "snapshot_create: ready on poll 3 then save (rc=$rc): $(cat "$r44/calls")" >&2; exit 1; }
grep -q 'EMULATOR_SNAPSHOT_READY_S:-60' tool/emulator/snapshot_create.sh && grep -q 'EMULATOR_SNAPSHOT_SETTLE_S:-10' tool/emulator/snapshot_create.sh &&
  grep -q 'timeout "${SHARD_ANIM_S:-5}" adb shell "$ANIM_OFF_CMD"' tool/emulator/snapshot_create.sh ||
  { echo "snapshot_create waits up to 60s, animations off in one capped call, settles 10s" >&2; exit 1; }
# run_shard (round 4.4.9): readiness BEFORE the BOOT line (not ready = dead
# boot); unlock + animations after it, never fatal.
grep -q 'services_wait_s="${EMULATOR_SERVICES_WAIT_S:-$((SHARD_READY_S - 2))}"' tool/emulator/run_shard.sh &&
  grep -q 'timeout "${SHARD_ANIM_S:-5}" adb shell "$ANIM_OFF_CMD"' tool/emulator/run_shard.sh &&
  awk '/svc_out="\$\(wait_services_ready "/ { w = NR } /printf .BOOT / { b = NR } /adb shell "\$ANIM_OFF_CMD"/ { a = NR } END { exit !(w && b && a && w < b && a > b) }' tool/emulator/run_shard.sh ||
  { echo "run_shard waits for services before the BOOT line, unlocks and turns animations off after it" >&2; exit 1; }
cat > "$r44/runner.sh" <<'RUN'
#!/bin/sh
echo "PASS $1: stub" >> "$EMULATOR_ARTIFACTS/results.txt"
RUN
chmod +x "$r44/runner.sh"
rm -rf "$r44/art"; mkdir -p "$r44/art"
rc=0; svc -1 env EMULATOR_SERVICES_WAIT_S=1 EMULATOR_ARTIFACTS="$r44/art" EMULATOR_FLOW_RUNNER="$r44/runner.sh" \
  EMULATOR_SNAPSHOT_HW="$av/create-booted/snapshot-hardware.ini" EMULATOR_RUN_HW="$av/create-booted/hardware-qemu.ini" \
  bash tool/emulator/run_shard.sh full 1 >"$r44/shard.out" 2>&1 || rc=$?
# Round 4.4.9 (run 41757362316): services never ready -> dead boot: exit 1,
# no BOOT line (the workflow's boot check retries), a DEAD line, no flow,
# no unlock.
[[ "$rc" == 1 ]] && ! grep -q '^BOOT ' "$r44/art/results.txt" && grep -q '^DEAD boot full-1: system services not ready after 1s (services not ready after 1s' "$r44/art/results.txt" &&
  ! grep -q '^PASS ' "$r44/art/results.txt" && ! grep -q '^TIME ' "$r44/art/results.txt" && [[ "$(grep -c 'shell input keyevent 82' "$r44/calls")" == 0 ]] &&
  grep -q 'dead boot (no BOOT line), the boot check retries once' "$r44/shard.out" ||
  { echo "4.4.9 run_shard: services never ready must be a dead boot (rc=$rc): $(cat "$r44/shard.out" "$r44/art/results.txt")" >&2; exit 1; }
echo "4.4.9 run_shard: services never ready -> rc 1, no BOOT, DEAD line, no flows"
# ... and the workflow's boot check then retries it (no BOOT line -> retry=true).
bc_dir="$(mktemp -d)"; mkdir -p "$bc_dir/emulator-app-test-artifacts"; cp "$r44/art/results.txt" "$bc_dir/emulator-app-test-artifacts/"
bc_script="$(awk '/- name: Check for a boot death/ { f = 1 } f && /run: \|/ { r = 1; next } r && /^      - name:/ { exit } r { sub(/^          /, ""); print }' "$workflow")"
( cd "$bc_dir" && mkdir -p bin && printf '#!/bin/sh\nexit 0\n' > bin/adb && chmod +x bin/adb &&
  PATH="$bc_dir/bin:$PATH" GITHUB_OUTPUT="$bc_dir/out" bash -c "${bc_script//\$\{\{ matrix.shard \}\}/1}" >/dev/null 2>&1 )
grep -qx 'retry=true' "$bc_dir/out" && grep -q '^DEAD boot full-1' "$bc_dir/emulator-app-test-artifacts/results-boot-death.txt" &&
  grep -q '^RETRY boot 1:' "$bc_dir/emulator-app-test-artifacts/results.txt" ||
  { echo "4.4.9: the boot check must retry a DEAD boot: $(cat "$bc_dir/out" 2>/dev/null)" >&2; exit 1; }
echo "4.4.9 boot check: DEAD boot -> retry=true, dead attempt in results-boot-death.txt"
# Ready late but within the bound (poll 3 of a 10s wait) -> BOOT and the flows run.
rm -rf "$r44/art"; mkdir -p "$r44/art"
rc=0; svc 2 env EMULATOR_SERVICES_WAIT_S=10 EMULATOR_ARTIFACTS="$r44/art" EMULATOR_FLOW_RUNNER="$r44/runner.sh" \
  EMULATOR_SNAPSHOT_HW="$av/create-booted/snapshot-hardware.ini" EMULATOR_RUN_HW="$av/create-booted/hardware-qemu.ini" \
  bash tool/emulator/run_shard.sh full 1 >"$r44/shard.out" 2>&1 || rc=$?
[[ "$rc" == 0 ]] && grep -q '^BOOT full-1 snapshot$' "$r44/art/results.txt" && grep -q '^HOSTCPU full-1 ' "$r44/art/results.txt" && grep -q '^PASS ' "$r44/art/results.txt" &&
  grep -q 'services ready after 3 poll(s)' "$r44/shard.out" && ! grep -q '^DEAD ' "$r44/art/results.txt" ||
  { echo "4.4.9 run_shard: services ready late within the bound must continue (rc=$rc): $(cat "$r44/shard.out")" >&2; exit 1; }
echo "4.4.9 run_shard: services ready on poll 3 within 10s -> BOOT, flows run"
# keyevent 82 failing: retried 3 times (round 4.4.2), never fatal.
cat > "$r44/bin/adb.fail82" <<'ADB'
#!/usr/bin/env bash
echo "$*" >> "$STUB_DIR/calls"
[[ "$*" == "shell input keyevent 82" ]] && { echo "No service published for: input" >&2; exit 1; }
exec "$STUB_DIR/bin/adb.ok" "$@"
ADB
cp "$r44/bin/adb" "$r44/bin/adb.ok"; sed -i '2d' "$r44/bin/adb.ok"; cp "$r44/bin/adb.fail82" "$r44/bin/adb"; chmod +x "$r44/bin/adb" "$r44/bin/adb.ok"
rm -rf "$r44/art"; mkdir -p "$r44/art"
rc=0; svc 0 env EMULATOR_ARTIFACTS="$r44/art" EMULATOR_FLOW_RUNNER="$r44/runner.sh" \
  EMULATOR_SNAPSHOT_HW="$av/create-booted/snapshot-hardware.ini" EMULATOR_RUN_HW="$av/create-booted/hardware-qemu.ini" \
  bash tool/emulator/run_shard.sh full 1 >"$r44/shard.out" 2>&1 || rc=$?
[[ "$rc" == 0 && "$(grep -c 'shell input keyevent 82' "$r44/calls")" == 2 ]] && grep -q 'unlock (keyevent 82) failed 2 times; continuing' "$r44/shard.out" && grep -q '^TIME ' "$r44/art/results.txt" ||
  { echo "run_shard: unlock retried 3 times, never fatal (rc=$rc): $(grep -c 'keyevent 82' "$r44/calls") $(cat "$r44/shard.out")" >&2; exit 1; }
# Round 4.4.3 (Manu): a hang before the BOOT line ends within the pre-BOOT
# watchdog (here 2s) with no BOOT line, so the boot retry runs; the hung
# adb is killed too (it would keep the step's stdout open).
cat > "$r44/bin/adb" <<'ADB'
#!/usr/bin/env bash
echo "$*" >> "$STUB_DIR/calls"
[[ "$*" == "shell getprop debug.temple.snapshot_marker" ]] && exec sleep 37.5
exec "$STUB_DIR/bin/adb.ok" "$@"
ADB
chmod +x "$r44/bin/adb"
rm -rf "$r44/art" "$r44/wdtmp"; mkdir -p "$r44/art" "$r44/wdtmp"; wd_t0=$SECONDS; wd_n0="$(date +%s%N)"
rc=0; svc 0 env TMPDIR="$r44/wdtmp" EMULATOR_PREBOOT_S=2 SHARD_GETPROP_S=30 EMULATOR_ARTIFACTS="$r44/art" EMULATOR_FLOW_RUNNER="$r44/runner.sh" \
  EMULATOR_SNAPSHOT_HW="$av/create-booted/snapshot-hardware.ini" EMULATOR_RUN_HW="$av/create-booted/hardware-qemu.ini" \
  bash tool/emulator/run_shard.sh full 1 >"$r44/shard.out" 2>&1 || rc=$?
wd_el=$((SECONDS - wd_t0)); wd_ms=$(( ($(date +%s%N) - wd_n0) / 1000000 ))
# Round 4.4.5 (Manu nit 2): the watchdog that won removes the BOOT claim
# dir (allow it 1s to finish after run_shard.sh is gone), and the attempt
# ends soon after the watchdog fires (2s). Round 4.4.7: <= 4500 ms (2s
# watchdog + 2.5s teardown on a loaded 2-core runner; CI saw 2084/2113 ms,
# 2 cores + 2 busy loops 2217 ms). Still proves the watchdog ended it: the
# stubbed getprop hangs 37.5s under a 30s cap here, the default getprop
# cap is 5s and the real watchdog is SHARD_PREBOOT_S=10s, all > 4.5s.
for _ in 1 2 3 4 5 6 7 8 9 10; do compgen -G "$r44/wdtmp/run_shard.boot.*" >/dev/null || break; sleep 0.1; done
! compgen -G "$r44/wdtmp/run_shard.boot.*" >/dev/null || { echo "run_shard: watchdog won but left its BOOT claim dir: $(ls "$r44/wdtmp")" >&2; exit 1; }
(( wd_ms <= 4500 )) || { echo "run_shard: attempt ended ${wd_ms} ms after start, > 2.5s after the 2s watchdog" >&2; exit 1; }
echo "pre-BOOT watchdog: attempt ended ${wd_ms} ms after start (watchdog 2000 ms), claim dir removed"
# <= 5s (round 4.4.7, whole seconds of the <= 4500 ms above): the watchdog
# itself must end it (2s), not the 5s or 30s getprop cap
# (round 4.4.4 mutation: a watchdog that kills nothing must fail here).
[[ "$rc" != 0 ]] && (( wd_el <= 5 )) && ! grep -q '^BOOT ' "$r44/art/results.txt" 2>/dev/null && ! grep -q '^PASS ' "$r44/art/results.txt" 2>/dev/null &&
  grep -q 'no BOOT line 2s after run_shard.sh started' "$r44/shard.out" && ! pgrep -f 'sleep 37.5' >/dev/null ||
  { echo "run_shard pre-BOOT watchdog: rc=${rc} ${wd_el}s, no BOOT, hung adb killed: $(cat "$r44/shard.out"; pgrep -af 'sleep 37.5')" >&2; pkill -f 'sleep 37.5'; exit 1; }
# Round 4.4.4: a hung "shell input keyevent 82" after BOOT is capped per
# try (timeout 3, 2 tries 2s apart = 8s; round 4.4.6), never fatal, and the flows run.
cat > "$r44/bin/adb" <<'ADB'
#!/usr/bin/env bash
echo "$*" >> "$STUB_DIR/calls"
[[ "$*" == "shell input keyevent 82" ]] && exec sleep 38.5
exec "$STUB_DIR/bin/adb.ok" "$@"
ADB
chmod +x "$r44/bin/adb"
rm -rf "$r44/art"; mkdir -p "$r44/art"; ul_t0=$SECONDS
rc=0; svc 0 env EMULATOR_ARTIFACTS="$r44/art" EMULATOR_FLOW_RUNNER="$r44/runner.sh" \
  EMULATOR_SNAPSHOT_HW="$av/create-booted/snapshot-hardware.ini" EMULATOR_RUN_HW="$av/create-booted/hardware-qemu.ini" \
  bash tool/emulator/run_shard.sh full 1 >"$r44/shard.out" 2>&1 || rc=$?
ul_el=$((SECONDS - ul_t0))
[[ "$rc" == 0 ]] && (( ul_el <= 25 )) && grep -q '^BOOT full-1 snapshot$' "$r44/art/results.txt" && grep -q '^TIME ' "$r44/art/results.txt" &&
  grep -q 'unlock (keyevent 82) failed 2 times; continuing' "$r44/shard.out" && ! pgrep -f 'sleep 38.5' >/dev/null ||
  { echo "run_shard: a hung keyevent 82 is capped per try (rc=${rc} ${ul_el}s): $(cat "$r44/shard.out")" >&2; pkill -f 'sleep 38.5'; exit 1; }
# Round 4.4.4 (Manu nit 2): the watchdog expiring between the BOOT claim
# and the BOOT write must not kill the attempt (the claim is an atomic
# mkdir): watchdog 1s, BOOT write delayed 3s after the claim -> rc 0, BOOT.
cp "$r44/bin/adb.ok" "$r44/bin/adb"
rm -rf "$r44/art"; mkdir -p "$r44/art"
rc=0; svc 0 env EMULATOR_PREBOOT_S=1 EMULATOR_TEST_BOOT_WRITE_DELAY_S=3 EMULATOR_ARTIFACTS="$r44/art" EMULATOR_FLOW_RUNNER="$r44/runner.sh" \
  EMULATOR_SNAPSHOT_HW="$av/create-booted/snapshot-hardware.ini" EMULATOR_RUN_HW="$av/create-booted/hardware-qemu.ini" \
  bash tool/emulator/run_shard.sh full 1 >"$r44/shard.out" 2>&1 || rc=$?
[[ "$rc" == 0 ]] && grep -q '^BOOT full-1 snapshot$' "$r44/art/results.txt" && grep -q '^TIME ' "$r44/art/results.txt" &&
  ! grep -q 'no BOOT line' "$r44/shard.out" ||
  { echo "run_shard: watchdog/BOOT race (claim then 3s delay, watchdog 1s): rc=${rc} $(cat "$r44/shard.out")" >&2; exit 1; }
# Round 4.4.4 (Manu nit 3) / 4.4.5 (Manu blocker): the action's own adb
# calls go through adb_shim, installed in place by install.sh: a hung
# "shell input keyevent 82" / "shell settings put" ends at the cap,
# anything else passes through with its exit code.
# Simulates the action: fake SDK platform-tools with the real adb (sleeps
# forever on keyevent), install.sh, a GITHUB_PATH-style dir holding another
# adb, then the action's core.addPath($ANDROID_HOME/platform-tools) prepended
# AFTER it (so platform-tools wins, as in sdk-installer.ts:41).
shim_d="$(mktemp -d)"; mkdir -p "$shim_d/sdk/platform-tools" "$shim_d/ghpath"; export ADB_SHIM_STATE_DIR="$shim_d/state"
cat > "$shim_d/sdk/platform-tools/adb" <<'ADB'
#!/usr/bin/env bash
case "$*" in *"shell input keyevent 82"|*"shell settings put"*) exec sleep 31.5 ;; "devices") echo devices-ok; exit 0 ;; *) exit 7 ;; esac
ADB
printf '#!/usr/bin/env bash\necho ghpath-adb; exit 9\n' > "$shim_d/ghpath/adb"
chmod +x "$shim_d/sdk/platform-tools/adb" "$shim_d/ghpath/adb"
bash tool/emulator/adb_shim/install.sh "$shim_d/sdk/platform-tools" >/dev/null
bash tool/emulator/adb_shim/install.sh "$shim_d/sdk/platform-tools" >/dev/null # idempotent
[[ -x "$shim_d/sdk/platform-tools/adb.real" ]] && cmp -s tool/emulator/adb_shim/adb "$shim_d/sdk/platform-tools/adb" &&
  grep -q 'exec sleep 31.5' "$shim_d/sdk/platform-tools/adb.real" || { echo "adb_shim install.sh: adb -> adb.real, shim -> adb (twice)" >&2; exit 1; }
shim_path="$shim_d/sdk/platform-tools:$shim_d/ghpath:$PATH"
[[ "$(PATH="$shim_path" command -v adb)" == "$shim_d/sdk/platform-tools/adb" ]] || { echo "adb_shim: action PATH does not resolve to the shim" >&2; exit 1; }
sh_t0=$SECONDS; rc1=0; rc2=0; rc4=0
ANDROID_HOME="$shim_d/sdk" EMULATOR_ACTION_ADB_S=1 PATH="$shim_path" adb -s emulator-5554 shell input keyevent 82 || rc1=$?
ANDROID_HOME="$shim_d/sdk" EMULATOR_ACTION_ADB_S=1 PATH="$shim_path" adb -s emulator-5554 shell settings put global x 0 || rc2=$?
sh_el=$((SECONDS - sh_t0))
out3="$(ANDROID_HOME="$shim_d/sdk" PATH="$shim_path" adb devices)"
ANDROID_HOME="$shim_d/sdk" PATH="$shim_path" adb shell getprop x || rc4=$?
# Round 4.4.8b: the action's timed-out keyevent 82 is killed at the cap and
# exits 0 with a warning; its settings put is killed at the cap with the
# real exit code (124).
[[ "$rc1" == 0 && "$rc2" == 124 && "$out3" == devices-ok && "$rc4" == 7 ]] && (( sh_el <= 5 )) && ! pgrep -f 'sleep 31.5' >/dev/null ||
  { echo "adb_shim: keyevent/settings capped (rc ${rc1} ${rc2}, ${sh_el}s), others pass (${out3} ${rc4})" >&2; pkill -f 'sleep 31.5'; exit 1; }
rm -rf "$shim_d"
# Round 4.4.6 (Manu A): prepare_avd.sh (pre-launch script of all four
# action calls) re-installs the shim; a fresh real adb from sdkmanager is
# moved over an existing adb.real, even while the old adb.real runs (mv,
# not cp: writing onto a running binary fails with "Text file busy").
r46="$(mktemp -d)"; export ADB_SHIM_STATE_DIR="$r46/state"
mkdir -p "$r46/pt"
# Round 4.4.7: the "real adb" is a copy of bash, not of sleep. On the
# ubuntu-26.04 runner sleep is rust-coreutils, a multi-call binary that
# refuses to run under another file name ("Security violation: Requested
# utility `adb` does not match executable name: .../pt/adb.real", runs
# 41580611177 and 41580615725). bash runs under any name and stays mapped
# (no exec) while its child sleeps, so the file is still busy.
cp "$(command -v bash)" "$r46/pt/adb"   # an ELF "real adb"
bash tool/emulator/adb_shim/install.sh "$r46/pt" >/dev/null || { echo "4.4.6 install.sh first install" >&2; exit 1; }
"$r46/pt/adb.real" -c 'sleep 37.25; :' & old_real=$!   # the old adb (server) still running
for _ in 1 2 3 4 5 6 7 8 9 10; do pgrep -P "$old_real" >/dev/null && break; sleep 0.1; done
kill -0 "$old_real" 2>/dev/null || { echo "4.4.7: the stand-in real adb did not start" >&2; exit 1; }
tfb="$(cp /bin/true "$r46/pt/adb.real" 2>&1)" && { echo "4.4.6: expected Text file busy writing onto a running adb.real" >&2; kill "$old_real"; exit 1; }
[[ "$tfb" == *"Text file busy"* ]] || { echo "4.4.6: cp onto a running binary should say Text file busy: $tfb" >&2; kill "$old_real"; exit 1; }
printf '#!/usr/bin/env bash\necho NEWREAL "$@"\n' > "$r46/pt/adb"; chmod +x "$r46/pt/adb"   # sdkmanager's fresh adb
o="$(bash tool/emulator/adb_shim/install.sh --reinstall "$r46/pt" 2>&1)" || { echo "4.4.6 reinstall over a running adb.real failed: $o" >&2; kill "$old_real"; exit 1; }
pkill -P "$old_real" 2>/dev/null; kill "$old_real" 2>/dev/null; wait "$old_real" 2>/dev/null || true
cmp -s tool/emulator/adb_shim/adb "$r46/pt/adb" && grep -q NEWREAL "$r46/pt/adb.real" && [[ "$o" == *"::warning::adb_shim: $r46/pt/adb was replaced"* ]] ||
  { echo "4.4.6 reinstall: adb must be the shim and adb.real the NEW binary: $o" >&2; exit 1; }
[[ "$("$r46/pt/adb" devices)" == "NEWREAL devices" ]] || { echo "4.4.6: shim passes through to the new adb.real" >&2; exit 1; }
rm -f "$r46/pt/adb.real"; rc=0; o="$(bash tool/emulator/adb_shim/install.sh --reinstall "$r46/pt" 2>&1)" || rc=$?
[[ "$rc" == 1 && "$o" == *"::warning::adb_shim: no real adb ($r46/pt/adb.real missing)"* ]] || { echo "4.4.6: missing adb.real warns: rc $rc $o" >&2; exit 1; }
grep -q 'adb_shim/install.sh" --reinstall "${ANDROID_HOME}/platform-tools"' tool/emulator/prepare_avd.sh || { echo "4.4.6: prepare_avd.sh re-installs the shim" >&2; exit 1; }
[[ "$(grep -c 'pre-emulator-launch-script: ${{ env.EMULATOR_PRE_LAUNCH }} ' "$workflow")" == 4 && "$(grep -c 'uses: reactivecircus/android-emulator-runner@' "$workflow")" == 4 ]] ||
  { echo "4.4.6: all four action calls (warm-up create, shard create, flows, retry) run prepare_avd.sh" >&2; exit 1; }
# Round 4.4.6 (Manu B): one getprop budget per boot (serial + boot id),
# then fail fast. Simulates the action's waitForDevice (T=8: 4 tries + 2s
# delays, then the throw) against a getprop that hangs forever.
printf '#!/usr/bin/env bash\ncase "$*" in *"getprop sys.boot_completed") exec sleep 41.75 ;; *) echo ok ;; esac\n' > "$r46/pt/adb.real"; chmod +x "$r46/pt/adb.real"
bash tool/emulator/adb_shim/install.sh --reinstall "$r46/pt" >/dev/null
wait_for_device() { local attempts=0 max=$(( $1 / 2 )) t0 gp=0; while :; do t0=$(date +%s%N); "$r46/pt/adb" -s emulator-5554 shell getprop sys.boot_completed >/dev/null 2>&1; gp=$(( gp + ($(date +%s%N) - t0) / 1000000 )); if (( attempts < max )); then sleep 2; else echo "$gp"; return 1; fi; attempts=$((attempts + 1)); done; }
w0=$(date +%s%N); gp_ms="$(timeout 40 bash -c "$(declare -f wait_for_device); r46='$r46'; wait_for_device 8" || true)"; w_ms=$(( ($(date +%s%N) - w0) / 1000000 ))
[[ -n "$gp_ms" ]] && (( gp_ms <= 4300 && w_ms <= 4300 + 8000 + 700 )) && ! pgrep -f 'sleep 41.75' >/dev/null ||
  { echo "4.4.6 getprop budget: getprop total ${gp_ms:-none} ms (<= 4000 + slack), loop ${w_ms} ms (<= 4 s + 4 x 2 s delays)" >&2; pkill -f 'sleep 41.75'; exit 1; }
ls "$ADB_SHIM_STATE_DIR"/getprop.emulator-5554.* >/dev/null 2>&1 || { echo "4.4.6: budget state keyed by serial + boot id under the state dir" >&2; exit 1; }
[[ "$(bash -c 'source tool/emulator/plan.sh; echo "$SHARD_GETPROP_BUDGET_S"')" == 4 ]] && grep -q 'ADB_SHIM_GETPROP_BUDGET_MS:-3500' tool/emulator/adb_shim/adb && grep -q 'kill-after=0.5' tool/emulator/adb_shim/adb ||
  { echo "4.4.6: shim budget 3500 ms + 0.5 s kill-after = plan.sh SHARD_GETPROP_BUDGET_S 4" >&2; exit 1; }
# A new boot (prepare_avd.sh -> install.sh) gets a fresh budget.
bash tool/emulator/adb_shim/install.sh --reinstall "$r46/pt" >/dev/null; g0=$(date +%s%N)
"$r46/pt/adb" -s emulator-5554 shell getprop sys.boot_completed >/dev/null 2>&1 || true; g_ms=$(( ($(date +%s%N) - g0) / 1000000 ))
(( g_ms >= 3000 )) || { echo "4.4.6: a new boot id resets the getprop budget (got ${g_ms} ms, want ~3500)" >&2; exit 1; }
"$r46/pt/adb" shell getprop debug.x >/dev/null || { echo "4.4.6: other getprops pass through" >&2; exit 1; }
echo "getprop budget: ${gp_ms} ms of getprop in a ${w_ms} ms boot wait (T=8); reset per boot"
# Round 4.4.6 (Manu nit 1): after a failed create the warn step stops the
# emulator, bounded (a hung "adb emu kill" -> pkill qemu-system), and drops
# the AVD locks; it still exits 0.
mkdir -p "$r46/bin" "$r46/home/.android/avd/x.avd"; : > "$r46/home/.android/avd/x.avd/hardware-qemu.ini.lock"
printf '#!/usr/bin/env bash\n[[ "$*" == "emu kill" ]] && exec sleep 43.5\nexit 0\n' > "$r46/bin/adb"; chmod +x "$r46/bin/adb"
bash -c 'exec -a qemu-system-x86_64-r46 sleep 44.5' & fake_qemu=$!
k0=$SECONDS; rc=0; o="$(HOME="$r46/home" PATH="$r46/bin:$PATH" EMULATOR_SHARD=3 bash tool/emulator/create_warn.sh failure)" || rc=$?; k_el=$((SECONDS - k0))
sleep 0.3
[[ "$rc" == 0 && "$o" == "::warning::shard 3:"* ]] && (( k_el <= 6 )) && ! kill -0 "$fake_qemu" 2>/dev/null && [[ ! -e "$r46/home/.android/avd/x.avd/hardware-qemu.ini.lock" ]] && ! pgrep -f 'sleep 43.5' >/dev/null ||
  { echo "4.4.6 create_warn: rc ${rc}, ${k_el}s (<= 6), qemu stopped, lock removed: $o" >&2; kill "$fake_qemu" 2>/dev/null; pkill -f 'sleep 43.5'; exit 1; }
wait "$fake_qemu" 2>/dev/null || true
# Round 4.4.6 (Satyavrat: 1.5 min): the shard create is cut at the deadline
# (GitHub truncates fractional timeout-minutes): a hung adb, deadline 3s.
printf '#!/usr/bin/env bash\nexec sleep 45.5\n' > "$r46/bin/adb"; date +%s > "$r46/create_start"
d0=$SECONDS; rc=0; o="$(PATH="$r46/bin:$PATH" EMULATOR_CREATE_DEADLINE_S=3 EMULATOR_CREATE_START_FILE="$r46/create_start" EMULATOR_SNAPSHOT_READY_S=12 bash tool/emulator/snapshot_create.sh 2>&1)" || rc=$?; d_el=$((SECONDS - d0))
[[ "$rc" != 0 && "$o" == *"3s deadline reached; not saving"* ]] && (( d_el <= 5 )) || { echo "4.4.6 snapshot_create deadline: rc ${rc} ${d_el}s: $o" >&2; pkill -f 'sleep 45.5'; exit 1; }
pkill -f 'sleep 45.5' 2>/dev/null || true
python3 - "$workflow" <<'PY' || exit 1
import sys
wf = open(sys.argv[1]).read(); job = wf[wf.index("\n  emulator:"):]
def step(name):
    i = job.index(f"\n      - name: {name}\n"); j = job.find("\n      - name:", i + 1)
    return job[i:j]
mk, cr = step("Mark shard snapshot create start"), step("Create AVD snapshot")
assert 'run: date +%s > "${RUNNER_TEMP}/create_start"' in mk and job.index("name: Mark shard snapshot create start") < job.index("name: Create AVD snapshot"), mk
assert 'EMULATOR_CREATE_DEADLINE_S: "90"' in cr and "timeout-minutes: 2\n" in cr, cr
PY
[[ "$(bash -c 'source tool/emulator/plan.sh; echo "$SHARD_CREATE_DEADLINE_S $SHARD_UNLOCK_TRIES $SHARD_UNLOCK_S $SHARD_RETRY_BOOT_S $SHARD_CREATE_BOOT_S $SHARD_BOOT_S $SHARD_CREATE_READY_S"')" == "90 2 8 50 50 150 12" ]] ||
  { echo "4.4.6 values: deadline 90, unlock 2 (8s), retry boot 50, shard create boot 50, first boot 150, create ready 12" >&2; exit 1; }
unset ADB_SHIM_STATE_DIR; rm -rf "$r46"
echo "round 4.4.6 checks ok"
cp "$r44/bin/adb.fail82" "$r44/bin/adb"
mk_svc_adb "$r44/bin"
# Workflow: boot-retry step only on a failed flows step with no BOOT line.
python3 - "$workflow" <<'PY' || exit 1
import re, sys
wf = open(sys.argv[1]).read()
job = wf[wf.index("\n  emulator:"):]
names = re.findall(r"\n      - name: (.+)", job)
need = ["Run emulator flows", "Check for a boot death", "Run emulator flows (boot retry)", "Write results summary"]
idx = [names.index(n) for n in need]
assert idx == sorted(idx) and idx[1] == idx[0] + 1 and idx[2] == idx[1] + 1, f"step order {names}"
def step(name):
    i = job.index(f"\n      - name: {name}\n"); j = job.find("\n      - name:", i + 1)
    return job[i:j]
chk, rt, fl = step("Check for a boot death"), step("Run emulator flows (boot retry)"), step("Run emulator flows")
assert "if: ${{ !cancelled() && steps.flows.outcome == 'failure' }}" in chk, chk
assert "id: boot-check" in chk and "grep -q '^BOOT ' emulator-app-test-artifacts/results.txt" in chk and "adb emu kill" in chk, chk
assert chk.index("adb emu kill") < chk.index('echo "retry=true"'), chk
assert "if: ${{ !cancelled() && steps.flows.outcome == 'failure' && steps.boot-check.outputs.retry == 'true' }}" in rt, rt
strip = lambda t: [l for l in t.splitlines() if l.strip().startswith(("api-level", "target", "arch", "cores", "disk-size", "avd-name", "force-avd", "disable-anim", "emulator-", "pre-emulator", "script:", "uses:", "timeout-minutes"))]
# Round 4.4.3: identical except the retry's boot wait (EMULATOR_RETRY_BOOT_TIMEOUT).
# Round 4.4.9c: the retry differs only in its boot wait and -no-snapshot-load.
assert [l.replace(" -no-snapshot-load", "") for l in strip(rt) if "emulator-boot-timeout" not in l] == [l for l in strip(fl) if "emulator-boot-timeout" not in l], (strip(rt), strip(fl))
assert "emulator-options: ${{ env.EMULATOR_OPTIONS }} -no-snapshot-load" in rt, rt
assert "emulator-boot-timeout: ${{ env.EMULATOR_RETRY_BOOT_TIMEOUT }}" in rt
# Round 4.4.4/4.4.5: after this job's own create step (saved or failed) 60s like the retry.
assert "emulator-boot-timeout: ${{ (steps.create-avd.outcome == 'success' || steps.create-avd.outcome == 'failure') && env.EMULATOR_RETRY_BOOT_TIMEOUT || env.EMULATOR_BOOT_TIMEOUT }}" in fl, fl
assert "sleep 5" not in chk and "timeout 5 sh -c 'adb emu kill; adb wait-for-disconnect' </dev/null || true" in chk, chk
# Round 4.4.6 (Reviewer): no untimed adb call in the boot check.
assert all(("timeout" in l) for l in chk.splitlines() if "adb " in l and not l.strip().startswith("#")), chk
assert 'EMULATOR_BOOT_TIMEOUT: "150"' in wf
PY
# The boot-check script itself: BOOT line -> retry=false; none -> kill + retry=true.
chk_sh="$(python3 - "$workflow" <<'PY'
import sys
wf = open(sys.argv[1]).read()
i = wf.index("      - name: Check for a boot death"); j = wf.index("      - name: Run emulator flows (boot retry)")
blk = wf[i:j].split("        run: |\n", 1)[1]
print("\n".join(l[10:] for l in blk.splitlines()))
PY
)"
# The step's ${{ matrix.shard }} is an Actions expression; shard 7 here.
chk_sh="${chk_sh//\$\{\{ matrix.shard \}\}/7}"
for case in "BOOT full-1 snapshot:false" "FAIL x:true" ":true"; do
  line="${case%:*}" want="${case##*:}"
  d="$r44/bc"; rm -rf "$d"; mkdir -p "$d/emulator-app-test-artifacts"; [[ -n "$line" ]] && echo "$line" > "$d/emulator-app-test-artifacts/results.txt"
  rm -f "$r44/calls"
  ( cd "$d" && PATH="$r44/bin:$PATH" STUB_DIR="$r44" GITHUB_OUTPUT="$d/out" bash -c "sleep() { :; }; $chk_sh" ) >/dev/null 2>&1
  grep -qx "retry=${want}" "$d/out" || { echo "boot-check with results '${line}': want retry=${want}, got $(cat "$d/out")" >&2; exit 1; }
  if [[ "$want" == true ]]; then grep -q '^emu kill$' "$r44/calls" || { echo "boot-check kills the emulator before the retry" >&2; exit 1; }
  else ! grep -q 'emu kill' "$r44/calls" 2>/dev/null || { echo "boot-check: no kill when BOOT is present" >&2; exit 1; }; fi
done
# B. Deity: the first real option, by its exact label (r6 17c and 30g dumps).
replay44() { # fixture fn...
  ( export EMULATOR_FLOW=99-r44 EMULATOR_ARTIFACTS="$r44/art44" EMULATOR_PACKAGE=com.shradhaventures.temple
    # shellcheck disable=SC1091
    source tool/emulator/lib/common.sh
    ui_dump() { cp "$R44_FX" "$DUMP"; }
    ui_screen_size() { echo 320 640; }
    ui_tap() { echo "TAP ${UI_TEXT:-}"; }
    adb_shell_capped() { shift; echo "ADB $*"; }
    sleep() { :; }
    R44_FX="$1"; shift; "$@" ) 2>&1
}
T44=tool/emulator/testdata/run41461260068
fro() { ui_dump && first_real_option "$1" | sed -n 1p; }
fbp() { ui_dump && filter_bar_present; }
fbp_old() { ui_dump && ui_find --resource-id filter-chip-state; }
deity44="$(sed -n "s/^ALL_INDIA_DEITY_PICK='\(.*\)'\$/\1/p" tool/emulator/lib/common.sh)"
for fx in 17c_deity_select.xml 30g_deity_select.xml; do
  o="$(replay44 "$T44/$fx" select_labeled "$deity44" DEITY)" &&
    grep -qx 'TAP 81 Yoginis; Gauri-Shankar (central shrine) 1' <<<"$o" && ! grep -q '^ADB input swipe' <<<"$o" ||
    { echo "deity @first on r6 ${fx}: tap '81 Yoginis; Gauri-Shankar (central shrine)' on the first screen: $o" >&2; exit 1; }
  o="$(replay44 "$T44/$fx" select_labeled '^Ahalya( +[0-9]+)?$' DEITY)" && { echo "r6 ${fx}: Ahalya is not in the live list: $o" >&2; exit 1; }
done
[[ "$deity44" == @first ]] || { echo "ALL_INDIA_DEITY_PICK must be @first" >&2; exit 1; }
# chip_exact takes the label (count stripped) on a chip showing it.
printf '<hierarchy><node text="" resource-id="filter-chip-deity" content-desc="81 Yoginis; Gauri-Shankar (central shrine)" bounds="[14,181][300,216]" /></hierarchy>' > "$r44/chip81.xml"
o="$(replay44 "$r44/chip81.xml" chip_exact '81 Yoginis; Gauri-Shankar (central shrine)')" || { echo "chip_exact on the 81 Yoginis chip: $o" >&2; exit 1; }
# Old fixture with Ahalya removed: still the first real option, no Ahalya needed.
drop_node() { # in out resource-id-prefix: remove matching nodes (and their subtrees)
  python3 - "$1" "$2" "$3" <<'PY'
import sys, xml.etree.ElementTree as ET
t = ET.parse(sys.argv[1]); root = t.getroot()
for parent in list(root.iter()):
    for ch in list(parent):
        if ch.get("resource-id", "").startswith(sys.argv[3]):
            parent.remove(ch)
t.write(sys.argv[2], encoding="unicode")
PY
}
drop_node tool/emulator/testdata/run41306793034/deity_sheet_open.xml "$r44/deity_no_ahalya.xml" filter-option-deity-Ahalya
grep -q Ahalya tool/emulator/testdata/run41306793034/deity_sheet_open.xml && ! grep -q 'filter-option-deity-Ahalya' "$r44/deity_no_ahalya.xml" || { echo "fixture: Ahalya removed from the old sheet" >&2; exit 1; }
[[ "$(replay44 "$r44/deity_no_ahalya.xml" fro deity)" == '81 Yoginis; Gauri-Shankar (central shrine)' ]] || { echo "first_real_option without Ahalya" >&2; exit 1; }
drop_node "$r44/deity_no_ahalya.xml" "$r44/deity_no_81.xml" "filter-option-deity-81 Yoginis"
[[ "$(replay44 "$r44/deity_no_81.xml" fro deity)" == 'Adinatha — Jain · Jain' ]] || { echo "first_real_option takes the content-desc label: $(replay44 "$r44/deity_no_81.xml" fro deity)" >&2; exit 1; }
printf '<hierarchy><node resource-id="filter-option-deity-any" content-desc="Any deity 811" /></hierarchy>' > "$r44/only_any.xml"
replay44 "$r44/only_any.xml" fro deity >/dev/null && { echo "first_real_option: -any is not a real option" >&2; exit 1; }
# Sim, live list without Ahalya: @first picks the head; the old regex gives up.
o="$(SIM_NO_AHALYA=1 bash "$sim" DEITY '@first' deity,state,district all "$r44/sim1")"
grep -q "^RESULT rc=0 .* label='Aadeity00'" <<<"$o" || { echo "sim (no Ahalya): @first picks the head: $o" >&2; exit 1; }
o="$(SIM_NO_AHALYA=1 bash "$sim" DEITY '^Ahalya( +[0-9]+)?$' deity,state,district all "$r44/sim2")"
grep -q "^RESULT rc=1 " <<<"$o" || { echo "sim (no Ahalya): the old pick must fail: $o" >&2; exit 1; }
# C. 30s filter-kept: any filter chip or filter-clear (r6 seq1 dump: state chip scrolled off).
replay44 "$T44/seq1_filter_kept.xml" fbp >/dev/null || { echo "filter_bar_present on r6 seq1-filter-kept.xml" >&2; exit 1; }
replay44 "$T44/seq1_filter_kept.xml" fbp_old >/dev/null && { echo "fixture: seq1 has no state chip on screen (the old false positive)" >&2; exit 1; }
replay44 "$T44/detail_no_filter_bar.xml" fbp >/dev/null && { echo "filter_bar_present: a dump with no filter bar must fail" >&2; exit 1; }
grep -q 'elif filter_kept "${kept\[@\]}"; then' tool/emulator/flows/29_filter_matrix.sh || { echo "flow 29 filter-kept uses filter_kept when a filter is applied" >&2; exit 1; }
# E. KAN-193 named at the 17c clear comment.
grep -q 'Jira KAN-193' tool/emulator/flows/17_entry_matrix.sh || { echo "17_entry_matrix names KAN-193" >&2; exit 1; }
echo "round 4.4 checks ok"
# Round 4.4.1 (Manu's nits, Sanu's fixture rule)
# 1. @first taps the dumped row in place, after making sure the sheet is at
# the list head (-any on screen). R441_FX is a list of dumps; every sheet
# swipe moves to the next one, so a mid-list sheet must swipe to the head.
replay441() { # "fx1 fx2 ..." fn...
  ( export EMULATOR_FLOW=99-r441 EMULATOR_ARTIFACTS="$r44/art441" EMULATOR_PACKAGE=com.shradhaventures.temple
    # shellcheck disable=SC1091
    source tool/emulator/lib/common.sh
    read -r -a R441_LIST <<<"$1"; shift; R441_I=0
    ui_dump() { cp "${R441_LIST[$R441_I]}" "$DUMP"; }
    ui_sheet_swipe() { echo "SWIPE $1"; (( R441_I + 1 < ${#R441_LIST[@]} )) && R441_I=$((R441_I + 1)); return 0; }
    seek_option() { echo "SEEK $*"; return 1; }
    ui_screen_size() { echo 320 640; }
    ui_tap() { echo "TAP ${UI_TEXT:-}"; }
    adb_shell_capped() { shift; echo "ADB $*"; }
    sleep() { :; }
    "$@" ) 2>&1
}
for fx in 17c_deity_select.xml 30g_deity_select.xml; do
  o="$(replay441 "$T44/$fx" select_labeled '@first' DEITY)" &&
    grep -qx 'TAP 81 Yoginis; Gauri-Shankar (central shrine) 1' <<<"$o" && ! grep -Eq '^(SEEK|SWIPE)' <<<"$o" && grep -q 'tap in place' <<<"$o" ||
    { echo "4.4.1 @first at the head of r6 ${fx}: tap in place, no seek/swipe: $o" >&2; exit 1; }
done
# Mid-list sheet: the -any row and the first two real rows scrolled off.
drop_node "$T44/17c_deity_select.xml" "$r44/mid1.xml" filter-option-deity-any
drop_node "$r44/mid1.xml" "$r44/mid2.xml" "filter-option-deity-81 Yoginis"
drop_node "$r44/mid2.xml" "$r44/mid.xml" "filter-option-deity-Adinatha"
grep -q 'filter-option-deity-any\|filter-option-deity-81 Yoginis' "$r44/mid.xml" && { echo "fixture: mid-list sheet" >&2; exit 1; }
o="$(replay441 "$r44/mid.xml $r44/mid.xml $T44/17c_deity_select.xml" select_labeled '@first' DEITY)" &&
  [[ "$(grep -c '^SWIPE down$' <<<"$o")" == 2 ]] && grep -qx 'TAP 81 Yoginis; Gauri-Shankar (central shrine) 1' <<<"$o" && ! grep -q '^SEEK' <<<"$o" && ! grep -q 'TAP Ajitnatha' <<<"$o" ||
  { echo "4.4.1 @first on a mid-list sheet: swipe down to the head, then tap 81 Yoginis: $o" >&2; exit 1; }
# Never at the head: give up after FIRST_TOP_SWIPES, no tap.
o="$(FIRST_TOP_SWIPES=3 replay441 "$r44/mid.xml" select_labeled '@first' DEITY)" && { echo "4.4.1 @first with no list head must fail: $o" >&2; exit 1; }
[[ "$(grep -c '^SWIPE down$' <<<"$o")" == 3 ]] && ! grep -q 'tap in place' <<<"$o" || { echo "4.4.1 @first gives up after 3 fallback swipes, no option tap: $o" >&2; exit 1; }
# 2. filter-kept needs filter-clear (and the applied labels): chips alone fail.
fk() { ui_dump && filter_kept "$@"; }
replay44 "$T44/seq1_filter_kept.xml" fk 'state=Tamil Nadu' 'deity=Shiva' >/dev/null || { echo "4.4.1 filter_kept on r6 seq1 (Tamil Nadu off-row, Shiva)" >&2; exit 1; }
drop_node "$T44/seq1_filter_kept.xml" "$r44/chips_no_clear.xml" filter-clear
grep -q 'filter-chip-deity' "$r44/chips_no_clear.xml" && ! grep -q 'filter-clear' "$r44/chips_no_clear.xml" || { echo "fixture: chips without filter-clear" >&2; exit 1; }
replay44 "$r44/chips_no_clear.xml" fbp >/dev/null || { echo "fixture: the chip bar is still there" >&2; exit 1; }
o="$(replay44 "$r44/chips_no_clear.xml" fk 'deity=Shiva')" && { echo "4.4.1 filter_kept: chips with no filter-clear (filter lost) must fail: $o" >&2; exit 1; }
replay44 "$r44/chips_no_clear.xml" fk >/dev/null && { echo "4.4.1 filter_kept with no labels still needs filter-clear" >&2; exit 1; }
replay44 "$T44/seq1_filter_kept.xml" fk 'deity=Ganesha' >/dev/null && { echo "4.4.1 filter_kept: wrong deity label must fail" >&2; exit 1; }
replay44 "$T44/detail_no_filter_bar.xml" fk 'deity=Shiva' >/dev/null && { echo "4.4.1 filter_kept with no bar" >&2; exit 1; }
grep -q "identifier: 'filter-clear'" lib/*/directory_filter_bar.dart 2>/dev/null || find lib -name directory_filter_bar.dart -exec grep -q "identifier: 'filter-clear'" {} + || { echo "app: filter-clear id moved" >&2; exit 1; }
# do_action bookkeeping: select records, clear and a state change drop.
fdefs="$(python3 - <<'PY2'
import re
s = open("tool/emulator/flows/29_filter_matrix.sh").read()
for name in ("do_action", "applied_pairs"):
    m = re.search(r"(?ms)^%s\(\) \{.*?^\}" % name, s)
    print(m.group(0))
PY2
)"
o="$(bash -c "declare -A APPLIED=() PICK=() SECTION=(); scoped_pick() { echo x; }; open_chip() { :; }; apply_sheet() { :; }; close_x() { :; }; clear_named() { :; }
  select_labeled() { SELECTED_LABEL=\"L-\$CHIPN\"; }; $fdefs
  CHIPN=1 do_action deity select; CHIPN=2 do_action district select; CHIPN=3 do_action district pick-close; applied_pairs | sort; echo --
  CHIPN=4 do_action state select; applied_pairs | sort; echo --; do_action state clear; applied_pairs | sort")"
[[ "$o" == $'deity=L-1\ndistrict=L-2\n--\ndeity=L-1\nstate=L-4\n--\ndeity=L-1' ]] || { echo "4.4.1 do_action APPLIED bookkeeping: $o" >&2; exit 1; }
# 3. Boot retry RETRY line: written, shown by summarize, not counted twice.
d="$r44/bc"; rm -rf "$d"; mkdir -p "$d/emulator-app-test-artifacts"
chk441="$chk_sh"
( cd "$d" && PATH="$r44/bin:$PATH" STUB_DIR="$r44" GITHUB_OUTPUT="$d/out" bash -c "sleep() { :; }; $chk441" ) >/dev/null 2>&1
grep -qx 'retry=true' "$d/out" && grep -qx 'RETRY boot 7: no BOOT line after the first emulator start; ran the shard once more' "$d/emulator-app-test-artifacts/results.txt" ||
  { echo "4.4.1 boot-check writes a RETRY line: $(cat "$d/emulator-app-test-artifacts/results.txt" 2>&1)" >&2; exit 1; }
d="$r44/bc"; rm -rf "$d"; mkdir -p "$d/emulator-app-test-artifacts"; echo 'FAIL x: from the dead attempt' > "$d/emulator-app-test-artifacts/results.txt"
( cd "$d" && PATH="$r44/bin:$PATH" STUB_DIR="$r44" GITHUB_OUTPUT="$d/out" bash -c "sleep() { :; }; $chk441" ) >/dev/null 2>&1
grep -q '^FAIL x' "$d/emulator-app-test-artifacts/results-boot-death.txt" && ! grep -q '^FAIL' "$d/emulator-app-test-artifacts/results.txt" || { echo "4.4.1 dead attempt lines move out of results.txt" >&2; exit 1; }
sm="$r44/sm"; rm -rf "$sm"; mkdir -p "$sm"
{ echo 'RETRY boot 3: no BOOT line after the first emulator start; ran the shard once more'; echo 'BOOT full-3 snapshot'
  while read -r id; do echo "START $id"; echo "PASS $id: ok"; echo "DONE $id"; done < <(bash -c 'source tool/emulator/plan.sh; plan_ids full 3'); } > "$sm/results.txt"
o="$(EMULATOR_ARTIFACTS="$sm" EMULATOR_TIER=full EMULATOR_SHARD=3 GITHUB_STEP_SUMMARY="$sm/sum.md" bash tool/emulator/summarize.sh)" || { echo "4.4.1 summarize with a RETRY line must stay green: $o" >&2; exit 1; }
grep -q ', 0 failed, .*0 not run' <<<"$o" && grep -q '^RETRY (1):' <<<"$o" && grep -q '^#### Boot retries (RETRY: 1)' "$sm/sum.md" && grep -q '^- RETRY boot 3:' "$sm/sum.md" ||
  { echo "4.4.1 summarize lists RETRY, counts nothing: $o" >&2; exit 1; }
[[ "$(grep -c '^RETRY ' "$sm/results.txt")" == 1 ]] || { echo "4.4.1 summarize must not append RETRY lines" >&2; exit 1; }
{ echo 'RETRY boot 3: no BOOT line after the first emulator start; ran the shard once more'; bash -c 'source tool/emulator/plan.sh; plan_ids full' | while read -r id; do echo "PASS $id: ok"; done; } > "$sm/results.txt"
o="$(env -u GITHUB_STEP_SUMMARY EMULATOR_ARTIFACTS="$sm" bash tool/emulator/release_gate.sh full 0123456789abcdef0123456789abcdef01234567 build 2>&1)" &&
  grep -q '(1 boot retry: 3)$' <<<"$o" && ! grep -q 'NOT a release gate' <<<"$o" || { echo "4.4.1 release gate lists the retry and does not refuse it: $o" >&2; exit 1; }
# 4. (PR body only.) 5. Fixtures carry no ad-click ids, emails, tokens or device ids.
python3 tool/emulator/fixture_scan.py tool/emulator/testdata >"$r44/fscan" || { echo "4.4.1 fixture scan:" >&2; cat "$r44/fscan" >&2; exit 1; }
mkdir -p "$r44/fs"; for bad in 'content-desc="%3Fgclid%3DCj0KCQiAfake123"' 'a@b.co' 'ya29.a0AfH6SMBfakefake' 'android_id=0123456789abcdef' '356938035643809' 'ZX1G22ABCD	device'; do
  printf '%s\n' "$bad" > "$r44/fs/x.xml"; python3 tool/emulator/fixture_scan.py "$r44/fs" >/dev/null && { echo "4.4.1 fixture scan misses: $bad" >&2; exit 1; }
done
printf 'emulator-5554\tdevice\ngclid%%3DREDACTED\n' > "$r44/fs/x.xml"; python3 tool/emulator/fixture_scan.py "$r44/fs" >/dev/null || { echo "4.4.1 fixture scan: emulator-5554 and REDACTED are allowed" >&2; exit 1; }
echo "round 4.4.1 checks ok"
# Round 4.4.2 (review 54b55b7 + Manu's nits)
# @first head search pulls short (FIRST_TOP_SWIPE_PCT, default 12%).
o="$( ( export EMULATOR_FLOW=99-r442 EMULATOR_ARTIFACTS="$r44/art442" EMULATOR_PACKAGE=com.shradhaventures.temple
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh
  L=("$r44/mid.xml" "$T44/17c_deity_select.xml"); I=0
  ui_dump() { cp "${L[$I]}" "$DUMP"; }
  ui_sheet_swipe() { echo "SWIPE $*"; I=1; }
  ui_screen_size() { echo 320 640; }; ui_tap() { echo "TAP ${UI_TEXT:-}"; }; sleep() { :; }
  select_labeled '@first' DEITY ) 2>&1)"
grep -qx 'SWIPE down 58 12' <<<"$o" || { echo "4.4.2 @first head search uses a short pull: $o" >&2; exit 1; }
grep -q 'local travel_pct="${3:-}"' tool/emulator/lib/common.sh || { echo "4.4.2 ui_sheet_swipe takes a travel %" >&2; exit 1; }
# filter_kept scrolls the chip row when every expected chip is off it.
replay442() { # "fx..." fn...: each chip-row scroll moves to the next dump
  ( export EMULATOR_FLOW=99-r442 EMULATOR_ARTIFACTS="$r44/art442" EMULATOR_PACKAGE=com.shradhaventures.temple
    # shellcheck disable=SC1091
    source tool/emulator/lib/common.sh
    read -r -a L <<<"$1"; shift; I=0
    ui_dump() { cp "${L[$I]}" "$DUMP"; }
    scroll_chip_bar_at() { echo "CHIPSCROLL $*"; (( I + 1 < ${#L[@]} )) && I=$((I + 1)); return 0; }
    ui_screen_size() { echo 320 640; }; ui_tap() { echo "TAP ${UI_TEXT:-}"; }; sleep() { :; }
    fk2() { ui_dump && filter_kept "$@" && echo KEPT || echo "LOST ${FILTER_KEPT_WHY}"; }
    "$@" ) 2>&1
}
drop_node "$T44/seq1_filter_kept.xml" "$r44/off1.xml" filter-chip-deity
drop_node "$r44/off1.xml" "$r44/offrow.xml" filter-chip-district
grep -q 'filter-clear' "$r44/offrow.xml" && ! grep -q 'filter-chip-' "$r44/offrow.xml" || { echo "fixture: filter-clear with every chip off the row" >&2; exit 1; }
o="$(replay442 "$r44/offrow.xml $T44/seq1_filter_kept.xml" fk2 'deity=Shiva')"
grep -qx KEPT <<<"$o" && grep -q '^CHIPSCROLL' <<<"$o" || { echo "4.4.2 filter_kept scrolls to the deity chip and judges it: $o" >&2; exit 1; }
o="$(replay442 "$r44/offrow.xml $T44/seq1_filter_kept.xml" fk2 'deity=Ganesha')"
grep -q "^LOST deity chip shows 'Shiva', want 'Ganesha'" <<<"$o" || { echo "4.4.2 filter_kept: scrolled-to chip with the wrong label fails: $o" >&2; exit 1; }
o="$(replay442 "$r44/offrow.xml" fk2 'deity=Shiva')"
grep -q '^LOST no expected chip (deity) on the row after scrolling' <<<"$o" || { echo "4.4.2 filter_kept: filter-clear alone (no chip judged) fails: $o" >&2; exit 1; }
# Nothing applied: filter-clear must be absent (flow 29).
grep -q 'if none_applied_ok; then pass_step' tool/emulator/flows/29_filter_matrix.sh || { echo "4.4.2 flow 29 uses none_applied_ok when nothing is applied" >&2; exit 1; }
nao_def="$(python3 -c 'import re; s=open("tool/emulator/flows/29_filter_matrix.sh").read(); print(re.search(r"(?ms)^none_applied_ok\(\) \{.*?^\}", s).group(0))')"
eval "$nao_def"
fna() { ui_dump; if none_applied_ok; then echo OK; else echo "$FILTER_KEPT_WHY"; fi; }
[[ "$(replay44 "$r44/chips_no_clear.xml" fna)" == OK && "$(replay44 "$T44/seq1_filter_kept.xml" fna)" == "filter-clear shown with no filter applied" && "$(replay44 "$T44/detail_no_filter_bar.xml" fna)" == "filter bar missing after detail" ]] ||
  { echo "4.4.2 nothing-applied check: chips only OK, filter-clear fails, no bar fails" >&2; exit 1; }
# release_gate: a shard artifact without a BOOT line is a missing shard.
ms="$(mktemp -d)"; gate_clean_results "$ms"
sed -i '/^BOOT /d' "${ms}/shards/emulator-app-test-5/results.txt"
rc=0; g="$(EMULATOR_GATE_MODE=strict EMULATOR_SHARD_RESULTS="${ms}/shards" EMULATOR_ARTIFACTS="$ms" GITHUB_STEP_SUMMARY=/dev/null bash tool/emulator/release_gate.sh full "$gate_sha" build 2>&1)" || rc=$?
[[ "$rc" == 1 && "$g" == *"missing shard artifacts: 5 (need 15); no BOOT line (emulator died before run_shard.sh): 5"* ]] || { echo "4.4.2 gate: shard 5 without BOOT refused with the reason: rc=${rc} ${g}" >&2; exit 1; }
rm -rf "$ms"
# fixture_scan nits: =/&#61;, (?!REDACTED\b), %40, advertising id, hyphenated IMEI, Luhn.
for bad in 'gclid&#61;Cj0KCQiAfake12' 'gclid%3DREDACTEDx12345' 'a%40b.co' 'advertising_id: 38400000-8cf0-11bd-b23e-10b96e40000d' 'IMEI 35-693803-564380-9' '35-693803-564380-9' '490154203237518'; do
  printf '%s\n' "$bad" > "$r44/fs/x.xml"; python3 tool/emulator/fixture_scan.py "$r44/fs" >/dev/null && { echo "4.4.2 fixture scan misses: $bad" >&2; exit 1; }
done
for ok in 'gclid%3DREDACTED' 'adid=00000000-0000-0000-0000-000000000000' '490154203237519' 'bounds="[0,0][1700000000000,1]"'; do
  printf '%s\n' "$ok" > "$r44/fs/x.xml"; python3 tool/emulator/fixture_scan.py "$r44/fs" >/dev/null || { echo "4.4.2 fixture scan false positive: $ok" >&2; exit 1; }
done
echo "round 4.4.2 checks ok"
rm -rf "$r44"
rm -rf "$r4"
# Round 4.4.8 (run 41601153030, run126/r7/triage.md).
# A. The shim's capped action calls (keyevent 82, settings put) retry inside
# the same cap and never fail the action: "No service published for: input"
# right after a snapshot load killed shards 3 and 6 twice each.
r48="$(mktemp -d)"; mkdir -p "$r48/pt"
cat > "$r48/pt/adb" <<'ADB'
#!/usr/bin/env bash
n="$(cat "$STUB48/n" 2>/dev/null || echo 0)"; n=$((n + 1)); echo "$n" > "$STUB48/n"
case "$*" in
  *"input keyevent 82"*)
    if (( n <= ${STUB48_FAILS:-0} )); then echo "java.lang.IllegalStateException: android.os.ServiceManager\$ServiceNotFoundException: No service published for: input" >&2; exit 1; fi
    echo ok ;;
  *) echo pass ;;
esac
ADB
chmod +x "$r48/pt/adb"; bash tool/emulator/adb_shim/install.sh "$r48/pt" >/dev/null || { echo "4.4.8 shim install" >&2; exit 1; }
export STUB48="$r48"
for case48 in "0 0 1" "2 0 3" "99 0 x"; do
  read -r fails want_rc want_n <<<"$case48"
  echo 0 > "$r48/n"; t0=$SECONDS
  rc=0; o="$(STUB48_FAILS="$fails" EMULATOR_ACTION_ADB_S=5 "$r48/pt/adb" -s emulator-5554 shell input keyevent 82 2>&1)" || rc=$?
  el=$((SECONDS - t0)); n="$(cat "$r48/n")"
  [[ "$rc" == "$want_rc" ]] && (( el <= 6 )) || { echo "4.4.8 shim keyevent (fails=${fails}): rc ${rc} (want ${want_rc}) in ${el}s (<= 6): $o" >&2; exit 1; }
  if [[ "$want_n" != x ]]; then [[ "$n" == "$want_n" ]] || { echo "4.4.8 shim keyevent (fails=${fails}): ${n} calls, want ${want_n}" >&2; exit 1; }
  else (( n >= 3 )) && [[ "$o" == *"::warning::adb_shim: '-s emulator-5554 shell input keyevent 82' failed"* ]] || { echo "4.4.8 shim: a keyevent that keeps failing retries and warns, rc 0: n=${n} $o" >&2; exit 1; }; fi
done
echo "4.4.8 shim: keyevent 82 fails 0/2/always -> rc 0 within the 5s cap (retries, then a warning)"
unset STUB48
# B. 30s is five one-sequence flows (seqs:N), each runs only its sequence.
for k in 1 2 3 4 5; do
  o="$(FILTER_MATRIX_PART="seqs:$k" bash -c 'case "${FILTER_MATRIX_PART}" in seqs:[1-5]) echo "${FILTER_MATRIX_PART#seqs:}";; esac')"
  [[ "$o" == "$k" ]] || { echo "4.4.8 seqs:$k" >&2; exit 1; }
done
grep -q '\[\[ -n "${SEQ_ONLY:-}" && "$n" != "$SEQ_ONLY" \]\] && continue' tool/emulator/flows/29_filter_matrix.sh || { echo "4.4.8: the SEQS loop skips other sequences under seqs:N" >&2; exit 1; }
for k in 1 2 3 4 5; do [[ "$(bash -c 'source tool/emulator/plan.sh; plan_cap_s "30s'"$k"'-filter-matrix-seq'"$k"'"')" == 540 ]] || { echo "4.4.8: 30s$k cap 540s" >&2; exit 1; }; done
# C (4.4.8b). fresh_home: relaunch once ONLY on the GPU context-loss
# signature for the app pid with no crash/ANR; otherwise FAIL, no relaunch.
fh="$(mktemp -d)"
fh_case() { # name logcat-file -> prints results.txt, launches in $fh/<name>.n
  local name="$1" lc="$2"
  ( set +e
    FLOW=29x; PKG=com.shradhaventures.temple; RESULTS="$fh/$name.results"; : > "$RESULTS"; calls=0
    eval "$(sed -n '/^app_crashed_in_log() {/,/^}/p; /^record_fail() {/,/^}/p' tool/emulator/lib/common.sh)"
    step_reset() { :; }; STEP_TIMED_OUT=0
    logcat_window_start() { :; }
    logcat_window_read() { [[ "$lc" == unreadable ]] && return 3; cat "$lc"; }
    force_stop_app() { :; }; launch_app() { calls=$((calls + 1)); echo L >> "$fh/$name.n"; }
    accept_policy_if_shown() { (( calls >= 2 )); }; wait_for_home() { :; }
    eval "$(sed -n '/^fresh_home_once() {/,/^}/p; /^app_gpu_context_lost_in_log() {/,/^}/p; /^fresh_home() {/,/^}/p' tool/emulator/flows/29_filter_matrix.sh)"
    fresh_home >/dev/null 2>&1 && echo HOME || echo NOHOME
  ) > "$fh/$name.out"
}
P5='com.shradhaventures.temple'
printf '%s\n' "11-03 08:18:22.719   519   566 I ActivityManager: Start proc 5697:${P5}/u0a167 for pre-top-activity {${P5}/${P5}.MainActivity}" \
  "11-03 08:18:34.777  5697  5782 W OpenGLRenderer: Failed to make current on surface 0x7a1bea2461b0, error=EGL_BAD_CONTEXT" \
  "11-03 08:18:34.779  5697  5697 W OpenGLRenderer: Surface lost, forcing relayout" > "$fh/sig.txt"
{ cat "$fh/sig.txt"; printf '%s\n' "11-03 08:18:40.000  5697  5697 E AndroidRuntime: FATAL EXCEPTION: main" "11-03 08:18:40.000  5697  5697 E AndroidRuntime: Process: ${P5}, PID: 5697"; } > "$fh/fatal.txt"
{ cat "$fh/sig.txt"; echo "11-03 08:18:41.000   519   600 E ActivityManager: ANR in ${P5} (${P5}/.MainActivity)"; } > "$fh/anr.txt"
printf '%s\n' "11-03 08:18:22.719   519   566 I ActivityManager: Start proc 5697:${P5}/u0a167 for pre-top-activity" "11-03 08:18:30.000  5697  5697 I flutter: still on splash" > "$fh/nosig.txt"
# signature on ANOTHER process (system UI), not the app pid
printf '%s\n' "11-03 08:18:22.719   519   566 I ActivityManager: Start proc 5697:${P5}/u0a167 for pre-top-activity" "11-03 08:18:34.777   900   901 W OpenGLRenderer: Surface lost, forcing relayout" > "$fh/otherpid.txt"
fh_case sig "$fh/sig.txt"
[[ "$(cat "$fh/sig.out")" == HOME && "$(wc -l < "$fh/sig.n")" == 2 && "$(grep -c '^RELAUNCH 29x: fresh_home: home not reached, EGL context lost on com.shradhaventures.temple' "$fh/sig.results")" == 1 && "$(grep -c '^FAIL' "$fh/sig.results")" == 0 ]] ||
  { echo "4.4.8b fresh_home: GPU signature -> one relaunch + RELAUNCH line: $(cat "$fh/sig.out" "$fh/sig.results")" >&2; exit 1; }
for c in fatal:crashed anr:crashed nosig:"no GPU context-loss signature" otherpid:"no GPU context-loss signature" unreadable:"logcat unreadable"; do
  name="${c%%:*}"; want="${c#*:}"; lc="$fh/$name.txt"; [[ "$name" == unreadable ]] && lc=unreadable
  fh_case "$name" "$lc"
  [[ "$(cat "$fh/$name.out")" == NOHOME && "$(wc -l < "$fh/$name.n")" == 1 && "$(cat "$fh/$name.results")" == "FAIL 29x: fresh_home: "*"$want"* ]] && ! grep -q '^RELAUNCH' "$fh/$name.results" ||
    { echo "4.4.8b fresh_home ($name): FAIL, no relaunch: $(cat "$fh/$name.out" "$fh/$name.results")" >&2; exit 1; }
done
# The real 29e logcat (run 41601153030 shard 5) carries the signature on the app pid.
echo "4.4.8b fresh_home: signature -> 1 relaunch + RELAUNCH; FATAL/ANR/no signature/other pid/unreadable -> FAIL, 1 launch"
# D (4.4.8b). The gate reports RELAUNCH lines (count + ids), not as failures.
ms="$(mktemp -d)"; gate_clean_results "$ms"
echo "RELAUNCH 29e-filter-matrix-drawer-all-district: fresh_home: home not reached, EGL context lost on com.shradhaventures.temple (no crash/ANR); relaunched the app once" >> "$ms/results.txt"
rc=0; g="$(EMULATOR_GATE_MODE=strict EMULATOR_SHARD_RESULTS="${ms}/shards" EMULATOR_ARTIFACTS="$ms" GITHUB_STEP_SUMMARY="$ms/sum.md" \
  bash tool/emulator/release_gate.sh full "$gate_sha" build 2>&1)" || rc=$?
[[ "$rc" == 0 && "$g" == *"(1 app relaunch after GPU context loss: 29e-filter-matrix-drawer-all-district)"* && "$g" != *"NOT a release gate"* ]] &&
  grep -q '^- RELAUNCH 29e-filter-matrix-drawer-all-district:' "$ms/sum.md" ||
  { echo "4.4.8b gate must report RELAUNCH (count + ids) and still pass: rc=${rc} ${g}" >&2; exit 1; }
echo "4.4.8b gate: RELAUNCH reported (1, 29e), gate still passes"
# E (4.4.8b). Shim scope: only the action's exact keyevent 82 outside the
# harness is swallowed; harness/flow calls keep real exit codes, no retry.
r48b="$(mktemp -d)"; mkdir -p "$r48b/pt"
cat > "$r48b/pt/adb" <<'ADB'
#!/usr/bin/env bash
echo x >> "$STUB48B/n"; echo "No service published for: input" >&2; exit 1
ADB
chmod +x "$r48b/pt/adb"; bash tool/emulator/adb_shim/install.sh "$r48b/pt" >/dev/null
export STUB48B="$r48b"
for c in "harness|1|-s emulator-5554 shell input keyevent 82" "flow66||-s emulator-5554 shell input keyevent 66" \
         "flow123||-s emulator-5554 shell input keyevent 123" "noserial||shell input keyevent 82" "harness66|1|shell input keyevent 66" \
         "settings||-s emulator-5554 shell settings put global window_animation_scale 0.0" "extra||-s emulator-5554 shell input keyevent 82 x"; do
  IFS='|' read -r name henv argv <<<"$c"; rm -f "$r48b/n"; rc=0
  # shellcheck disable=SC2086
  env ${henv:+ADB_SHIM_HARNESS=1} EMULATOR_ACTION_ADB_S=5 "$r48b/pt/adb" $argv >/dev/null 2>&1 || rc=$?
  [[ "$rc" == 1 && "$(wc -l < "$r48b/n")" == 1 ]] || { echo "4.4.8b shim ($name: ${henv:+ADB_SHIM_HARNESS=1 }adb $argv): real rc 1, one call; got rc ${rc}, $(wc -l < "$r48b/n") calls" >&2; exit 1; }
done
grep -qx 'export ADB_SHIM_HARNESS=1' tool/emulator/run_shard.sh && grep -qx 'export ADB_SHIM_HARNESS=1' tool/emulator/run_one_flow.sh &&
  ! grep -q ADB_SHIM_HARNESS "$workflow" || { echo "4.4.8b: run_shard/run_one_flow export ADB_SHIM_HARNESS=1, the workflow never sets it" >&2; exit 1; }
unset STUB48B
echo "4.4.8b shim: harness/flow/non-exact keyevents and settings keep rc 1 with one call; only the action's keyevent 82 is swallowed"
# F (4.4.8b). Each 30sN missing -> strict gate refuses with that id NOT RUN.
for k in 1 2 3 4 5; do
  ms="$(mktemp -d)"; gate_clean_results "$ms"; id="30s${k}-filter-matrix-seq${k}"
  sed -i "/ ${id}\(:\|\$\)/d" "$ms/results.txt"
  rc=0; g="$(EMULATOR_GATE_MODE=strict EMULATOR_SHARD_RESULTS="${ms}/shards" EMULATOR_ARTIFACTS="$ms" GITHUB_STEP_SUMMARY=/dev/null \
    bash tool/emulator/release_gate.sh full "$gate_sha" build 2>&1)" || rc=$?
  [[ "$rc" == 1 && "$g" == *"1 NOT RUN (no result: ${id})"* ]] || { echo "4.4.8b: ${id} missing must refuse the gate (NOT RUN): rc=${rc} ${g}" >&2; exit 1; }
  echo "4.4.8b gate: ${id} missing -> rc 1, '1 NOT RUN (no result: ${id})'"
done
# Round 4.4.9: install retries ONCE, only on the exact "cmd: Can't find
# service: package" (run 41757362316), after a bounded services wait.
ri="$(mktemp -d)"; mkdir -p "$ri/bin"; : > "$ri/app.apk"
cat > "$ri/bin/adb" <<'ADB'
#!/usr/bin/env bash
echo "$*" >> "$RI/calls"
case "$*" in
  install\ *)
    n="$(cat "$RI/n" 2>/dev/null || echo 0)"; n=$((n + 1)); echo "$n" > "$RI/n"
    r="$(sed -n "${n}p" "$RI/plan")"
    case "$r" in
      ok) echo "Performing Streamed Install"; echo "Success" ;;
      nopkg) echo "Performing Streamed Install"; echo "adb.real: failed to install $RI/app.apk: cmd: Can't find service: package" >&2; exit 1 ;;
      other) echo "adb: failed to install $RI/app.apk: Failure [INSTALL_FAILED_INSUFFICIENT_STORAGE]" >&2; exit 1 ;;
    esac ;;
  *"service check "*) echo "Service ${*##* }: found" ;;
  *"pm path android"*) echo "package:/system/framework/framework-res.apk" ;;
  *"getprop sys.boot_completed"*) echo 1 ;;
  *) : ;;
esac
ADB
chmod +x "$ri/bin/adb"
inst_case() { # plan... -> "rc installs services-checks"
  printf '%s\n' "$@" > "$ri/plan"; rm -f "$ri/n" "$ri/calls"; mkdir -p "$ri/art"; : > "$ri/art/results.txt"
  local rc=0
  RI="$ri" PATH="$ri/bin:$PATH" EMULATOR_FLOW=inst EMULATOR_ARTIFACTS="$ri/art" EMULATOR_APK="$ri/app.apk" EMULATOR_SERVICES_POLL_S=0 \
    EMULATOR_INSTALL_SERVICES_WAIT_S=3 bash -c 'source tool/emulator/lib/common.sh >/dev/null 2>&1; install_apk' >/dev/null 2>&1 || rc=$?
  echo "$rc $(grep -c '^install ' "$ri/calls") $(grep -c 'service check input' "$ri/calls")"
}
[[ "$(inst_case nopkg ok)" == "0 2 1" ]] || { echo "4.4.9 install: 'Can't find service: package' once -> services wait, one retry, success: $(inst_case nopkg ok)" >&2; exit 1; }
[[ "$(inst_case nopkg nopkg ok)" == "1 2 1" ]] && grep -q "^FAIL inst: install: adb install failed: .*Can't find service: package" "$ri/art/results.txt" ||
  { echo "4.4.9 install: the retry is ONCE (second 'Can't find service: package' fails)" >&2; exit 1; }
[[ "$(inst_case other ok)" == "1 1 0" ]] && grep -q "^FAIL inst: install: adb install failed: .*INSUFFICIENT_STORAGE" "$ri/art/results.txt" ||
  { echo "4.4.9 install: any other install error is not retried and waits for nothing: $(inst_case other ok)" >&2; exit 1; }
[[ "$(inst_case ok)" == "0 1 0" ]] || { echo "4.4.9 install: a clean install runs once" >&2; exit 1; }
echo "4.4.9 install: package-service error once -> wait + 1 retry -> ok; twice -> FAIL; other error -> FAIL, no retry"
# Round 4.4.9b: the effective per-flow cap is in the logs. Run 41757362316
# printed "cap 600s each" on shards 11/15/9 although 30s1-5 ran at 540s
# (EMULATOR_FLOW_BUDGET); the header and group now print the row cap,
# run_one_flow writes CAP <id> <s> and the flow's timeout uses it.
cp_dir="$(mktemp -d)"; mk_ready_adb "$cp_dir/bin" 1
printf '#!/bin/sh\necho "$1 $EMULATOR_FLOW_BUDGET" >> "$CP_LOG"\n' > "$cp_dir/runner.sh"; chmod +x "$cp_dir/runner.sh"
CP_LOG="$cp_dir/budgets" PATH="$cp_dir/bin:$PATH" EMULATOR_FLOW_RUNNER="$cp_dir/runner.sh" EMULATOR_ARTIFACTS="$cp_dir/art" \
  bash tool/emulator/run_shard.sh full 11 > "$cp_dir/out" 2>&1
grep -q 'caps: 30g1-filter-matrix-search-deity=450s 30g2-filter-matrix-search-deity=450s 30s2-filter-matrix-seq2=540s 19-rotation-state=300s, worst case 2129s' "$cp_dir/out" &&
  grep -qx '::group::Flow 30s2-filter-matrix-seq2 (cap 540s)' "$cp_dir/out" && ! grep -q 'cap 600s each' "$cp_dir/out" &&
  grep -qx '30g1-filter-matrix-search-deity 450' "$cp_dir/budgets" && grep -qx '30s2-filter-matrix-seq2 540' "$cp_dir/budgets" ||
  { echo "4.4.9b: shard 11 must log the row caps: $(head -3 "$cp_dir/out"; cat "$cp_dir/budgets")" >&2; exit 1; }
for want in "30s3-filter-matrix-seq3 540 540" "06a1-filters-single 400 400" "30s1-filter-matrix-seq1 900 600"; do
  read -r fid fb fwant <<<"$want"; rm -rf "$cp_dir/a1"; mkdir -p "$cp_dir/a1"
  EMULATOR_FLOW_BUDGET="$fb" EMULATOR_ARTIFACTS="$cp_dir/a1" PATH="$cp_dir/bin:$PATH" EMULATOR_APK=/nonexistent \
    timeout 60 bash tool/emulator/run_one_flow.sh "$fid" "tool/emulator/flows/29_filter_matrix.sh" > "$cp_dir/one.out" 2>&1
  grep -qx "CAP ${fid} ${fwant}s" "$cp_dir/a1/results.txt" && grep -q "flow ${fid}: budget ${fwant}s" "$cp_dir/one.out" ||
    { echo "4.4.9b run_one_flow: EMULATOR_FLOW_BUDGET=${fb} -> CAP ${fwant}s: $(cat "$cp_dir/a1/results.txt")" >&2; exit 1; }
done
echo "4.4.9b caps: shard 11 header/group/runner 540s for 30s1-2; run_one_flow CAP 540 (30s3), 600 (06a), 900 clamped to 600"
# Round 4.4.9c (Manu nit 1): only the boot-retry step cold-boots
# (-no-snapshot-load); every other emulator step keeps the plain options.
python3 - "$workflow" <<'PY' || { echo "4.4.9c: -no-snapshot-load on the boot retry step only" >&2; exit 1; }
import re, sys
steps = re.split(r"\n      - name: ", open(sys.argv[1]).read())
opts = [(s.split("\n", 1)[0], re.findall(r"emulator-options: (.*)", s)) for s in steps if "emulator-options:" in s]
retry = [v for k, v in opts if k == "Run emulator flows (boot retry)"]
ok = len(opts) == 4 and retry == [["${{ env.EMULATOR_OPTIONS }} -no-snapshot-load"]]
ok &= all(v == ["${{ env.EMULATOR_OPTIONS }}"] for k, v in opts if k != "Run emulator flows (boot retry)")
sys.exit(0 if ok else 1)
PY
echo "4.4.9c: boot retry cold-boots (-no-snapshot-load) within the 50s retry wait; other emulator steps unchanged"
# Round 4.4.9c (Reviewer 1): with the cold-boot retry, the retry paths keep
# the 50s retry boot wait and stay within budget (<= 2640 retry, <= 2700 all,
# >= 10s margin on the longest).
read -r _ q_retry _ q_cretry _ q_rretry q_cf _ < <(bash -c 'source tool/emulator/plan.sh; plan_e2e_s')
(( q_retry <= 2640 && q_cretry <= 2690 && q_rretry <= 2690 && q_cf <= 2690 )) &&
  [[ "$(bash -c 'source tool/emulator/plan.sh; echo "$SHARD_RETRY_BOOT_S"')" == 50 ]] ||
  { echo "4.4.9c: cold-boot retry paths over budget: retry ${q_retry} cold+retry ${q_cretry} refused+retry ${q_rretry} create failed+retry ${q_cf}" >&2; exit 1; }
echo "4.4.9c: retry paths ${q_retry}/${q_cretry}/${q_rretry}/${q_cf}s with the 50s cold-boot retry wait (<= 2700 - 10)"
# Round 4.4.9c (Reviewer 2): adb install is bounded.
grep -q 'timeout --kill-after=5 "${EMULATOR_INSTALL_S:-120}" adb install -r -d "$EMULATOR_APK" 2>&1' tool/emulator/lib/common.sh ||
  { echo "4.4.9c: install_once must be bounded (120s + 5s)" >&2; exit 1; }
(( 2 * 125 + 12 <= $(bash -c 'source tool/emulator/plan.sh; for i in $(plan_ids full); do plan_is_skipped "$i" || plan_cap_s "$i"; done' | sort -n | head -1) )) ||
  { echo "4.4.9c: two bounded installs + services wait must fit the smallest flow cap" >&2; exit 1; }
hd="$(mktemp -d)"; mkdir -p "$hd/bin"; printf '#!/bin/sh\n[ "$1" = install ] && exec sleep 39.5\nexit 0\n' > "$hd/bin/adb"; chmod +x "$hd/bin/adb"; : > "$hd/app.apk"
t0=$SECONDS; rc=0
PATH="$hd/bin:$PATH" EMULATOR_FLOW=inst EMULATOR_ARTIFACTS="$hd/art" EMULATOR_APK="$hd/app.apk" EMULATOR_INSTALL_S=1 \
  bash -c 'source tool/emulator/lib/common.sh >/dev/null 2>&1; install_apk' >/dev/null 2>&1 || rc=$?
(( rc != 0 && SECONDS - t0 <= 8 )) && grep -q '^FAIL inst: install: adb install failed' "$hd/art/results.txt" && ! pgrep -f 'sleep 39.5' >/dev/null ||
  { echo "4.4.9c: a hung adb install must fail within its bound (rc=$rc $((SECONDS - t0))s)" >&2; pkill -f 'sleep 39.5'; exit 1; }
echo "4.4.9c install: a hung adb install fails within EMULATOR_INSTALL_S, no retry"
# Round 4.4.9d: package-service retry then UPDATE_INCOMPATIBLE -> FAIL after
# exactly 2 installs; without the retry, UPDATE_INCOMPATIBLE still reinstalls.
ud="$(mktemp -d)"; mkdir -p "$ud/bin"; : > "$ud/app.apk"
cat > "$ud/bin/adb" <<'ADB'
#!/bin/bash
[[ "$1" == install ]] || exit 0
n=$(( $(cat "$UD/n" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$UD/n"
r="$(sed -n "${n}p" "$UD/script")"
case "$r" in svc) echo "cmd: Can't find service: package"; exit 1;;
  inc) echo "Failure [INSTALL_FAILED_UPDATE_INCOMPATIBLE: x]"; exit 1;; *) echo Success;; esac
ADB
chmod +x "$ud/bin/adb"; printf '#!/bin/sh\nexit 0\n' > "$ud/svc.sh"
inst_case() { rm -f "$ud/n" "$ud/art/results.txt"; printf '%s\n' "$@" > "$ud/script"; local rc=0
  UD="$ud" PATH="$ud/bin:$PATH" EMULATOR_FLOW=inst EMULATOR_ARTIFACTS="$ud/art" EMULATOR_APK="$ud/app.apk" EMULATOR_INSTALL_SERVICES_WAIT_S=1 \
    bash -c 'source tool/emulator/lib/common.sh >/dev/null 2>&1; install_apk' >/dev/null 2>&1 || rc=$?; echo "$rc $(cat "$ud/n")"; }
if ! { [[ "$(inst_case svc inc ok)" == "1 2" ]] && grep -q '^FAIL inst: install: adb install failed' "$ud/art/results.txt"; }; then
  echo "4.4.9d: retry + UPDATE_INCOMPATIBLE must FAIL after exactly 2 installs" >&2; exit 1
fi
[[ "$(inst_case inc ok)" == "0 2" ]] || { echo "4.4.9d: plain UPDATE_INCOMPATIBLE must still uninstall+reinstall" >&2; exit 1; }
rm -rf "$ud"
echo "4.4.9d install: retry then UPDATE_INCOMPATIBLE -> FAIL (2 installs); plain UPDATE_INCOMPATIBLE -> reinstall ok"
echo "round 4.4.8 checks ok"

# --- PR 124 r7: wrappers stay on the tree and drive main's KAN-198 matrix.
echo "PR 124 r7: 29a-29m / 30a-30d wrappers + 29h/29m action split"
for slice in 29a 29b 29c 29d 29e 29f 29g 29h 29i 29j 29k 29l 29m 30a 30b 30c 30d; do
  matches=(tool/emulator/flows/${slice}_*.sh)
  if [[ ! -f "${matches[0]}" ]]; then
    echo "missing PR 124 wrapper tool/emulator/flows/${slice}_*.sh" >&2
    exit 1
  fi
done
if ! grep -q 'MATRIX_ACTIONS="select pick-close dismiss-empty"' tool/emulator/flows/29h_search_district.sh; then
  echo "29h must keep the first three search x district actions" >&2; exit 1
fi
if ! grep -q 'MATRIX_ACTIONS="back-empty outside-empty clear"' tool/emulator/flows/29m_search_district_rest.sh; then
  echo "29m must keep the last three search x district actions" >&2; exit 1
fi
if ! grep -q 'source ".*/29_filter_matrix.sh"' tool/emulator/flows/lib/filter_matrix.sh &&
   ! grep -q 'source "${_matrix_dir}/../29_filter_matrix.sh"' tool/emulator/flows/lib/filter_matrix.sh; then
  echo "filter_matrix.sh must source 29_filter_matrix.sh" >&2; exit 1
fi
if ! grep -q 'filter_matrix.sh' tool/emulator/flows/lib/filter_matrix_b.sh; then
  echo "filter_matrix_b.sh must source filter_matrix.sh" >&2; exit 1
fi
# District cells still force "choose a state first" (r6 / 30b prefix).
if ! grep -q 'finish_choose_state_first' tool/emulator/flows/29_filter_matrix.sh; then
  echo "29_filter_matrix.sh must call finish_choose_state_first for district" >&2; exit 1
fi
# Chip-off-screen: find_filter_chip in chip_present (r6 / 22 / 29k).
if ! grep -q 'find_filter_chip filter-chip-state' tool/emulator/flows/29_filter_matrix.sh; then
  echo "29_filter_matrix.sh must scroll to chips via find_filter_chip" >&2; exit 1
fi
# CI plans the same cells as 29m under the 30f2 id (shard budget).
if ! grep -q 'search:district:2' tool/emulator/plan.sh; then
  echo "plan.sh must include search x district half 2 (30f2 / 29m)" >&2; exit 1
fi
echo "PR 124 r7 wrapper checks ok"

echo "emulator self-test ok"
