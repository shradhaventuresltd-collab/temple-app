#!/usr/bin/env bash
# Release-gate line for the summary job. Usage:
#   release_gate.sh TIER SHA SOURCE   (SOURCE: build | url | artifact)
# Only a build-mode run tested the APK built from SHA. With apk_url or
# artifact inputs SHA is just this run's commit, not the APK's, so it is
# printed as unverified and must not be used as a release gate.
# Writes to GITHUB_STEP_SUMMARY when set, and to stdout.
set -euo pipefail
tier="${1:?tier}" sha="${2:?sha}" source="${3:?source}"
if [[ ! "$sha" =~ ^[0-9a-f]{40}$ ]]; then
  echo "build did not report a full SHA: '${sha}'" >&2
  exit 1
fi
tick='`'
case "$source" in
  build)
    line="Emulator **${tier}** suite ran on commit ${tick}${sha}${tick}."
    ;;
  url|artifact)
    line="Emulator **${tier}** suite ran on an APK from ${source} input; run commit ${tick}${sha}${tick}: SHA UNVERIFIED, not valid as release gate."
    ;;
  *)
    echo "release_gate.sh: unknown APK source '${source}'" >&2
    exit 1
    ;;
esac
echo "$line"
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  printf '### Release gate\n\n%s\n\n' "$line" >> "$GITHUB_STEP_SUMMARY"
fi
