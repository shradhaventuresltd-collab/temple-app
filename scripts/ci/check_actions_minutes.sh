#!/usr/bin/env bash
# Compare GitHub Actions usage with the 2,000 minute private-repo budget.
# Opens or updates one issue labelled actions-minutes at or above 75% (1,500).
#
# Secret Sanu adds on the repository (optional, account-wide figure):
#   Name: BILLING_TOKEN
#   Fine-grained personal access token created by the owner of this
#   user-owned account (GITHUB_TOKEN cannot read billing here).
#   Account permission: Plan, Read-only.
#   Repository access: this repository is enough; Plan is an account permission.
#
# Without a usable BILLING_TOKEN, this script sums Actions run timings for
# this repository for the current calendar month. That estimate misses
# minutes used by other private repositories on the same account.
set -euo pipefail

budget_minutes=2000
threshold_minutes=1500

# Exit 0 when usage is at or above 75% of the 2,000 minute budget.
minutes_at_or_over_threshold() {
  awk -v used="$1" -v limit="$threshold_minutes" 'BEGIN { exit !(used + 0 >= limit) }'
}

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  return 0 2>/dev/null || exit 0
fi

repo="${GITHUB_REPOSITORY:?}"
owner="${repo%%/*}"
source_label=""
used=""
included_note=""

try_billing() {
  local url="$1"
  local body http
  body="$(curl -sS -H "Authorization: Bearer ${BILLING_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -w $'\n%{http_code}' \
    "$url" || true)"
  http="${body##*$'\n'}"
  body="${body%$'\n'*}"
  if [[ "$http" != "200" ]]; then
    echo "billing ${url} returned HTTP ${http}." >&2
    return 1
  fi
  used="$(python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["total_minutes_used"])' <<<"$body")"
  local included
  included="$(python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("included_minutes", ""))' <<<"$body")"
  if [[ -n "$included" ]]; then
    included_note="Billing reported included_minutes=${included}. This check still uses the ${budget_minutes} free private-minute budget."
  fi
  source_label="GitHub billing API via BILLING_TOKEN (account-wide)."
}

if [[ -n "${BILLING_TOKEN:-}" ]]; then
  if try_billing "https://api.github.com/users/${owner}/settings/billing/actions"; then
    :
  elif try_billing "https://api.github.com/orgs/${owner}/settings/billing/actions"; then
    :
  else
    echo "BILLING_TOKEN could not read plan billing. Falling back to a repo timing estimate." >&2
    used=""
  fi
else
  echo "BILLING_TOKEN is not set. Estimating from this repository's Actions timings." >&2
fi

if [[ -z "$used" ]]; then
  month_start="$(date -u +%Y-%m-01)"
  today="$(date -u +%Y-%m-%d)"
  ids="$(gh api --paginate "repos/${repo}/actions/runs?created=${month_start}..${today}&per_page=100" --jq '.workflow_runs[].id')"
  total_ms=0
  if [[ -n "$ids" ]]; then
    while IFS= read -r id; do
      [[ -z "$id" ]] && continue
      ms="$(gh api "repos/${repo}/actions/runs/${id}/timing" --jq '[(.billable // {}) | to_entries[].value.total_ms] | add // 0' 2>/dev/null || echo 0)"
      case "$ms" in
        ''|null) ms=0 ;;
      esac
      total_ms=$((total_ms + ms))
    done <<<"$ids"
  fi
  used="$(awk -v ms="$total_ms" 'BEGIN { printf "%.2f", ms / 60000 }')"
  source_label="Estimate: sum of Actions run timings for ${repo} from ${month_start} through ${today} UTC. Other private repositories on the account are not included. Add repository secret BILLING_TOKEN (fine-grained PAT, account permission Plan: Read-only) for the account-wide number."
fi

echo "Actions minutes used: ${used} / ${budget_minutes} (${source_label})"

if ! minutes_at_or_over_threshold "$used"; then
  echo "Under 75% (${threshold_minutes} minutes). No issue."
  exit 0
fi

body_file="$(mktemp)"
{
  echo "Actions usage is at or above 75% of the 2,000 free private minutes."
  echo
  echo "- Used: ${used} minutes"
  echo "- Budget: ${budget_minutes} minutes"
  echo "- Threshold: ${threshold_minutes} minutes (75%)"
  echo "- Source: ${source_label}"
  if [[ -n "$included_note" ]]; then
    echo "- ${included_note}"
  fi
  echo
  echo "Checked at ${today:-$(date -u +%Y-%m-%d)} UTC by the actions-minutes workflow."
} >"$body_file"

gh label create actions-minutes \
  --repo "$repo" \
  --color D93F0B \
  --description "Actions minutes at or above 75% of 2000" \
  >/dev/null 2>&1 || true

existing="$(gh issue list --repo "$repo" --state open --label actions-minutes --limit 1 --json number --jq '.[0].number')"
title="Actions minutes passed 75% of 2,000"
if [[ -z "$existing" || "$existing" == "null" ]]; then
  gh issue create --repo "$repo" --label actions-minutes --title "$title" --body-file "$body_file"
else
  gh issue edit "$existing" --repo "$repo" --title "$title" --body-file "$body_file"
  echo "Updated issue #${existing}."
fi
