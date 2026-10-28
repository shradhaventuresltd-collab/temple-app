#!/usr/bin/env bash
# Flow 30d-near-me: filter matrix part b slice, entry near_me. Near me has no
# DirectoryFilterBar today, so the case records NOT RUN with that reason and
# the flow passes only its entry check. See lib/filter_matrix_b.sh.
# Sourced by run_one_flow.sh.
MATRIX_ENTRY=near_me
# shellcheck source=lib/filter_matrix_b.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/filter_matrix_b.sh"
matrix_main
