#!/usr/bin/env bash
# Upload tester APKs with the Firebase CLI.
# Does not run Seed, Admin, Firestore, or any other Firebase write.
#
# Skips (exit 0) on a pull_request run and when App Distribution secrets
# are empty. Otherwise writes the service-account JSON to a temp file,
# points GOOGLE_APPLICATION_CREDENTIALS at it, and deletes that file
# before exiting. Release notes are the short SHA, the commit subject,
# and the Actions run URL.

set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"

if [[ "${GITHUB_EVENT_NAME:-}" == "pull_request" ]]; then
  echo "Skipping distribution on a pull_request run."
  exit 0
fi

missing=()
for name in FIREBASE_ANDROID_APP_ID FIREBASE_APP_DISTRIBUTION_SA_JSON; do
  if [[ -z "${!name:-}" ]]; then
    missing+=("$name")
  fi
done
if ((${#missing[@]})); then
  echo "Skipping distribution because these secrets are unavailable: ${missing[*]}"
  exit 0
fi

if (($# == 0)); then
  echo "error: no APK path given" >&2
  exit 1
fi

for apk in "$@"; do
  if [[ ! -f "$apk" ]]; then
    echo "error: apk not found: $apk" >&2
    exit 1
  fi
done

umask 077
base="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
sa="$(mktemp "$base/firebase-app-distro-sa.XXXXXX.json")"
notes="$(mktemp "$base/demo-release-notes.XXXXXX.txt")"
cleanup() {
  local status=$?
  rm -f -- "$sa" "$notes"
  exit "$status"
}
trap cleanup EXIT

printf '%s' "$FIREBASE_APP_DISTRIBUTION_SA_JSON" > "$sa"
chmod 600 "$sa"

py_status=0
python3 - "$sa" <<'PY' || py_status=$?
import json
import sys

path = sys.argv[1]
try:
    with open(path, encoding="utf-8") as handle:
        data = json.load(handle)
except Exception:
    sys.exit(2)
if (
    not isinstance(data, dict)
    or data.get("type") != "service_account"
    or "private_key" not in data
    or "client_email" not in data
):
    sys.exit(3)
PY
case "$py_status" in
  0) ;;
  2)
    echo "error: FIREBASE_APP_DISTRIBUTION_SA_JSON is not JSON" >&2
    exit 1
    ;;
  *)
    echo "error: FIREBASE_APP_DISTRIBUTION_SA_JSON is not a service account key" >&2
    exit 1
    ;;
esac

short="${GITHUB_SHA:?GITHUB_SHA is required}"
short="${short:0:7}"
subject="$(git log -1 --format=%s)"
run_url="${GITHUB_SERVER_URL:?}/${GITHUB_REPOSITORY:?}/actions/runs/${GITHUB_RUN_ID:?}"
printf '%s %s\n%s\n' "$short" "$subject" "$run_url" > "$notes"

export GOOGLE_APPLICATION_CREDENTIALS="$sa"

firebase_cli="${DEMO_FIREBASE_CLI:-$root/scripts/ci/firebase-cli/node_modules/.bin/firebase}"
if [[ ! -x "$firebase_cli" ]]; then
  echo "error: pinned firebase CLI is missing. Run npm ci in scripts/ci/firebase-cli." >&2
  exit 1
fi

for apk in "$@"; do
  "$firebase_cli" appdistribution:distribute "$apk" \
    --app "$FIREBASE_ANDROID_APP_ID" \
    --groups core-testers \
    --release-notes-file "$notes"
done
