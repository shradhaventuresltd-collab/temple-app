#!/usr/bin/env bash
# Build the Play release app bundle.
#
# Refuses ENABLE_ADMIN_TOOLS so Seed / CMS / Upload stay out of the Play AAB.
# Also refuses --dart-define-from-file (equals or space form); that file can
# set the define. Demo APKs pass the define on their own flutter build
# command; do not use this script for those.
#
#   ./scripts/build_play_aab.sh
#   ./scripts/build_play_aab.sh --build-name=1.2.0 --build-number=3
#
# The bundle is build/app/outputs/bundle/release/app-release.aab.
# Signing requirements: docs/android-play-internal-test.md.

set -euo pipefail

cd "$(dirname "$0")/.."

refuse() {
  echo "error: Play AAB must not be built with ENABLE_ADMIN_TOOLS." >&2
  echo "Admin tools stay out of Play builds. For a demo APK, use:" >&2
  echo "  flutter build apk --profile --target-platform=android-arm64 --dart-define=ENABLE_ADMIN_TOOLS=true" >&2
  exit 1
}

refuse_define_file() {
  echo "error: Play AAB must not be built with --dart-define-from-file." >&2
  echo "A defines file can set ENABLE_ADMIN_TOOLS. Admin tools stay out of Play builds." >&2
  exit 1
}

if [[ "${ENABLE_ADMIN_TOOLS:-}" == "true" ]]; then
  refuse
fi

for arg in "$@"; do
  case "$arg" in
    *ENABLE_ADMIN_TOOLS=true*)
      refuse
      ;;
    --dart-define-from-file|--dart-define-from-file=*)
      refuse_define_file
      ;;
  esac
done

exec flutter build appbundle --release "$@"
