#!/usr/bin/env bash
# Flow 29l-sequences: 3-step filter sequences seq4-seq5 on Home Browse, each
# probed (split from 29j for the 1140s flow budget). See lib/filter_matrix.sh.
MATRIX_ENTRY=seq
SEQ_CASES="seq4 seq5"
# shellcheck source=lib/filter_matrix.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/filter_matrix.sh"
matrix_main
