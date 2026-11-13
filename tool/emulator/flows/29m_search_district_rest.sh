#!/usr/bin/env bash
# Flow 29m-search-district-rest: second half of the search x district
# matrix slice (back-empty, outside-empty, clear). Split from 29h after
# run 41269171081 stopped at 933s of 1140s. See lib/filter_matrix.sh.
# Sourced by run_one_flow.sh.
MATRIX_ENTRY=search
MATRIX_CHIP=district
MATRIX_ACTIONS="back-empty outside-empty clear"
# shellcheck source=lib/filter_matrix.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/filter_matrix.sh"
matrix_main
