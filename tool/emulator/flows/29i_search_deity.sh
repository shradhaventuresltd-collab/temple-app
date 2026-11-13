#!/usr/bin/env bash
# Flow 29i-search-deity: filter matrix slice, entry search, chip deity. See lib/filter_matrix.sh.
# Sourced by run_one_flow.sh.
MATRIX_ENTRY=search
MATRIX_CHIP=deity
# shellcheck source=lib/filter_matrix.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/filter_matrix.sh"
matrix_main
