#!/usr/bin/env bash
# Choose universal or split from the universal APK size in bytes.
# Over 60 MiB, split per ABI. At or under 60 MiB, keep the universal APK.
set -euo pipefail

bytes="${1:?apk size in bytes}"
limit=$((60 * 1024 * 1024))
if (( bytes > limit )); then
  printf '%s\n' split
else
  printf '%s\n' universal
fi
