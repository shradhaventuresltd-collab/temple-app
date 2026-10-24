#!/usr/bin/env bash
# Decide where the emulator APK comes from and, for a direct URL, download it.
# Artifact downloads and Flutter builds are separate workflow steps.
set -euo pipefail

classify_inputs() {
  local url="$1"
  local run_id="$2"
  local name="$3"
  local ref="$4"

  if [[ -n "$url" ]]; then
    if [[ "$url" != https://* ]]; then
      echo "apk_url must be an https URL" >&2
      return 1
    fi
    if [[ "$url" == *"@"* ]]; then
      echo "apk_url must not embed credentials" >&2
      return 1
    fi
    echo url
    return 0
  fi

  if [[ -n "$run_id" || -n "$name" ]]; then
    if [[ -z "$run_id" || -z "$name" ]]; then
      echo "artifact_run_id and artifact_name must both be set" >&2
      return 1
    fi
    if [[ ! "$run_id" =~ ^[0-9]+$ ]]; then
      echo "artifact_run_id must be a numeric run id" >&2
      return 1
    fi
    echo artifact
    return 0
  fi

  if [[ -n "$ref" ]]; then
    if [[ "$ref" =~ [[:space:]] || "$ref" == -* ]]; then
      echo "ref must be a branch, tag, or commit without spaces" >&2
      return 1
    fi
    echo build
    return 0
  fi

  echo "No APK source. Set apk_url, or artifact_run_id and artifact_name, or ref." >&2
  return 1
}

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  return 0
fi

url="${INPUT_APK_URL:-}"
run_id="${INPUT_ARTIFACT_RUN_ID:-}"
name="${INPUT_ARTIFACT_NAME:-}"
ref="${INPUT_REF:-}"

mode="$(classify_inputs "$url" "$run_id" "$name" "$ref")"

if [[ "$mode" == "url" ]]; then
  dest="${GITHUB_WORKSPACE:-.}/emulator-apk-download"
  mkdir -p "$dest"
  echo "Downloading APK from the given https URL"
  curl --fail --silent --show-error --location --output "${dest}/app.apk" "$url"
  python3 - "$dest/app.apk" <<'PY'
import sys
path = sys.argv[1]
magic = open(path, "rb").read(4)
if magic[:2] != b"PK":
    raise SystemExit("download is not an APK (missing zip header)")
print(f"downloaded {path}")
PY
fi

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  printf 'mode=%s\n' "$mode" >> "$GITHUB_OUTPUT"
fi
echo "APK source: ${mode}"
