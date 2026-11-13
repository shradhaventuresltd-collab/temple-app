#!/usr/bin/env bash
# Flow 29c-home-browse-deity: filter matrix slice, entry home_browse, chip deity. See lib/filter_matrix.sh.
# Sourced by run_one_flow.sh.
MATRIX_ENTRY=home_browse
MATRIX_CHIP=deity
# shellcheck source=lib/filter_matrix.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/filter_matrix.sh"
matrix_main
