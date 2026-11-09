#!/usr/bin/env bash
# Which emulator flows run in which tier and shard (Confluence 12353537).
#
#   smoke  six flows, one job, on non-draft pull requests (path-filtered)
#   full   every flow, fifteen parallel shards (SHARD_COUNT), on workflow_dispatch and
#          when a release or pre-release is published
#   all    every flow in one sequential list (local runs, summary job)
#
# Usage:
#   plan.sh flows <smoke|full|all> [shard]   rows "id script part"
#   plan.sh ids <smoke|full|all> [shard]     flow ids only
#   plan.sh matrix <smoke|full>              JSON list for strategy.matrix
#   plan.sh need-minutes <smoke|full> [shard] worst-case emulator step minutes
#
# Sourcing this file defines the constants and functions without output.
set -uo pipefail

# Per-flow cap. run_one_flow.sh holds the same number as FLOW_BUDGET.
FLOW_CAP_S=600
FLOW_KILL_AFTER_S=15
# Device reset, pm clear, and the FAIL write around each flow. Run
# 41373837994 (28 flows in 7 job logs): group start -> "installed" (reset +
# pm clear) max 4.9s (median 2.0s), last line -> group end (logcat pull,
# FAIL write, incl. the 600s-timeout flows) max 6.8s: <= 12s. 30s keeps
# 2.5x headroom; every flow still gets reset_device_state + pm clear.
# Round 4.4.9b (architect: >= 10s margin on create failed + retry): 25s,
# still 2.1x the 12s measured maximum; the 4.4.9 install retry (services
# wait + install) runs inside the flow's own cap, not in this allowance.
FLOW_RESET_S=25
# run_shard.sh's outer "timeout --kill-after" on top of the flow guard
# (round 4.3.1: counted in plan_need_s).
FLOW_OUTER_KILL_S=10
# One snapshot boot per job (emulator-boot-timeout, workflow
# EMULATOR_BOOT_TIMEOUT). Round 4.4.2: 150s, Manu's floor (81 boots, the
# slowest ~33.7s; cold boots 28-34s, snapshot loads ~6s).
SHARD_BOOT_S=150
# Round 4.4: after boot, run_shard.sh waits for the system services
# (services_ready.sh) and unlocks with keyevent 82 (never fatal).
# Round 4.4.2: 3 tries of <= 3s, 2s apart (3 x 3 + 2 x 2 = 13s). Round
# 4.4.3: readiness 20s + 2s kill-after. The snapshot is saved only after
# the same readiness check, so a warm boot is ready within seconds (r6
# deaths came ~6s after the snapshot load). boot + ready + unlock = 185s.
# Round 4.4.9: the readiness wait runs before the BOOT line and decides a
# dead boot (run 41757362316). 22 healthy boots in runs 41601153030 and
# 41757362316 were ready on poll 1 in <= 1s; the 6 broken ones were never
# ready in 20s. 10s (4 polls) + 2s kill-after = 12s.
SHARD_READY_S=12
# Round 4.4.6 (Satyavrat): 2 tries (2 x 3 + 1 x 2 = 8s).
SHARD_UNLOCK_TRIES=2
SHARD_UNLOCK_S=$((SHARD_UNLOCK_TRIES * 3 + (SHARD_UNLOCK_TRIES - 1) * 2))
# Round 4.4.2: job budget with the boot retry. A dead first attempt (no
# BOOT line) costs at most the action start (SHARD_ACTION_START_S) plus
# boot + ready + unlock; then the boot-death check step and the retry
# flows step (same cap as the flow step). JOB_SETUP_POST_MIN is the setup
# + post-step allowance the job timeout already keeps (step + 20).
# shellcheck disable=SC2034 # read by self_test.sh (job budget)
SHARD_ACTION_START_S=30
# Round 4.4.3: a retried (dead) attempt has no BOOT line. Either the
# action died while booting (action start + boot), or run_shard.sh did
# not reach the BOOT line within SHARD_PREBOOT_S and its watchdog ended
# the attempt (Manu). The getprop just before BOOT is capped at
# SHARD_GETPROP_S. Round 4.4.4: only that getprop runs before BOOT, and
# the action's keyevent is capped (adb_shim). Dead attempt = action start
# 30 + boot 150 + action adb 5 + pre-BOOT watchdog 10 = 195s.
# shellcheck disable=SC2034 # read by self_test.sh (job budget)
SHARD_GETPROP_S=5
# shellcheck disable=SC2034 # read by run_shard.sh and self_test.sh
# Round 4.4.9: pre-BOOT = capped getprop (SHARD_GETPROP_S 5) + readiness
# (SHARD_READY_S 12) + 5s margin = 22s.
SHARD_PREBOOT_S=22
# Round 4.4.4: the action's own adb calls (keyevent 82; disable-animations
# is off, so no settings put) go through tool/emulator/adb_shim, capped at
# SHARD_ACTION_ADB_S each. Animations are turned off in one capped call
# (SHARD_ANIM_S) by snapshot_create.sh and run_shard.sh.
# shellcheck disable=SC2034 # read by run_shard.sh, snapshot_create.sh, self_test.sh
SHARD_ACTION_ADB_S=5 SHARD_ANIM_S=5
# shellcheck disable=SC2034 # read by run_shard.sh and snapshot_create.sh
ANIM_OFF_CMD="settings put global window_animation_scale 0.0; settings put global transition_animation_scale 0.0; settings put global animator_duration_scale 0.0"
# Round 4.4.4 (Satyavrat): both "Create AVD snapshot" steps boot cold with
# EMULATOR_CREATE_BOOT_TIMEOUT (was 600): 120s is 3.6x the slowest cold boot
# (33.7s of 81). The warm-up waits at most 60s for services
# (EMULATOR_SNAPSHOT_READY_S) and settles 10s; a shard's own fallback
# snapshot waits 20s and settles 5s (SHARD_CREATE_*), save ~5s.
# shellcheck disable=SC2034 # read by self_test.sh
# Round 4.4.5 (Manu nit 1): the shard's own snapshot (warm-up refused) boots
# with 60s (workflow EMULATOR_SHARD_CREATE_BOOT_TIMEOUT, = the retry boot
# wait), waits 12s for services and settles 3s: 30 + 60 + 5 + 5 + 12 + 3 + 5
# = 120s, the step cap (SHARD_CREATE_STEP_MIN 2), so the refused + boot-death
# path fits 2700s and the job budget counts that step. The warm-up keeps 120s
# (WARMUP_CREATE_BOOT_S, EMULATOR_CREATE_BOOT_TIMEOUT).
# shellcheck disable=SC2034 # read by self_test.sh
WARMUP_CREATE_BOOT_S=120 SHARD_CREATE_BOOT_S=50 WARMUP_READY_S=60 WARMUP_SETTLE_S=10 SHARD_CREATE_READY_S=12 SHARD_CREATE_SETTLE_S=3 SNAPSHOT_SAVE_S=5 SHARD_CREATE_STEP_MIN=2
# Round 4.4.6: the shard create is cut at SHARD_CREATE_DEADLINE_S (90s, from
# the mark step; snapshot_create.sh) since GitHub truncates a fractional
# timeout-minutes; the step cap (2 min) stays the hard backstop. The warn
# step after a failed create stops the emulator in <= 5s + 1 (E2E_WARN_S).
# Every action boot can spend SHARD_GETPROP_BUDGET_S (4s) in its
# "getprop sys.boot_completed" calls (adb_shim budget) on top of its boot wait.
# shellcheck disable=SC2034 # read by self_test.sh
SHARD_CREATE_DEADLINE_S=90 E2E_WARN_S=6 SHARD_GETPROP_BUDGET_S=4
# Round 4.4.6 (Reviewer): every adb call the harness makes outside the flows
# runs under a timeout (self_test scans run_shard, services_ready,
# prepare_avd, snapshot_create, create_warn and the boot-death check); the
# action's own keyevent/settings and boot getprops go through adb_shim. Flow
# adb calls are bounded by their per-flow cap.
# snapshot_create.sh: setprop <= 3s, snapshot save <= 10s. The warm-up's
# measured base (E2E_WARMUP_BASE_S 102) already holds one ~5s save
# (SNAPSHOT_SAVE_S), so the warm-up adds setprop 3 + (10 - 5). The shard
# create is cut at its 90s deadline whatever these sum to. prepare_avd.sh's
# "adb emu kill" (<= 5s + 1) runs inside the action start
# (SHARD_ACTION_START_S, measured with that kill returning at once: no
# emulator is up yet); the boot-death check's kill + wait share
# E2E_BOOT_CHECK_S (5s).
# shellcheck disable=SC2034 # read by snapshot_create.sh and self_test.sh
SNAPSHOT_SETPROP_S=3 SNAPSHOT_SAVE_CAP_S=10 PREP_KILL_S=6
# Round 4.4.3 (Satyavrat): the retry attempt's boot wait (workflow
# EMULATOR_RETRY_BOOT_TIMEOUT). It restores the snapshot (~6s); 60s is 10x
# that and ~1.8x the slowest cold boot (33.7s). The first attempt keeps
# SHARD_BOOT_S.
# Round 4.4.6 (Satyavrat): 50s (1.5x the slowest cold boot); the shard
# create boot follows it (SHARD_CREATE_BOOT_S).
SHARD_RETRY_BOOT_S=50
# Round 4.4.3: end-to-end model (seconds), from run 41391038302 step times:
# gate 6, build 264, shard setup 42, shard post + summary job 42; the
# avd-warmup job on a cold cache is 102s + its cold boot
# (SHARD_CREATE_BOOT_S) + keyevent/animations + readiness (60) and settle (10); the boot-death
# check is kill + wait-for-disconnect (<= 5s). Every path <= 2700s
# (Sanu, 45 min); the boot-retry path <= 2640s (Satyavrat, 44.0 min).
# shellcheck disable=SC2034 # read by self_test.sh
E2E_GATE_S=6 E2E_BUILD_S=264 E2E_SETUP_S=42 E2E_POST_S=42 E2E_WARMUP_BASE_S=102 E2E_BOOT_CHECK_S=5
# shellcheck disable=SC2034 # read by self_test.sh (job budget)
JOB_SETUP_POST_MIN=20
# One variable: matrix, need-minutes, run_shard.sh and self_test follow it.
SHARD_COUNT=15
# The limit is the worst case, not a flow count (round 4.3.1). Per flow:
# cap + kill-after 15 + reset 30 + outer kill-after 10. Shard 12 holds 4
# Round 4.4.3 (Sanu: 45 min on every path, incl. the boot retry): 26 and
# 08 (300s row caps) moved off shard 12 onto a 15th shard. Round 4.4.4:
# boot 150 + action keyevent 5 + getprop 5 + ready 22 + unlock 13 +
# animations 5 = 200s; round 4.4.6: + boot getprop budget 4, unlock 8 =
# 199s; round 4.4.9: readiness 12s (before BOOT) = 189s:
# round 4.4.9b: per flow cap + 15 + 25 reset + 10 = cap + 50:
# shard 12: 189 + 2 x (600 + 50) + (300 + 50) = 1839s (06a, 06b, 31);
# shard 15: 189 + 2 x (300 + 50) + 2 x (540 + 50) = 2069s (round 4.4.8:
#   26, 08, 30s3, 30s4); shard 11: 189 + 2 x 350 + 2 x 590 = 2069s;
#   shard 9: 189 + 650 + 2 x 350 + 590 = 2129s;
# every other shard: 189 + 3 x 650 = 2139s = 35.65 min. All <= 39 min,
# step timeout 42 (self_test checks every shard against 39 min).
# shellcheck disable=SC2034 # read by self_test.sh (sources this file)
SHARD_WORST_MAX_S=$((39 * 60))

SMOKE_FLOWS="01-first-launch 04-home 05-search 08-list-detail 14-back-relaunch 15-offline"

# Location-dependent flows are skipped on the emulator (decision of
# 2026-10-30): they need a GPS fix and Settings round-trips. 30d-near-me
# is listed for the split filter matrix; it is a no-op until that flow
# exists. They report SKIPPED, which is neither a pass nor a failure.
# EMULATOR_SKIP_FLOWS="" runs them.
DEFAULT_SKIP_FLOWS="11-near-me 23-near-me-settings-roundtrip 30d-near-me"
# Steps allowed to report NA ("<flow>:<step>") on the strict release gate.
# Empty: every NA (e.g. 24 multi-photo on a single-photo temple) blocks a
# release until it is fixed or deliberately listed here.
# shellcheck disable=SC2034 # read by release_gate.sh (sources this file)
DEFAULT_NA_STEPS=""

# id|script|FILTER_MATRIX_PART|shard[|cap seconds, <= FLOW_CAP_S]
# The optional 5th field lowers one flow's cap (run_one_flow.sh
# EMULATOR_FLOW_BUDGET). Round 4.3: 26 and 08 (96s and 105s in run
# 41391038302) get 300s, so 06 can split into 06a/06b in shard 12.
# Balanced by worst-case time (Satyavrat, round 4.2): every active flow
# can take 645s, so each shard holds at most 3 active flows. 20 "long"
# flows (measured at or near the 600s cap in run 41373837994, or matrix
# parts of those: 17a-d, 29a-f, 30a-c/e-g, 30s1-5, 06, 21, 22) and 22 short
# ones: shards 1-6 run 2 long + 1 short, shards 7-14 run 1 long + 2 short,
# with the slowest short flows (14, 27, 24, 18, 19, 26, 25) in 7-14.
# Round 4.4.3: shard 15 holds 26 and 08 (300s caps), off shard 12.
# Round 4.4.8 (run 41601153030): 30s (5 sequences, 600s cap) ran out of time
# after ~2.5 sequences (seq1 260s, seq2 226s); it is now 30s1-30s5
# (FILTER_MATRIX_PART=seqs:N, 540s cap each) on shards 11, 11, 15, 15, 9;
# 19, 20, 24 and 15 (observed max 94/53/137/38s) drop to 300s caps there.
# 17 is split per entry point (17a-17d), and the filter matrix runs one
# entry x one chip per flow (FILTER_MATRIX_PART=<entry>:<chip>, "seqs" for
# the 3+ step sequences). Planned skips (11, 23, 30d) cost nothing.
PLAN_ROWS=(
  "17a-entry-matrix-home-button|tool/emulator/flows/17_entry_matrix.sh|home_button|1"
  "29a-filter-matrix-home-state|tool/emulator/flows/29_filter_matrix.sh|home_browse:state|1"
  "01-first-launch|tool/emulator/flows/01_first_launch.sh||1"
  "17b-entry-matrix-drawer-all|tool/emulator/flows/17_entry_matrix.sh|drawer_all|2"
  "29b-filter-matrix-home-district|tool/emulator/flows/29_filter_matrix.sh|home_browse:district|2"
  "02-policy-gate|tool/emulator/flows/02_policy_gate.sh||2"
  "17c-entry-matrix-drawer-search|tool/emulator/flows/17_entry_matrix.sh|drawer_search|3"
  "29c-filter-matrix-home-deity|tool/emulator/flows/29_filter_matrix.sh|home_browse:deity|3"
  "03-force-update|tool/emulator/flows/03_force_update.sh||3"
  "11-near-me|tool/emulator/flows/11_near_me.sh||3"
  "17d-entry-matrix-list-drawer-all|tool/emulator/flows/17_entry_matrix.sh|list_drawer_all|4"
  "29d-filter-matrix-drawer-all-state|tool/emulator/flows/29_filter_matrix.sh|drawer_all:state|4"
  "04-home|tool/emulator/flows/04_home.sh||4"
  "29e-filter-matrix-drawer-all-district|tool/emulator/flows/29_filter_matrix.sh|drawer_all:district|5"
  "29f-filter-matrix-drawer-all-deity|tool/emulator/flows/29_filter_matrix.sh|drawer_all:deity|5"
  "05-search|tool/emulator/flows/05_search.sh||5"
  "30a-filter-matrix-drawer-bar-state|tool/emulator/flows/29_filter_matrix.sh|drawer_bar:state|6"
  "30b-filter-matrix-drawer-bar-district|tool/emulator/flows/29_filter_matrix.sh|drawer_bar:district|6"
  "07-district|tool/emulator/flows/07_district.sh||6"
  "23-near-me-settings-roundtrip|tool/emulator/flows/23_near_me_settings_roundtrip.sh||6"
  "30c-filter-matrix-drawer-bar-deity|tool/emulator/flows/29_filter_matrix.sh|drawer_bar:deity|7"
  "14-back-relaunch|tool/emulator/flows/14_back_relaunch.sh||7"
  "12-ads|tool/emulator/flows/12_ads.sh||7"
  "30e-filter-matrix-search-state|tool/emulator/flows/29_filter_matrix.sh|search:state|8"
  "27-offline-cold-start|tool/emulator/flows/27_offline_cold_start.sh||8"
  "13-licences|tool/emulator/flows/13_licences.sh||8"
  "30f-filter-matrix-search-district|tool/emulator/flows/29_filter_matrix.sh|search:district|9"
  "24-gallery-autoadvance-viewer|tool/emulator/flows/24_gallery_autoadvance_viewer.sh||9|300"
  "15-offline|tool/emulator/flows/15_offline.sh||9|300"
  "30s5-filter-matrix-seq5|tool/emulator/flows/29_filter_matrix.sh|seqs:5|9|540"
  "30g-filter-matrix-search-deity|tool/emulator/flows/29_filter_matrix.sh|search:deity|10"
  "18-home-reselect|tool/emulator/flows/18_home_reselect.sh||10"
  "16-home-browse|tool/emulator/flows/16_home_browse.sh||10"
  "19-rotation-state|tool/emulator/flows/19_rotation_state.sh||11|300"
  "20-empty-and-back|tool/emulator/flows/20_empty_and_back.sh||11|300"
  "30s1-filter-matrix-seq1|tool/emulator/flows/29_filter_matrix.sh|seqs:1|11|540"
  "30s2-filter-matrix-seq2|tool/emulator/flows/29_filter_matrix.sh|seqs:2|11|540"
  "06a-filters-single|tool/emulator/flows/06_filters.sh|single|12"
  "06b-filters-combined|tool/emulator/flows/06_filters.sh|combined|12"
  "31-filter-chain|tool/emulator/flows/31_filter_chain.sh||12|300"
  "26-drawer-nav-stack|tool/emulator/flows/26_drawer_nav_stack.sh||15|300"
  "08-list-detail|tool/emulator/flows/08_list_detail.sh||15|300"
  "30s3-filter-matrix-seq3|tool/emulator/flows/29_filter_matrix.sh|seqs:3|15|540"
  "30s4-filter-matrix-seq4|tool/emulator/flows/29_filter_matrix.sh|seqs:4|15|540"
  "21-district-close-then-other-chip|tool/emulator/flows/21_district_close_then_other_chip.sh||13"
  "25-directions-edge|tool/emulator/flows/25_directions_edge.sh||13"
  "09-photos|tool/emulator/flows/09_photos.sh||13"
  "22-filter-combos-reset|tool/emulator/flows/22_filter_combos_reset.sh||14"
  "10-directions|tool/emulator/flows/10_directions.sh||14"
  "28-small-screen-rotation-overflow|tool/emulator/flows/28_small_screen_rotation_overflow.sh||14"
  "30d-near-me|tool/emulator/flows/29_filter_matrix.sh|near_me:all|14"
)

plan_skip_list() {
  printf '%s' "${EMULATOR_SKIP_FLOWS-$DEFAULT_SKIP_FLOWS}" | tr ',' ' '
}

plan_is_skipped() {
  local id="$1"
  [[ " $(plan_skip_list) " == *" ${id} "* ]]
}

# Rows "id script part" for a tier, in run order. Fails on a bad tier/shard.
plan_flows() {
  local tier="${1:-}" shard="${2:-}" row id script part sh smoke_id
  case "$tier" in
    smoke)
      for smoke_id in $SMOKE_FLOWS; do
        for row in "${PLAN_ROWS[@]}"; do
          IFS='|' read -r id script part sh _ <<<"$row"
          if [[ "$id" == "$smoke_id" ]]; then
            printf '%s %s %s\n' "$id" "$script" "${part:--}"
          fi
        done
      done
      ;;
    full)
      if [[ -n "$shard" && ! "$shard" =~ ^[1-9][0-9]*$ ]] || (( ${shard:-1} > SHARD_COUNT )); then
        echo "plan.sh: shard must be 1-${SHARD_COUNT}" >&2
        return 1
      fi
      for row in "${PLAN_ROWS[@]}"; do
        IFS='|' read -r id script part sh _ <<<"$row"
        if [[ -z "$shard" || "$sh" == "$shard" ]]; then
          printf '%s %s %s\n' "$id" "$script" "${part:--}"
        fi
      done
      ;;
    all)
      for row in "${PLAN_ROWS[@]}"; do
        IFS='|' read -r id script part sh _ <<<"$row"
        printf '%s %s %s\n' "$id" "$script" "${part:--}"
      done | sort
      ;;
    *)
      echo "plan.sh: tier must be smoke, full, or all" >&2
      return 1
      ;;
  esac
}

# Cap in seconds for one flow id: the row's 5th field, else FLOW_CAP_S.
plan_cap_s() {
  local want="$1" row id script part sh cap
  for row in "${PLAN_ROWS[@]}"; do
    IFS='|' read -r id script part sh cap <<<"$row"
    if [[ "$id" == "$want" ]]; then
      if [[ "$cap" =~ ^[0-9]+$ ]] && (( cap > 0 && cap < FLOW_CAP_S )); then echo "$cap"; else echo "$FLOW_CAP_S"; fi
      return 0
    fi
  done
  echo "$FLOW_CAP_S"
}

plan_ids() {
  plan_flows "$@" | awk '{ print $1 }'
}

# Worst case for one emulator step: one boot, then every flow that is not
# skipped hitting its cap plus kill-after plus the reset around it.
plan_need_s() {
  local id total=$((SHARD_BOOT_S + SHARD_GETPROP_BUDGET_S + SHARD_ACTION_ADB_S + SHARD_GETPROP_S + SHARD_READY_S + SHARD_UNLOCK_S + SHARD_ANIM_S))
  while read -r id; do
    if ! plan_is_skipped "$id"; then
      total=$((total + $(plan_cap_s "$id") + FLOW_KILL_AFTER_S + FLOW_RESET_S + FLOW_OUTER_KILL_S))
    fi
  done < <(plan_ids "$@")
  echo "$total"
}

# Round 4.4.3-4.4.5: end-to-end worst case of a full run, in seconds.
# Prints "warm retry cold cold_retry refused refused_retry create_failed_retry max_shard":
#   warm       gate + build + setup + max shard + post
#   retry      ... + dead attempt + boot check + max shard with the retry
#              boot wait (SHARD_RETRY_BOOT_S)
#   cold       warm with the build replaced by the slower of build and a
#              cold avd-warmup job
#   cold_retry cold + the boot retry
#   refused    the warm-up saved nothing: each shard creates its own
#              snapshot (create step, <= SHARD_CREATE_STEP_MIN), then its
#              flows boot with the retry boot wait
#   refused_retry  refused + a dead first attempt (booting with the retry
#              wait: action start + 60 + keyevent + pre-BOOT watchdog) +
#              boot check + the retry flows (Manu: was 2767s in 4.4.4)
#   create_failed_retry  refused, but the shard's create step failed or hit
#              its cap: flows still boot with the retry wait (round 4.4.5),
#              then die and retry
plan_e2e_s() {
  local n need max=0 dead dead_r wu crit create create_cap warm retry cold cold_retry refused refused_retry cf_retry
  for n in $(seq 1 "$SHARD_COUNT"); do
    need="$(plan_need_s full "$n")"
    (( need > max )) && max=$need
  done
  dead=$((SHARD_ACTION_START_S + SHARD_BOOT_S + SHARD_GETPROP_BUDGET_S + SHARD_ACTION_ADB_S + SHARD_PREBOOT_S))
  dead_r=$((SHARD_ACTION_START_S + SHARD_RETRY_BOOT_S + SHARD_GETPROP_BUDGET_S + SHARD_ACTION_ADB_S + SHARD_PREBOOT_S))
  wu=$((E2E_WARMUP_BASE_S + WARMUP_CREATE_BOOT_S + SHARD_GETPROP_BUDGET_S + SHARD_ACTION_ADB_S + SHARD_ANIM_S + WARMUP_READY_S + WARMUP_SETTLE_S + SNAPSHOT_SETPROP_S + SNAPSHOT_SAVE_CAP_S - SNAPSHOT_SAVE_S))
  crit=$E2E_BUILD_S; (( wu > crit )) && crit=$wu
  create=$((SHARD_ACTION_START_S + SHARD_CREATE_BOOT_S + SHARD_GETPROP_BUDGET_S + SHARD_ACTION_ADB_S + SHARD_ANIM_S + SHARD_CREATE_READY_S + SHARD_CREATE_SETTLE_S + SNAPSHOT_SETPROP_S + SNAPSHOT_SAVE_CAP_S))
  (( create > SHARD_CREATE_DEADLINE_S )) && create=$SHARD_CREATE_DEADLINE_S
  create_cap=$((SHARD_CREATE_STEP_MIN * 60)); (( create > create_cap )) && create_cap=$create
  warm=$((E2E_GATE_S + E2E_BUILD_S + E2E_SETUP_S + max + E2E_POST_S))
  retry=$((E2E_GATE_S + E2E_BUILD_S + E2E_SETUP_S + dead + E2E_BOOT_CHECK_S + max - SHARD_BOOT_S + SHARD_RETRY_BOOT_S + E2E_POST_S))
  cold=$((E2E_GATE_S + crit + E2E_SETUP_S + max + E2E_POST_S))
  cold_retry=$((E2E_GATE_S + crit + E2E_SETUP_S + dead + E2E_BOOT_CHECK_S + max - SHARD_BOOT_S + SHARD_RETRY_BOOT_S + E2E_POST_S))
  refused=$((E2E_GATE_S + crit + E2E_SETUP_S + create + max - SHARD_BOOT_S + SHARD_RETRY_BOOT_S + E2E_POST_S))
  refused_retry=$((E2E_GATE_S + crit + E2E_SETUP_S + create + dead_r + E2E_BOOT_CHECK_S + max - SHARD_BOOT_S + SHARD_RETRY_BOOT_S + E2E_POST_S))
  cf_retry=$((E2E_GATE_S + crit + E2E_SETUP_S + create_cap + E2E_WARN_S + dead_r + E2E_BOOT_CHECK_S + max - SHARD_BOOT_S + SHARD_RETRY_BOOT_S + E2E_POST_S))
  echo "$warm $retry $cold $cold_retry $refused $refused_retry $cf_retry $max"
}

plan_matrix() {
  case "${1:-}" in
    smoke) echo '["smoke"]' ;;
    full)
      local i out="["
      for ((i = 1; i <= SHARD_COUNT; i++)); do
        out+="\"${i}\""
        if (( i < SHARD_COUNT )); then out+=","; fi
      done
      echo "${out}]"
      ;;
    *)
      echo "plan.sh: matrix tier must be smoke or full" >&2
      return 1
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  return 0
fi

cmd="${1:-}"
shift || true
case "$cmd" in
  flows) plan_flows "$@" ;;
  ids) plan_ids "$@" ;;
  matrix) plan_matrix "$@" ;;
  need-minutes)
    need="$(plan_need_s "$@")" || exit 1
    echo $(((need + 59) / 60))
    ;;
  *)
    echo "usage: plan.sh {flows|ids|matrix|need-minutes} <smoke|full|all> [shard]" >&2
    exit 2
    ;;
esac
