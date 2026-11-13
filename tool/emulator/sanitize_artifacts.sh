#!/usr/bin/env bash
# sanitize_artifacts.sh DIR: before upload-artifact. Renames any file or
# directory whose name has a character upload-artifact rejects
# (" : < > | * ? CR LF, run 41391038302 shard 11) by replacing each with
# '_', and fails if DIR/results.txt is missing, so a shard never uploads
# an artifact the summary job cannot merge.
set -uo pipefail
dir="${1:?artifact dir}"
if [[ ! -s "${dir}/results.txt" ]]; then
  echo "::error::${dir}/results.txt is missing or empty; this shard reported nothing"
  exit 1
fi
renamed=0
# Deepest first, so a renamed directory does not hide its children.
while IFS= read -r -d '' path; do
  base="$(basename "$path")"
  safe="$(printf '%s' "$base" | tr ':"<>|*?\r\n' '_________')"
  if [[ "$safe" != "$base" ]]; then
    mv -f -- "$path" "$(dirname "$path")/${safe}"
    echo "renamed: ${path} -> ${safe}"
    renamed=$((renamed + 1))
  fi
done < <(find "$dir" -mindepth 1 -depth -print0)
echo "artifact names checked: ${renamed} renamed"
exit 0
