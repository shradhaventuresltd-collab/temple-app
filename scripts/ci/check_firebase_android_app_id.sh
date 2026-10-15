#!/usr/bin/env bash
# Confirm FIREBASE_ANDROID_APP_ID is the registered .demo Android app.
# Does not print the secret value.
set -euo pipefail

expected="1:109314154382:android:856cbde1eb92ba234ccedf"
actual="${FIREBASE_ANDROID_APP_ID-}"

if [[ "$actual" != "$expected" ]]; then
  printf '%s\n' \
    "error: FIREBASE_ANDROID_APP_ID is not the registered demo Android app id ${expected}." \
    "Set that GitHub secret to the mobilesdk_app_id for com.shradhaventures.temple.demo." \
    "The secret value was not printed." >&2
  exit 1
fi

echo "ok: FIREBASE_ANDROID_APP_ID is the registered demo Android app"
