#!/usr/bin/env bash
# Invoked by android-emulator-runner. The action runs its script with
# /usr/bin/sh (dash), which rejects `set -o pipefail`, so the workflow
# calls this file instead of inlining bash options.
set -euo pipefail

export PATH="${PATH}:${HOME}/.maestro/bin"

bash scripts/ci/install_https_handoff.sh
adb install -r build/app/outputs/flutter-apk/app-profile.apk

export MAESTRO_CLI_NO_ANALYTICS=1
set +e
maestro test --debug-output /tmp/maestro-debug .maestro
status=$?
set -e
if [[ "$status" -ne 0 ]]; then
  echo "===== maestro hierarchy ====="
  maestro hierarchy || true
  echo "===== logcat (crash / flutter) ====="
  adb logcat -d -t 400 | grep -E "AndroidRuntime|FATAL|flutter" || true
  if [[ -d /tmp/maestro-debug ]]; then
    find /tmp/maestro-debug -type f -name '*.log' -print -exec tail -n 80 {} \;
  fi
  exit "$status"
fi
