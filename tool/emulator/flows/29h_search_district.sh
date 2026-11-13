#!/usr/bin/env bash
# Flow 29h-search-district: filter matrix slice, entry search, chip district.
# First three actions (select, pick-close, dismiss-empty). The last three
# are flow 29m (run 41269171081: all six reached 933s of 1140s and the
# pre-flight stopped the last two clear probes). See lib/filter_matrix.sh.
# Sourced by run_one_flow.sh.
MATRIX_ENTRY=search
MATRIX_CHIP=district
MATRIX_ACTIONS="select pick-close dismiss-empty"
# shellcheck source=lib/filter_matrix.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/filter_matrix.sh"
matrix_main
