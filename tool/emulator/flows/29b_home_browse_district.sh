#!/usr/bin/env bash
# Flow 29b-home-browse-district: filter matrix slice, entry home_browse, chip district. See lib/filter_matrix.sh.
# Sourced by run_one_flow.sh.
MATRIX_ENTRY=home_browse
MATRIX_CHIP=district
# shellcheck source=lib/filter_matrix.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/filter_matrix.sh"
matrix_main
