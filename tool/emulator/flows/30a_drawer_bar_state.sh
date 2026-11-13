#!/usr/bin/env bash
# Flow 30a-drawer-bar-state: filter matrix part b slice, entry drawer_bar
# (the FILTERS bar inside the drawer), chip state. See lib/filter_matrix_b.sh.
# Sourced by run_one_flow.sh.
MATRIX_ENTRY=drawer_bar
MATRIX_CHIP=state
# shellcheck source=lib/filter_matrix_b.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/filter_matrix_b.sh"
matrix_main
