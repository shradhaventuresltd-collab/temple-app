#!/usr/bin/env bash
# Which emulator flows run in which tier and shard (Confluence 12353537).
#
#   smoke  six flows, one job, on non-draft pull requests (path-filtered)
#   full   every flow, nine parallel shards (SHARD_COUNT), on workflow_dispatch and
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
# Device reset, pm clear, and the FAIL write around each flow.
FLOW_RESET_S=60
# One snapshot boot per job (emulator-boot-timeout).
SHARD_BOOT_S=300
SHARD_COUNT=9

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

# id|script|FILTER_MATRIX_PART|shard
# Shards are balanced by measured time from run 40916686359 (17, 06, 21,
# 22 and the filter matrix are the long ones) and hold at most five flows
# that are not skipped. Run 41373837994 hit the 600s cap in 17, 29 and 30:
# 17 is split in two (parts a/b), and the filter matrix runs one entry x
# one chip per flow (FILTER_MATRIX_PART=<entry>:<chip>, "seqs" for the
# 3+ step sequences), ~7 min each, on 8 shards.
PLAN_ROWS=(
  "17a-entry-matrix-home-button|tool/emulator/flows/17_entry_matrix.sh|home_button|1"
  "01-first-launch|tool/emulator/flows/01_first_launch.sh||1"
  "02-policy-gate|tool/emulator/flows/02_policy_gate.sh||1"
  "03-force-update|tool/emulator/flows/03_force_update.sh||1"
  "28-small-screen-rotation-overflow|tool/emulator/flows/28_small_screen_rotation_overflow.sh||1"
  "17b-entry-matrix-drawer-all|tool/emulator/flows/17_entry_matrix.sh|drawer_all|2"
  "29a-filter-matrix-home-state|tool/emulator/flows/29_filter_matrix.sh|home_browse:state|2"
  "04-home|tool/emulator/flows/04_home.sh||2"
  "05-search|tool/emulator/flows/05_search.sh||2"
  "07-district|tool/emulator/flows/07_district.sh||2"
  "29b-filter-matrix-home-district|tool/emulator/flows/29_filter_matrix.sh|home_browse:district|3"
  "30s-filter-matrix-sequences|tool/emulator/flows/29_filter_matrix.sh|seqs|3"
  "08-list-detail|tool/emulator/flows/08_list_detail.sh||3"
  "09-photos|tool/emulator/flows/09_photos.sh||3"
  "10-directions|tool/emulator/flows/10_directions.sh||3"
  "11-near-me|tool/emulator/flows/11_near_me.sh||3"
  "06-filters|tool/emulator/flows/06_filters.sh||4"
  "12-ads|tool/emulator/flows/12_ads.sh||4"
  "13-licences|tool/emulator/flows/13_licences.sh||4"
  "14-back-relaunch|tool/emulator/flows/14_back_relaunch.sh||4"
  "16-home-browse|tool/emulator/flows/16_home_browse.sh||4"
  "23-near-me-settings-roundtrip|tool/emulator/flows/23_near_me_settings_roundtrip.sh||4"
  "21-district-close-then-other-chip|tool/emulator/flows/21_district_close_then_other_chip.sh||5"
  "15-offline|tool/emulator/flows/15_offline.sh||5"
  "18-home-reselect|tool/emulator/flows/18_home_reselect.sh||5"
  "19-rotation-state|tool/emulator/flows/19_rotation_state.sh||5"
  "20-empty-and-back|tool/emulator/flows/20_empty_and_back.sh||5"
  "22-filter-combos-reset|tool/emulator/flows/22_filter_combos_reset.sh||6"
  "24-gallery-autoadvance-viewer|tool/emulator/flows/24_gallery_autoadvance_viewer.sh||6"
  "25-directions-edge|tool/emulator/flows/25_directions_edge.sh||6"
  "26-drawer-nav-stack|tool/emulator/flows/26_drawer_nav_stack.sh||6"
  "27-offline-cold-start|tool/emulator/flows/27_offline_cold_start.sh||6"
  "29c-filter-matrix-home-deity|tool/emulator/flows/29_filter_matrix.sh|home_browse:deity|7"
  "29d-filter-matrix-drawer-all-state|tool/emulator/flows/29_filter_matrix.sh|drawer_all:state|7"
  "29e-filter-matrix-drawer-all-district|tool/emulator/flows/29_filter_matrix.sh|drawer_all:district|7"
  "29f-filter-matrix-drawer-all-deity|tool/emulator/flows/29_filter_matrix.sh|drawer_all:deity|7"
  "30a-filter-matrix-drawer-bar-state|tool/emulator/flows/29_filter_matrix.sh|drawer_bar:state|7"
  "30b-filter-matrix-drawer-bar-district|tool/emulator/flows/29_filter_matrix.sh|drawer_bar:district|8"
  "30c-filter-matrix-drawer-bar-deity|tool/emulator/flows/29_filter_matrix.sh|drawer_bar:deity|8"
  "30e-filter-matrix-search-state|tool/emulator/flows/29_filter_matrix.sh|search:state|8"
  "30f-filter-matrix-search-district|tool/emulator/flows/29_filter_matrix.sh|search:district|8"
  "30g-filter-matrix-search-deity|tool/emulator/flows/29_filter_matrix.sh|search:deity|8"
  "30d-near-me|tool/emulator/flows/29_filter_matrix.sh|near_me:all|8"
  "17c-entry-matrix-drawer-search|tool/emulator/flows/17_entry_matrix.sh|drawer_search|9"
  "17d-entry-matrix-list-drawer-all|tool/emulator/flows/17_entry_matrix.sh|list_drawer_all|9"
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
          IFS='|' read -r id script part sh <<<"$row"
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
        IFS='|' read -r id script part sh <<<"$row"
        if [[ -z "$shard" || "$sh" == "$shard" ]]; then
          printf '%s %s %s\n' "$id" "$script" "${part:--}"
        fi
      done
      ;;
    all)
      for row in "${PLAN_ROWS[@]}"; do
        IFS='|' read -r id script part sh <<<"$row"
        printf '%s %s %s\n' "$id" "$script" "${part:--}"
      done | sort
      ;;
    *)
      echo "plan.sh: tier must be smoke, full, or all" >&2
      return 1
      ;;
  esac
}

plan_ids() {
  plan_flows "$@" | awk '{ print $1 }'
}

# Worst case for one emulator step: one boot, then every flow that is not
# skipped hitting its cap plus kill-after plus the reset around it.
plan_need_s() {
  local id active=0
  while read -r id; do
    if ! plan_is_skipped "$id"; then
      active=$((active + 1))
    fi
  done < <(plan_ids "$@")
  echo $((SHARD_BOOT_S + active * (FLOW_CAP_S + FLOW_KILL_AFTER_S + FLOW_RESET_S)))
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
