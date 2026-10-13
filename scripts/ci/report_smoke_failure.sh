#!/usr/bin/env bash
# Open or update the single open issue labelled smoke-failure.
# Lists commits between the last green android-smoke SHA and this failure.
set -euo pipefail

repo="${GITHUB_REPOSITORY:?}"
failing="${FAILING_SHA:?}"
last="${LAST_GREEN_SHA:-}"
run_url="${RUN_URL:?}"

cd "$(dirname "$0")/../.."

commits="(could not list commits)"
if [[ -n "$last" ]]; then
  git cat-file -e "${last}^{commit}" 2>/dev/null || git fetch --no-tags origin "$last" || true
  if git cat-file -e "${last}^{commit}" 2>/dev/null; then
    count="$(git rev-list --count "${last}..${failing}" 2>/dev/null || echo "")"
    commits="$(git log -n 80 --format='%h %s' "${last}..${failing}" 2>/dev/null || true)"
    if [[ -z "$commits" ]]; then
      commits="(no commits between ${last} and ${failing})"
    elif [[ -n "$count" && "$count" -gt 80 ]]; then
      commits="${commits}
... ${count} commits total; showing 80."
    fi
  else
    commits="(last green SHA ${last} is not available in this clone)"
  fi
else
  commits="$(git log -n 20 --format='%h %s' "${failing}" 2>/dev/null || true)"
  commits="No previous successful android-smoke job.
${commits}"
fi

body_file="$(mktemp)"
{
  echo "Android smoke failed. Batch the fixes, then let the next scheduled run or a workflow_dispatch verify main."
  echo
  echo "- Failing SHA: \`${failing}\`"
  echo "- Last green SHA: \`${last:-none}\`"
  echo "- Run: ${run_url}"
  echo "- Artifacts (maestro-debug): ${run_url}#artifacts"
  echo
  echo "Commits between the last green SHA and the failing SHA:"
  echo
  echo '```'
  printf '%s\n' "$commits"
  echo '```'
} >"$body_file"

gh label create smoke-failure \
  --repo "$repo" \
  --color B60205 \
  --description "Open batch of android-smoke failures" \
  >/dev/null 2>&1 || true

existing="$(gh issue list --repo "$repo" --state open --label smoke-failure --limit 1 --json number --jq '.[0].number')"
title="android-smoke failed at ${failing:0:7}"

if [[ -z "$existing" || "$existing" == "null" ]]; then
  gh issue create --repo "$repo" --label smoke-failure --title "$title" --body-file "$body_file"
else
  gh issue edit "$existing" --repo "$repo" --title "$title" --body-file "$body_file"
  echo "Updated issue #${existing}."
fi
