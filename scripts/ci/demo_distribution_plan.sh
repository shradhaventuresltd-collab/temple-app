#!/usr/bin/env bash
# Decide whether this run can sign a demo APK and whether it should
# upload that APK to Firebase App Distribution.
#
# A pull_request run skips distribution. An empty signing secret skips
# the signed build. An empty App Distribution secret skips distribution.
# Secret values are never printed. Missing secret names are.
#
# Writes sign= and distribute= to $GITHUB_OUTPUT when that file is set,
# and always prints those two lines on stdout.

set -euo pipefail

signing_secret_names=(
  DEMO_KEYSTORE_B64
  DEMO_KEYSTORE_PASSWORD
  DEMO_KEY_ALIAS
  DEMO_KEY_PASSWORD
)

distribution_secret_names=(
  FIREBASE_ANDROID_APP_ID
  FIREBASE_APP_DISTRIBUTION_SA_JSON
)

missing_secrets() {
  local name
  local missing=()
  for name in "$@"; do
    if [[ -z "${!name:-}" ]]; then
      missing+=("$name")
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
  if [[ -n "$(missing_secrets "${signing_secret_names[@]}")" ]]; then
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
  if [[ -n "$(missing_secrets "${distribution_secret_names[@]}")" ]]; then
    printf '%s\n' false
    return 0
  fi
  printf '%s\n' true
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  sign="$(demo_can_sign)"
  distribute="$(demo_should_distribute)"
  if [[ "$sign" != "true" ]]; then
    echo "Skipping the signed demo APK because these secrets are unavailable: $(missing_secrets "${signing_secret_names[@]}" | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
  fi
  if [[ "$distribute" == "true" ]]; then
    echo "Firebase App Distribution will run for core-testers."
  elif [[ "$(demo_event_name)" == "pull_request" ]]; then
    echo "Skipping distribution on a pull_request run."
  elif [[ "$sign" == "true" ]]; then
    echo "Skipping distribution because these secrets are unavailable: $(missing_secrets "${distribution_secret_names[@]}" | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
  fi
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    printf 'sign=%s\n' "$sign" >> "$GITHUB_OUTPUT"
    printf 'distribute=%s\n' "$distribute" >> "$GITHUB_OUTPUT"
  fi
  printf 'sign=%s\n' "$sign"
  printf 'distribute=%s\n' "$distribute"
fi
