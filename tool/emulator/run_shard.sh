#!/usr/bin/env bash
# Run one tier or shard of emulator flows on the emulator that is already
# booted (one snapshot boot per job). Each flow goes through
# run_one_flow.sh, which caps it at FLOW_BUDGET (600s), skips the
# location-dependent flows, and clears app data (pm clear) before every
# flow after the first.
#
# Usage: run_shard.sh smoke
#        run_shard.sh full <shard 1-SHARD_COUNT> (plan.sh)
#        run_shard.sh all
# EMULATOR_SHARD_DRY_RUN=1 prints the plan and runs nothing.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT" || exit 1
# shellcheck source=SCRIPTDIR/plan.sh
source "${ROOT}/tool/emulator/plan.sh"

tier="${1:-}"
shard="${2:-}"
if [[ "$tier" == full && -z "$shard" ]]; then
  echo "run_shard.sh: full needs a shard number 1-${SHARD_COUNT}" >&2
  exit 1
fi
if ! rows="$(plan_flows "$tier" "$shard")"; then
  exit 1
fi

export EMULATOR_REUSE_INSTALL=1
# Round 4.4.8b: harness adb calls keep real exit codes (adb_shim/adb).
export ADB_SHIM_HARNESS=1
artifacts="${EMULATOR_ARTIFACTS:-${ROOT}/emulator-app-test-artifacts}"
mkdir -p "$artifacts"
total="$(printf '%s\n' "$rows" | grep -c .)"
skipped=0
while read -r id _; do
  if [[ -n "$id" ]] && plan_is_skipped "$id"; then skipped=$((skipped + 1)); fi
done <<<"$rows"
# Round 4.4.9b: the per-row caps (plan.sh field 5), not the 600s ceiling:
# run 41757362316 printed "cap 600s each" for shards whose 30sN rows run
# at 540s, which read as if 540 was not applied.
caps_line="$(plan_ids "$tier" "$shard" | while read -r cid; do plan_is_skipped "$cid" || printf '%s=%ss ' "$cid" "$(plan_cap_s "$cid")"; done)"
echo "Emulator ${tier}${shard:+ shard ${shard}}: ${total} flows (${skipped} skipped, $((total - skipped)) to run), caps: ${caps_line% }, worst case $(plan_need_s "$tier" "$shard")s"

# Boot check, once per job: snapshot_create.sh set a RAM-only property
# before saving the snapshot, so it is still set only if this boot restored
# the snapshot. A cold boot ("cannot load snapshot ... different AVD
# configuration", run 41314245431) is a warning, not a failure.
if [[ "${EMULATOR_SHARD_DRY_RUN:-}" != 1 ]]; then
  # Round 4.4.3/4.4.4 (Manu): the BOOT line must be written within
  # SHARD_PREBOOT_S of run_shard.sh starting. Before BOOT runs only what
  # proves the emulator is alive: the snapshot-marker getprop (capped at
  # SHARD_GETPROP_S). A hang there (a dead emulator, an adb call that never
  # returns) would otherwise run the whole 42-min step; the watchdog ends
  # the attempt with no BOOT line, so the workflow's boot check retries.
  # Readiness, unlock and animations run after BOOT (bounded, non-fatal).
  # The watchdog and BOOT race for one claim (mkdir is atomic): whoever
  # makes the claim dir first wins, so a watchdog firing while BOOT is being
  # written can no longer kill a booted shard (round 4.4.4).
  preboot_s="${EMULATOR_PREBOOT_S:-$SHARD_PREBOOT_S}"
  # Round 4.4.9 (run 41757362316, shards 1/3/4/6/9/10): readiness moved
  # BEFORE the BOOT line. Those emulators loaded the snapshot, then zygote
  # and native services crash-looped (SIGILL, "received signal 4", 9 zygote
  # starts) and input/settings/package/activity never came up: the 4.4.8b
  # run went on and every flow failed at install ("cmd: Can't find service:
  # package"). Not ready within SHARD_READY_S (services_ready 10s + 2s
  # kill-after; every healthy boot so far was ready on poll 1, <= 1s) is
  # now a dead boot: no BOOT line, exit 1, so the workflow's boot check
  # runs the one retry, and a second dead attempt leaves the shard without
  # a BOOT line (release_gate: missing shard, its flows NOT RUN).
  services_wait_s="${EMULATOR_SERVICES_WAIT_S:-$((SHARD_READY_S - 2))}"
  wait_services_ready() { timeout --kill-after=2 "$1" bash tool/emulator/services_ready.sh "$1"; }
  main_pid=$$
  claim="$(mktemp -u "${TMPDIR:-/tmp}/run_shard.boot.XXXXXX")"
  (
    sleep "$preboot_s" >/dev/null 2>&1
    mkdir "$claim" 2>/dev/null || exit 0
    echo "::error::no BOOT line ${preboot_s}s after run_shard.sh started; ending this attempt so the boot retry can run" >&2
    # run_shard.sh first (so it cannot go on to write BOOT), then every
    # descendant listed before that (a hung adb inside $(...) would keep
    # the step's stdout open), never this watchdog.
    wd_pid=$BASHPID
    tree() { local c; for c in $(pgrep -P "$1"); do [[ "$c" == "$wd_pid" ]] && continue; echo "$c"; tree "$c"; done; }
    victims="$(tree "$main_pid")"
    kill -TERM "$main_pid" 2>/dev/null
    for c in $victims; do kill -TERM "$c" 2>/dev/null; done
    # Round 4.4.5 (Manu nit 2): run_shard.sh is gone, so drop the claim.
    rmdir "$claim" 2>/dev/null
  ) &
  preboot_watchdog=$!
  marker="$(timeout "${SHARD_GETPROP_S:-5}" adb shell getprop debug.temple.snapshot_marker 2>/dev/null </dev/null | tr -d '\r' || true)"
  if [[ "$marker" == 1 ]]; then boot=snapshot; else boot=cold; fi
  svc_out="$(wait_services_ready "$services_wait_s" 2>&1)"; svc_rc=$?
  if ! mkdir "$claim" 2>/dev/null; then
    # The watchdog claimed first: it is ending this attempt (no BOOT line).
    wait "$preboot_watchdog" 2>/dev/null; rmdir "$claim" 2>/dev/null; exit 1
  fi
  # Test hook (self_test): widen the race window. The watchdog expires here,
  # after the claim and before it is disarmed; it must then stand down.
  [[ -n "${EMULATOR_TEST_BOOT_WRITE_DELAY_S:-}" ]] && sleep "$EMULATOR_TEST_BOOT_WRITE_DELAY_S"
  kill "$preboot_watchdog" 2>/dev/null; wait "$preboot_watchdog" 2>/dev/null
  rmdir "$claim" 2>/dev/null
  printf '%s\n' "$svc_out"
  host_cpu="$(bash tool/emulator/cpu_id.sh --describe 2>/dev/null || echo unknown) (cache key cpu ${EMULATOR_CPU_ID:-unset})"
  if (( svc_rc != 0 )); then
    printf 'DEAD boot %s%s: system services not ready after %ss (%s); host cpu %s\n' "$tier" "${shard:+-${shard}}" "$services_wait_s" "$(tail -1 <<<"$svc_out")" "$host_cpu" >> "${artifacts}/results.txt"
    echo "::error::emulator ${tier}${shard:+ shard ${shard}}: system services not ready after ${services_wait_s}s; dead boot (no BOOT line), the boot check retries once"
    exit 1
  fi
  printf 'BOOT %s%s %s\n' "$tier" "${shard:+-${shard}}" "$boot" >> "${artifacts}/results.txt"
  printf 'HOSTCPU %s%s %s\n' "$tier" "${shard:+-${shard}}" "$host_cpu" >> "${artifacts}/results.txt"
  # Round 4.4 (after BOOT since 4.4.4): unlock (keyevent 82) up to
  # SHARD_UNLOCK_TRIES times 2s apart, and turn animations off in one capped
  # call (SHARD_ANIM_S; the action's disable-animations is off). Neither is
  # fatal. Readiness runs before BOOT since round 4.4.9 (above).
  for ((u = 1; u <= SHARD_UNLOCK_TRIES; u++)); do
    timeout 3 adb shell input keyevent 82 </dev/null >/dev/null 2>&1 && break
    (( u < SHARD_UNLOCK_TRIES )) && sleep 2
  done
  (( u <= SHARD_UNLOCK_TRIES )) || echo "::warning::unlock (keyevent 82) failed ${SHARD_UNLOCK_TRIES} times; continuing"
  timeout "${SHARD_ANIM_S:-5}" adb shell "$ANIM_OFF_CMD" </dev/null >/dev/null 2>&1 || echo "::warning::could not turn animations off; continuing"
  echo "boot: ${boot}"
  # Which keys differ between this boot's hardware-qemu.ini and the snapshot.
  snaprc=0
  snapcheck="$(bash tool/emulator/check_snapshot_config.sh post 2>/dev/null)" || snaprc=$?
  snapcheck="$(head -1 <<<"$snapcheck")"
  [[ -n "$snapcheck" ]] && printf 'SNAPCFG %s%s %s\n' "$tier" "${shard:+-${shard}}" "$snapcheck" >> "${artifacts}/results.txt"
  # Round 4.3.2: fail fast only when the config differs (size, cores, RAM,
  # partitions) AND the marker shows a cold boot: no flow runs on it
  # silently, and every planned flow then has no result (release_gate:
  # NOT RUN). A mismatch on a snapshot boot is only recorded (SNAPCFG).
  if [[ "$snaprc" == 1 && "$boot" == cold ]]; then
    printf 'FAIL boot-%s%s: snapshot config mismatch, cold boot: %s\n' "$tier" "${shard:+-${shard}}" "$snapcheck" >> "${artifacts}/results.txt"
    echo "::error::emulator ${tier}${shard:+ shard ${shard}}: ${snapcheck}"
    exit 1
  fi
  if [[ "$snaprc" == 1 ]]; then
    echo "::warning::emulator ${tier}${shard:+ shard ${shard}}: snapshot boot, but the AVD config differs from the snapshot: ${snapcheck}"
  fi
  if [[ "$boot" == cold ]]; then
    echo "::warning::emulator ${tier}${shard:+ shard ${shard}} cold-booted: the AVD snapshot was not loaded"
  fi
  [[ -n "${GITHUB_STEP_SUMMARY:-}" ]] && echo "boot: ${boot}" >> "$GITHUB_STEP_SUMMARY"
  [[ -n "${GITHUB_ENV:-}" ]] && echo "EMULATOR_BOOT=${boot}" >> "$GITHUB_ENV"
  if [[ -n "${RUNNER_TEMP:-}" ]]; then
    avd_dir="${ANDROID_AVD_HOME:-${HOME}/.android/avd}/${EMULATOR_AVD_NAME:-emulator-app-test-30}.avd"
    mkdir -p "${RUNNER_TEMP}/avd-ini/run-booted"
    cp -f "$avd_dir"/config.ini "$avd_dir"/hardware-qemu.ini "${RUNNER_TEMP}/avd-ini/run-booted/" 2>/dev/null || true
    cp -f "$avd_dir"/snapshots/default_boot/hardware.ini "${RUNNER_TEMP}/avd-ini/run-booted/snapshot-hardware.ini" 2>/dev/null || true
  fi
fi

# Outer guard: run_one_flow.sh enforces FLOW_BUDGET itself. This only stops
# a wrapper that wedges outside the flow (pm clear, logcat pull).
guard=$((FLOW_CAP_S + FLOW_KILL_AFTER_S + FLOW_RESET_S))
# The self-test swaps in a stub runner. CI always uses run_one_flow.sh.
runner="${EMULATOR_FLOW_RUNNER:-tool/emulator/run_one_flow.sh}"

# The plan rows are read on fd 3, and each flow runs with stdin from
# /dev/null. A flow's adb shell (or any command that reads stdin) would
# otherwise read the remaining rows, and only the first flow would run
# (PR #126 run 41306793034: shards 4, 5, 6 ran one flow each).
while read -r id script part <&3; do
  [[ -n "$id" ]] || continue
  if [[ "$part" == - ]]; then part=""; fi
  if [[ "${EMULATOR_SHARD_DRY_RUN:-}" == 1 ]]; then
    printf 'PLAN %s %s %s\n' "$id" "$script" "${part:--}"
    continue
  fi
  # A skipped flow is recorded here, at plan time, so the summary never
  # sees it as missing even if the runner is not reached.
  if plan_is_skipped "$id"; then
    printf 'SKIPPED %s: location-dependent, skipped on the emulator (EMULATOR_SKIP_FLOWS)\n' "$id" >> "${artifacts}/results.txt"
    echo "SKIPPED ${id}"
    continue
  fi
  cap="$(plan_cap_s "$id")"
  echo "::group::Flow ${id} (cap ${cap}s)"
  started=$SECONDS
  flow_guard=$((cap + FLOW_KILL_AFTER_S + FLOW_RESET_S))
  (( flow_guard <= guard )) || flow_guard=$guard
  EMULATOR_FLOW_BUDGET="$cap" FILTER_MATRIX_PART="${part:-all}" timeout --kill-after="$FLOW_OUTER_KILL_S" "$flow_guard" \
    bash "$runner" "$id" "$script" </dev/null
  rc=$?
  if [[ "$rc" -eq 124 || "$rc" -eq 137 ]]; then
    printf 'FAIL %s: timeout: wrapper exceeded %ss\n' "$id" "$flow_guard" >> "${artifacts}/results.txt"
  fi
  printf 'TIME %s %ss\n' "$id" "$((SECONDS - started))" >> "${artifacts}/results.txt"
  echo "::endgroup::"
done 3<<<"$rows"
exit 0
