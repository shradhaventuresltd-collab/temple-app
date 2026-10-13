#!/usr/bin/env bash
# Build the Play release app bundle.
#
# Refuses ENABLE_ADMIN_TOOLS so Seed / CMS / Upload stay out of the Play AAB,
# and refuses DEMO_BUILD so a Play upload cannot ship AdMob test units.
#
# Forms that fail before Gradle runs:
#   --dart-define=ENABLE_ADMIN_TOOLS=...     (= form, any value)
#   --dart-define ENABLE_ADMIN_TOOLS=...     (space form, any value)
#   ENABLE_ADMIN_TOOLS=... in the environment (any value, including empty)
#   --dart-define-from-file <file>           when the file contains
#   --dart-define-from-file=<file>           ENABLE_ADMIN_TOOLS or DEMO_BUILD
# The same = / space / env / from-file forms refuse DEMO_BUILD.
#
# After a successful `flutter build appbundle --release`, the bundle is
# checked with apksigner (when present) and keytool. A cert whose subject
# contains CN=Android Debug is refused. An unreadable cert is refused too.
#
# Before Gradle runs, scripts/check_android_smoke_gate.sh refuses the build
# unless the android-smoke job has succeeded on this exact HEAD SHA, and it
# refuses a dirty working tree. Only SMOKE_GATE_OVERRIDE=1 bypasses the
# green-smoke check: it prints a loud warning and continues. Other values,
# including 0, do not. The override does not bypass a dirty tree. Do not set
# it for a Play upload unless you accept an unsmoked commit. --verify-signing
# checks a bundle you already built and does not run the smoke gate.
#
#   ./scripts/build_play_aab.sh
#   ./scripts/build_play_aab.sh --build-name=1.2.0 --build-number=3
#   ./scripts/build_play_aab.sh --verify-signing path/to/app.aab
#
# The bundle is build/app/outputs/bundle/release/app-release.aab.
# Signing requirements: docs/android-play-internal-test.md.
# CI (no upload key) runs scripts/test_play_aab_guard.sh instead of this build.

set -euo pipefail

cd "$(dirname "$0")/.."

refuse_admin() {
  echo "error: Play AAB must not be built with ENABLE_ADMIN_TOOLS." >&2
  echo "Admin tools stay out of Play builds. For a demo APK, use:" >&2
  echo "  flutter build apk --profile --target-platform=android-arm64 --dart-define=ENABLE_ADMIN_TOOLS=true" >&2
  exit 1
}

refuse_demo() {
  echo "error: Play AAB must not be built with DEMO_BUILD." >&2
  echo "DEMO_BUILD forces AdMob test units. Play builds use production ad units." >&2
  exit 1
}

refuse_define_file() {
  echo "error: --dart-define-from-file is missing or unreadable: $1" >&2
  exit 1
}

refuse_debug_cert() {
  echo "error: Play AAB is signed with the Android debug certificate (CN=Android Debug)." >&2
  echo "Release bundles must use the Play upload key. See docs/android-play-internal-test.md." >&2
  exit 1
}

# Subjects from a signed jar, apk, or aab. apksigner prints
# "Signer #1 certificate DN: CN=...". keytool -printcert -jarfile prints
# "Owner: CN=...". Either is enough. Missing tools are skipped.
aab_cert_subjects() {
  local bundle="$1"
  if command -v apksigner >/dev/null 2>&1; then
    apksigner verify --print-certs "$bundle" 2>/dev/null || true
  fi
  if command -v keytool >/dev/null 2>&1; then
    keytool -printcert -jarfile "$bundle" 2>/dev/null || true
  fi
}

assert_not_debug_signed() {
  local bundle="$1"
  if [[ ! -f "$bundle" ]]; then
    echo "error: release bundle not found: $bundle" >&2
    exit 1
  fi
  local subjects
  subjects="$(aab_cert_subjects "$bundle")"
  if grep -q 'CN=Android Debug' <<<"$subjects"; then
    refuse_debug_cert
  fi
  if ! grep -Eq 'CN=|Owner:' <<<"$subjects"; then
    echo "error: could not read a signing certificate from $bundle (tried apksigner and keytool)." >&2
    exit 1
  fi
}

# Fail closed when the defines file cannot be read. Refuse when its text
# contains either blocked define (JSON or .env).
check_define_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    refuse_define_file "$file"
  fi
  if grep -q 'ENABLE_ADMIN_TOOLS' "$file"; then
    refuse_admin
  fi
  if grep -q 'DEMO_BUILD' "$file"; then
    refuse_demo
  fi
}

check_blocked_defines() {
  if env | grep -q '^ENABLE_ADMIN_TOOLS='; then
    refuse_admin
  fi
  if env | grep -q '^DEMO_BUILD='; then
    refuse_demo
  fi

  local args=("$@")
  local i=0
  while [[ $i -lt ${#args[@]} ]]; do
    local arg="${args[$i]}"
    case "$arg" in
      --dart-define-from-file)
        i=$((i + 1))
        if [[ $i -ge ${#args[@]} ]]; then
          echo "error: --dart-define-from-file requires a path." >&2
          exit 1
        fi
        check_define_file "${args[$i]}"
        ;;
      --dart-define-from-file=*)
        check_define_file "${arg#--dart-define-from-file=}"
        ;;
      *ENABLE_ADMIN_TOOLS*)
        refuse_admin
        ;;
      *DEMO_BUILD*)
        refuse_demo
        ;;
    esac
    i=$((i + 1))
  done
}

if [[ "${1:-}" == "--verify-signing" ]]; then
  assert_not_debug_signed "${2:?bundle path required}"
  exit 0
fi

check_blocked_defines "$@"

scripts/check_android_smoke_gate.sh

flutter build appbundle --release "$@"
assert_not_debug_signed "build/app/outputs/bundle/release/app-release.aab"
