#!/usr/bin/env bash
# Compatibility layer for PR 124 slice wrappers (29a–29m).
# Translates MATRIX_ENTRY / MATRIX_CHIP / MATRIX_ACTIONS / SEQ_CASES into
# FILTER_MATRIX_PART (and optionally ACTIONS) used by the KAN-198
# 29_filter_matrix.sh on main, then sources that flow.
# Sourced by the 29a–29m wrappers; run_one_flow.sh has already loaded
# tool/emulator/lib/common.sh.

_matrix_dir="$(dirname "${BASH_SOURCE[0]}")"

matrix_main() {
  local s n
  if [[ "${MATRIX_ENTRY:-}" == seq ]]; then
    for s in ${SEQ_CASES:-seq1 seq2 seq3 seq4 seq5}; do
      n="${s#seq}"
      FILTER_MATRIX_PART="seqs:${n}"
      # shellcheck source=../29_filter_matrix.sh
      source "${_matrix_dir}/../29_filter_matrix.sh"
    done
    return 0
  fi
  if [[ -z "${FILTER_MATRIX_PART:-}" ]]; then
    if [[ -n "${MATRIX_ENTRY:-}" && -n "${MATRIX_CHIP:-}" ]]; then
      FILTER_MATRIX_PART="${MATRIX_ENTRY}:${MATRIX_CHIP}"
    elif [[ -n "${MATRIX_ENTRY:-}" ]]; then
      FILTER_MATRIX_PART="${MATRIX_ENTRY}:all"
    fi
  fi
  if [[ -n "${MATRIX_ACTIONS:-}" && -z "${ACTIONS+x}" ]]; then
    # shellcheck disable=SC2206
    ACTIONS=(${MATRIX_ACTIONS})
  fi
  # shellcheck source=../29_filter_matrix.sh
  source "${_matrix_dir}/../29_filter_matrix.sh"
}
