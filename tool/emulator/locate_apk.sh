#!/usr/bin/env bash
# Pick the APK produced by resolve_apk.sh, download-artifact, or flutter build.
set -euo pipefail

root="${GITHUB_WORKSPACE:-.}"
mapfile -t found < <(
  find \
    "${root}/emulator-apk-download" \
    "${root}/downloaded-artifact" \
    "${root}/build-src/build/app/outputs" \
    "${root}/build/app/outputs" \
    -name '*.apk' -type f 2>/dev/null | sort
)

if [[ ${#found[@]} -eq 0 ]]; then
  echo "No APK was downloaded or built. Set apk_url, artifact_run_id plus artifact_name, or ref." >&2
  exit 1
fi

choose=""
for candidate in "${found[@]}"; do
  base="$(basename "$candidate")"
  if [[ "$base" == "app-debug.apk" ]]; then
    choose="$candidate"
    break
  fi
done
if [[ -z "$choose" ]]; then
  for candidate in "${found[@]}"; do
    base="$(basename "$candidate")"
    if [[ "$base" == "app-release.apk" || "$base" == "app.apk" ]]; then
      choose="$candidate"
      break
    fi
  done
fi
if [[ -z "$choose" ]]; then
  if [[ ${#found[@]} -eq 1 ]]; then
    choose="${found[0]}"
  else
    printf 'More than one APK and none is app-debug.apk or app-release.apk:\n' >&2
    printf '  %s\n' "${found[@]}" >&2
    exit 1
  fi
fi

echo "Using APK ${choose}"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  printf 'apk=%s\n' "$choose" >> "$GITHUB_OUTPUT"
fi
if [[ -n "${GITHUB_ENV:-}" ]]; then
  printf 'EMULATOR_APK=%s\n' "$choose" >> "$GITHUB_ENV"
fi
