#!/usr/bin/env bash
# Flow 17b: entry matrix (see lib/entry_matrix.sh) for entries: drawer_search list_drawer_all.
# Sourced by run_one_flow.sh.
# Read by lib/entry_matrix.sh.
# shellcheck disable=SC2034
ENTRY_MATRIX_ENTRIES="drawer_search list_drawer_all"
# shellcheck source=lib/entry_matrix.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/entry_matrix.sh"
