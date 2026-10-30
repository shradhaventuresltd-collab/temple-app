#!/usr/bin/env bash
# Flow 29j-sequences: 3-step filter sequences seq1-seq2 on Home Browse, each
# probed. seq3 is flow 29k, seq4-seq5 flow 29l (1140s flow budget).
# District only follows a State. See lib/filter_matrix.sh.
MATRIX_ENTRY=seq
SEQ_CASES="seq1 seq2"
# shellcheck source=lib/filter_matrix.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/filter_matrix.sh"
matrix_main
