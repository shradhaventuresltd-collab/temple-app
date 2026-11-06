#!/usr/bin/env bash
# Replay of 30s5 (deity:select district:select state:outside-empty district:clear)
# through scoped_pick + first_real_option on real dumps. Usage: replay_seq5.sh REPO
cd "$1" || exit 2
fx9=tool/emulator/testdata/run41781519101 fx11=tool/emulator/testdata/run41872598981
# shellcheck disable=SC2016 # expands when the trap runs
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
printf '<hierarchy><node text="" resource-id="filter-chip-state" content-desc="State" bounds="[14,184][114,219]" /><node text="" resource-id="filter-chip-district" content-desc="All districts" bounds="[122,184][262,219]" /><node text="" resource-id="filter-chip-deity" content-desc="Deity" bounds="[270,184][330,219]" /></hierarchy>' > "$tmp/bar_none.xml"
( export EMULATOR_FLOW=30s5-filter-matrix-seq5 EMULATOR_ARTIFACTS="$tmp/a" EMULATOR_PACKAGE=com.example
  # shellcheck disable=SC1091
  source tool/emulator/lib/common.sh >/dev/null 2>&1
  declare -A APPLIED=()
  bar="" ; ui_dump() { cp "$bar" "$DUMP"; }
  step() { # kind action bar-dump sheet-dump
    bar="$3"; local pick first rid; pick="$(scoped_pick "$1")"
    if [[ "$pick" == @first && -n "${4:-}" ]]; then cp "$4" "$DUMP"; { read -r first; read -r rid; } < <(first_real_option "$1"); fi
    echo "STEP $1:$2 chip-bar=$(basename "$3") pick=${pick}${first:+ -> '$first'}"
    [[ "$2" == select && -n "${first:-}" ]] && APPLIED[$1]="$first"
    [[ "$2" == select && "$1" == deity && -z "${first:-}" ]] && APPLIED[deity]="81 Yoginis; Gauri-Shankar (central shrine)"
  }
  step deity select "$tmp/bar_none.xml"
  step district select "$fx9/browse_deity_applied.xml" "$fx11/sheet_district_jabalpur.xml"
  echo "STEP state:outside-empty (opens the state sheet and dismisses it; no pick)"
  step district clear "$fx11/browse_deity_chip_offscreen.xml" "$fx11/sheet_district_jabalpur.xml"
  echo "APPLIED: $(for k in "${!APPLIED[@]}"; do printf '%s=%s; ' "$k" "${APPLIED[$k]}"; done)" )
