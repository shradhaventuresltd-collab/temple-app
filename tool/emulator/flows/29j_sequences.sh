#!/usr/bin/env bash
# Flow 29j-sequences: 3-step filter sequences on Home Browse, each probed.
# District only follows a State. See lib/filter_matrix.sh.
MATRIX_ENTRY=seq
# shellcheck source=lib/filter_matrix.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/filter_matrix.sh"
matrix_main
