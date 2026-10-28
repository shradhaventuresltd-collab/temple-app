#!/usr/bin/env bash
# Flow 29h-search-district: filter matrix slice, entry search, chip district. See lib/filter_matrix.sh.
# Sourced by run_one_flow.sh.
MATRIX_ENTRY=search
MATRIX_CHIP=district
# shellcheck source=lib/filter_matrix.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/filter_matrix.sh"
matrix_main
