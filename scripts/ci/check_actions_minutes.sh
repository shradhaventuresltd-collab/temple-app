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
# The total compared with 1,500 is analyze-test minutes plus android-smoke
# minutes for this repository. Other workflows are not included. BILLING_TOKEN,
# when it works, is recorded as an account-wide note and does not replace
# that total. Other private repositories are not in the total.
set -euo pipefail

budget_minutes=2000
threshold_minutes=1500

# Exit 0 when usage is at or above 75% of the 2,000 minute budget.
minutes_at_or_over_threshold() {
  awk -v used="$1" -v limit="$threshold_minutes" 'BEGIN { exit !(used + 0 >= limit) }'
}

# Workflow files whose billable minutes share one total.
minutes_workflows() {
  printf '%s\n' "ci.yml" "android-smoke.yml"
}

sum_minutes() {
  awk -v a="$1" -v b="$2" 'BEGIN { printf "%.2f", (a + 0) + (b + 0) }'
}

# Exact instruction written to the actions-minutes issue at 1,500 minutes.
minutes_over_budget_action() {
  printf '%s\n' "Change the android-smoke cron to two runs a day, 10 AM and 10 PM IST (cron '30 4,16 * * *')."
}

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  return 0 2>/dev/null || exit 0
fi

repo="${GITHUB_REPOSITORY:?}"
owner="${repo%%/*}"
source_label=""
used=""
included_note=""
billing_note=""
month_start="$(date -u +%Y-%m-01)"
today="$(date -u +%Y-%m-%d)"

# Billable minutes for one workflow file during the current calendar month.
workflow_minutes() {
  local workflow_file="$1"
  local ids id ms total_ms=0
  ids="$(gh api --paginate "repos/${repo}/actions/workflows/${workflow_file}/runs?created=${month_start}..${today}&per_page=100" --jq '.workflow_runs[].id')"
  if [[ -n "$ids" ]]; then
    while IFS= read -r id; do
      [[ -z "$id" ]] && continue
      ms="$(gh api "repos/${repo}/actions/runs/${id}/timing" --jq '[(.billable // {}) | to_entries[].value.total_ms] | add // 0' 2>/dev/null || echo 0)"
      case "$ms" in
        ''|null|*[!0-9]*) ms=0 ;;
      esac
      total_ms=$((total_ms + ms))
    done <<<"$ids"
  fi
  awk -v ms="$total_ms" 'BEGIN { printf "%.2f", ms / 60000 }'
}

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
  billing_used="$(python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["total_minutes_used"])' <<<"$body")"
  local included
  included="$(python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("included_minutes", ""))' <<<"$body")"
  if [[ -n "$included" ]]; then
    included_note="Billing reported included_minutes=${included}. This check still uses the ${budget_minutes} free private-minute budget."
  fi
}

analyze_minutes="$(workflow_minutes ci.yml)"
smoke_minutes="$(workflow_minutes android-smoke.yml)"
used="$(sum_minutes "$analyze_minutes" "$smoke_minutes")"
source_label="Sum of billable Actions minutes for analyze-test (ci.yml) and android-smoke (android-smoke.yml) in ${repo} from ${month_start} through ${today} UTC."

if [[ -n "${BILLING_TOKEN:-}" ]]; then
  billing_used=""
  if try_billing "https://api.github.com/users/${owner}/settings/billing/actions" \
    || try_billing "https://api.github.com/orgs/${owner}/settings/billing/actions"; then
    billing_note="Account-wide billing reported ${billing_used} minutes. The 1,500 check uses analyze-test plus android-smoke (${used} minutes), not the account-wide figure."
  else
    echo "BILLING_TOKEN could not read plan billing. The 1,500 check uses analyze-test plus android-smoke only." >&2
  fi
else
  echo "BILLING_TOKEN is not set. Counting analyze-test and android-smoke minutes for this repository." >&2
fi

echo "Actions minutes used: ${used} / ${budget_minutes} (${source_label})"

if ! minutes_at_or_over_threshold "$used"; then
  echo "Under 75% (${threshold_minutes} minutes). No issue."
  exit 0
fi

body_file="$(mktemp)"
action="$(minutes_over_budget_action)"
{
  echo "Actions usage is at or above 1,500 of 2,000 free private minutes."
  echo
  echo "- analyze-test: ${analyze_minutes} minutes"
  echo "- android-smoke: ${smoke_minutes} minutes"
  echo "- Total: ${used} minutes (analyze-test and android-smoke together)"
  echo "- Budget: ${budget_minutes} minutes"
  echo "- Threshold: ${threshold_minutes} minutes (75%)"
  echo "- Source: ${source_label}"
  if [[ -n "$billing_note" ]]; then
    echo "- ${billing_note}"
  fi
  if [[ -n "$included_note" ]]; then
    echo "- ${included_note}"
  fi
  echo
  echo "${action}"
  echo
  echo "The android-smoke schedule stays four runs a day until that cron is changed."
  echo
  echo "Checked at ${today} UTC by the actions-minutes workflow."
} >"$body_file"
echo "${action}"

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
