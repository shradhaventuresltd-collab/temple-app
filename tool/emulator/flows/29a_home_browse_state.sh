#!/usr/bin/env bash
# Flow 29a-home-browse-state: filter matrix slice, entry home_browse, chip state. See lib/filter_matrix.sh.
# Sourced by run_one_flow.sh.
MATRIX_ENTRY=home_browse
MATRIX_CHIP=state
# shellcheck source=lib/filter_matrix.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/filter_matrix.sh"
matrix_main
