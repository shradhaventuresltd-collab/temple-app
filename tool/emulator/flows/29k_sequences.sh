#!/usr/bin/env bash
# Flow 29k-sequences: 3-step filter sequence seq3 on Home Browse, probed
# (split from 29j for the 1140s flow budget). See lib/filter_matrix.sh.
MATRIX_ENTRY=seq
SEQ_CASES="seq3"
# shellcheck source=lib/filter_matrix.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/filter_matrix.sh"
matrix_main
