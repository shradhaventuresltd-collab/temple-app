#!/usr/bin/env bash
# PR 124 17a/17b wrappers source this file. The implementation lives in
# 17_entry_matrix.sh so plan.sh and self_test keep a stable path.
# shellcheck source=../17_entry_matrix.sh
source "$(dirname "${BASH_SOURCE[0]}")/../17_entry_matrix.sh"
