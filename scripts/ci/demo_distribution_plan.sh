#!/usr/bin/env bash
# Decide whether this run can sign a demo APK and whether it should
# upload that APK to Firebase App Distribution.
#
# Callers pass HAS_* flags ("true" or "false") from
# `secrets.NAME != ''`. This script never reads secret values.
# A pull_request run skips distribution. A flag that is not "true"
# skips the signed build or distribution. Missing secret names are printed.
#
# Writes sign= and distribute= to $GITHUB_OUTPUT when that file is set,
# and always prints those two lines on stdout.

set -euo pipefail

signing_flags=(
  HAS_DEMO_KEYSTORE_B64
  HAS_DEMO_KEYSTORE_PASSWORD
  HAS_DEMO_KEY_ALIAS
  HAS_DEMO_KEY_PASSWORD
)

distribution_flags=(
  HAS_FIREBASE_ANDROID_APP_ID
  HAS_FIREBASE_APP_DISTRIBUTION_SA_JSON
)

secret_name() {
  case "$1" in
    HAS_DEMO_KEYSTORE_B64) printf '%s\n' DEMO_KEYSTORE_B64 ;;
    HAS_DEMO_KEYSTORE_PASSWORD) printf '%s\n' DEMO_KEYSTORE_PASSWORD ;;
    HAS_DEMO_KEY_ALIAS) printf '%s\n' DEMO_KEY_ALIAS ;;
    HAS_DEMO_KEY_PASSWORD) printf '%s\n' DEMO_KEY_PASSWORD ;;
    HAS_FIREBASE_ANDROID_APP_ID) printf '%s\n' FIREBASE_ANDROID_APP_ID ;;
    HAS_FIREBASE_APP_DISTRIBUTION_SA_JSON) printf '%s\n' FIREBASE_APP_DISTRIBUTION_SA_JSON ;;
    *) printf '%s\n' "$1" ;;
  esac
}

flag_is_true() {
  [[ "${!1:-}" == "true" ]]
}

missing_flags() {
  local name
  local missing=()
  for name in "$@"; do
    if ! flag_is_true "$name"; then
      missing+=("$(secret_name "$name")")
    fi
  done
  if ((${#missing[@]})); then
    printf '%s\n' "${missing[@]}"
  fi
}

demo_event_name() {
  printf '%s\n' "${GITHUB_EVENT_NAME:-}"
}

# Prints "true" or "false".
demo_can_sign() {
  if [[ -n "$(missing_flags "${signing_flags[@]}")" ]]; then
    printf '%s\n' false
  else
    printf '%s\n' true
  fi
}

# Prints "true" or "false". Distribution also requires a signed build.
demo_should_distribute() {
  if [[ "$(demo_event_name)" == "pull_request" ]]; then
    printf '%s\n' false
    return 0
  fi
  if [[ "$(demo_can_sign)" != "true" ]]; then
    printf '%s\n' false
    return 0
  fi
  if [[ -n "$(missing_flags "${distribution_flags[@]}")" ]]; then
    printf '%s\n' false
    return 0
  fi
  printf '%s\n' true
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  sign="$(demo_can_sign)"
  distribute="$(demo_should_distribute)"
  if [[ "$sign" != "true" ]]; then
    echo "Skipping the signed demo APK because these secrets are unavailable: $(missing_flags "${signing_flags[@]}" | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
  fi
  if [[ "$distribute" == "true" ]]; then
    echo "Firebase App Distribution will run for core-testers."
  elif [[ "$(demo_event_name)" == "pull_request" ]]; then
    echo "Skipping distribution on a pull_request run."
  elif [[ "$sign" == "true" ]]; then
    echo "Skipping distribution because these secrets are unavailable: $(missing_flags "${distribution_flags[@]}" | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
  fi
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    printf 'sign=%s\n' "$sign" >> "$GITHUB_OUTPUT"
    printf 'distribute=%s\n' "$distribute" >> "$GITHUB_OUTPUT"
  fi
  printf 'sign=%s\n' "$sign"
  printf 'distribute=%s\n' "$distribute"
fi
