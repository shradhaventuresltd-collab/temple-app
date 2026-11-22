#!/usr/bin/env bash
# Compatibility layer for PR 124 part-b wrappers (30a–30d).
# Same translation as lib/filter_matrix.sh: the KAN-198 matrix lives in
# 29_filter_matrix.sh and already covers drawer_bar and near_me.
# Sourced by the 30a–30d wrappers.

# shellcheck source=filter_matrix.sh
source "$(dirname "${BASH_SOURCE[0]}")/filter_matrix.sh"
