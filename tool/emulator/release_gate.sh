#!/usr/bin/env bash
# Release-gate line for the summary job. Usage:
#   release_gate.sh TIER SHA SOURCE   (SOURCE: build | url | artifact)
# Only a build-mode run tested the APK built from SHA. With apk_url or
# artifact inputs SHA is just this run's commit, not the APK's, so it is
# printed as unverified and must not be used as a release gate.
# Writes to GITHUB_STEP_SUMMARY when set, and to stdout.
# It also reads the merged results ($EMULATOR_ARTIFACTS/results.txt) and
# prints "NOT a release gate: <reasons>" on any FAIL, XFAIL, XPASS or
# NOT RUN, on any SKIPPED flow outside plan.sh's planned skips
# (DEFAULT_SKIP_FLOWS; an EMULATOR_SKIP_FLOWS override does not count), or
# when the results are missing: a known bug is still a bug in the release.
# Only the release path exits 1 on that: EMULATOR_GATE_MODE=strict (set by
# the workflow for a published release or a dispatch with release_gate=true),
# or event "release" (EMULATOR_GATE_EVENT / GITHUB_EVENT_NAME). The strict
# path also refuses a non-full tier and an APK that was not built from SHA.
# Dispatch and pull_request runs list the same reasons and exit 0.
set -euo pipefail
tier="${1:?tier}" sha="${2:?sha}" source="${3:?source}"
if [[ ! "$sha" =~ ^[0-9a-f]{40}$ ]]; then
  echo "build did not report a full SHA: '${sha}'" >&2
  exit 1
fi
tick='`'
case "$source" in
  build)
    line="Emulator **${tier}** suite ran on commit ${tick}${sha}${tick}."
    ;;
  url|artifact)
    line="Emulator **${tier}** suite ran on an APK from ${source} input; run commit ${tick}${sha}${tick}: SHA UNVERIFIED, not valid as release gate."
    ;;
  *)
    echo "release_gate.sh: unknown APK source '${source}'" >&2
    exit 1
    ;;
esac
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
results="${EMULATOR_ARTIFACTS:-${root}/emulator-app-test-artifacts}/results.txt"
refuse=""
if [[ ! -s "$results" ]]; then
  refuse="no results at ${results}"
else
  n_fail="$(grep -c '^FAIL ' "$results" || true)"
  n_xfail="$(grep -c '^XFAIL ' "$results" || true)"
  n_xpass="$(grep -c '^XPASS ' "$results" || true)"
  n_notrun="$(grep -c '^NOT RUN ' "$results" || true)"
  # Planned skips come from plan.sh (DEFAULT_SKIP_FLOWS), never hard-coded.
  planned="$(bash -c 'source "$1"; printf "%s" "$DEFAULT_SKIP_FLOWS"' _ "${root}/tool/emulator/plan.sh")"
  unplanned="$(sed -n 's/^SKIPPED \([^: ]*\).*/\1/p' "$results" | sort -u | while read -r id; do
    [[ " ${planned} " == *" ${id} "* ]] || printf '%s ' "$id"
  done)"
  unplanned="${unplanned% }"
  n_unplanned=0
  [[ -n "$unplanned" ]] && n_unplanned="$(wc -w <<< "$unplanned")"
  if (( n_fail + n_xfail + n_xpass + n_notrun + n_unplanned > 0 )); then
    refuse="${n_fail} FAIL, ${n_xfail} XFAIL, ${n_xpass} XPASS, ${n_notrun} NOT RUN, ${n_unplanned} unplanned SKIPPED${unplanned:+ (${unplanned})}"
  fi
fi
if [[ -n "$refuse" ]]; then
  line="${line} NOT a release gate: ${refuse}."
fi
echo "$line"
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  printf '### Release gate\n\n%s\n\n' "$line" >> "$GITHUB_STEP_SUMMARY"
  if [[ -n "$refuse" && -s "$results" ]]; then
    { grep -E '^(FAIL|XFAIL|XPASS|NOT RUN) ' "$results" || true; } | sed 's/^/- /' >> "$GITHUB_STEP_SUMMARY"
    for id in $unplanned; do grep -m1 "^SKIPPED ${id}[: ]" "$results" | sed 's/^/- unplanned: /' >> "$GITHUB_STEP_SUMMARY"; done
  fi
fi
event="${EMULATOR_GATE_EVENT:-${GITHUB_EVENT_NAME:-}}"
strict=0
if [[ "${EMULATOR_GATE_MODE:-}" == strict || "$event" == release ]]; then strict=1; fi
if [[ "$strict" -eq 1 && "$tier" != full ]]; then
  refuse="${refuse:+${refuse}; }tier ${tier}, the release gate needs full"
fi
if [[ "$strict" -eq 1 && "$source" != build ]]; then
  refuse="${refuse:+${refuse}; }APK from ${source} input, not built from ${sha}"
  echo "Emulator **${tier}** release gate: NOT a release gate: ${refuse}."
fi
if [[ -n "$refuse" ]]; then
  if [[ "$strict" -eq 1 ]]; then
    echo "release_gate.sh: refusing release: ${refuse}" >&2
    exit 1
  fi
  echo "release_gate.sh: ${event:-local} run, not the release path: NOT a release gate (${refuse}); exit 0"
fi
