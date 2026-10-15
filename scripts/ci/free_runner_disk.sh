#!/usr/bin/env bash
# Free space on a GitHub-hosted runner before an Android build.
# Prints df -h before and after. Smoke jobs call this and nothing else from the distribution CLI.
#
# The preinstalled NDK tree is not the NDK this app builds with
# (side-by-side 28.2.13676358). Removing the image's copies frees that
# space. The NDK cache restores 28.2.13676358 after this step.
# system-images stays; the emulator cache restores that path.
# The image tool directory stays. Deleting it took 31-58s, and the
# distribution job uses the Node that ships with the image.
set -euo pipefail

echo "===== disk before ====="
df -h

targets=(
  /usr/share/dotnet
  /opt/ghc
  /usr/local/lib/android/sdk/ndk
)

for path in "${targets[@]}"; do
  if [[ -e "$path" ]]; then
    sudo rm -rf "$path"
    echo "removed ${path}"
  else
    echo "absent ${path}"
  fi
done

echo "===== disk after ====="
df -h
