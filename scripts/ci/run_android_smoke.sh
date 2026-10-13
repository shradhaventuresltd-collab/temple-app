#!/usr/bin/env bash
# Invoked by android-emulator-runner. The action runs its script with
# /usr/bin/sh (dash), which rejects `set -o pipefail`, so the workflow
# calls this file instead of inlining bash options.
set -euo pipefail

export PATH="${PATH}:${HOME}/.maestro/bin"

bash scripts/ci/install_https_handoff.sh
adb install -r build/app/outputs/flutter-apk/app-debug.apk
maestro test .maestro
