#!/usr/bin/env bash
# Flow 29e-drawer-all-district: filter matrix slice, entry drawer_all, chip district. See lib/filter_matrix.sh.
# Sourced by run_one_flow.sh.
MATRIX_ENTRY=drawer_all
MATRIX_CHIP=district
# shellcheck source=lib/filter_matrix.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/filter_matrix.sh"
matrix_main
