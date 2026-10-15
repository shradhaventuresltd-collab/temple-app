#!/usr/bin/env bash
# Free space on a GitHub-hosted runner before an Android build.
# Prints df -h before and after. Smoke jobs call this and nothing else from the distribution CLI.
#
# The preinstalled NDK tree is not the NDK this app builds with. A green
# android-smoke log shows sdkmanager downloading android-ndk-r28c during
# flutter build, into this same directory. Removing the image's copies
# leaves that download as the only NDK. system-images stays; the emulator
# cache restores that path.
set -euo pipefail

echo "===== disk before ====="
df -h

targets=(
  /usr/share/dotnet
  /opt/ghc
  /usr/local/lib/android/sdk/ndk
  /opt/hostedtoolcache
)
if [[ -n "${AGENT_TOOLSDIRECTORY:-}" && "${AGENT_TOOLSDIRECTORY}" != "/opt/hostedtoolcache" ]]; then
  case "${AGENT_TOOLSDIRECTORY}" in
    /opt/*) targets+=("${AGENT_TOOLSDIRECTORY}") ;;
  esac
fi

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
