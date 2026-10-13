#!/usr/bin/env bash
# Refuse a Play release unless the android-smoke job succeeded on this exact HEAD.
#
# Token: GH_TOKEN or GITHUB_TOKEN, or `gh auth token` when gh is already logged in.
# The only bypass is a non-empty SMOKE_GATE_OVERRIDE. That prints a loud warning
# and continues. Do not set it for a Play upload unless you accept an unsmoked SHA.
#
# There is no release workflow in this repo. scripts/build_play_aab.sh calls
# this script. Any future release workflow must call it too, before it builds.
set -euo pipefail

cd "$(dirname "$0")/.."

sha="$(git rev-parse HEAD)"

if [[ -n "${SMOKE_GATE_OVERRIDE:-}" ]]; then
  cat >&2 <<EOF
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! SMOKE_GATE_OVERRIDE is set.
!!! This Play bundle is NOT gated on a successful android-smoke run.
!!! SHA: ${sha}
!!! Do not use this for a Play upload unless you accept that risk.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
EOF
  exit 0
fi

token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
if [[ -z "$token" ]] && command -v gh >/dev/null 2>&1; then
  if command -v timeout >/dev/null 2>&1; then
    token="$(timeout 10 gh auth token 2>/dev/null || true)"
  else
    token="$(gh auth token 2>/dev/null || true)"
  fi
fi

refuse() {
  echo "error: android-smoke gate: $*" >&2
  echo "A Play bundle requires a successful android-smoke job on ${sha}." >&2
  echo "Scheduled smoke is 10:00, 17:00, 22:00, and 05:00 IST, or workflow_dispatch." >&2
  echo "The only bypass is SMOKE_GATE_OVERRIDE=1." >&2
  exit 1
}

if [[ -z "$token" ]]; then
  refuse "no GH_TOKEN, GITHUB_TOKEN, or gh login to verify Actions for ${sha}."
fi

export GH_TOKEN="$token"

parse_origin_repo() {
  local remote="$1"
  remote="${remote%.git}"
  remote="${remote%/}"
  remote="${remote#https://}"
  remote="${remote#http://}"
  remote="${remote#ssh://}"
  remote="${remote#git@}"
  if [[ "$remote" == *"@"* ]]; then
    remote="${remote#*@}"
  fi
  remote="${remote#github.com/}"
  remote="${remote#github.com:}"
  if [[ "$remote" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
    printf '%s' "$remote"
  fi
}

repo="${GITHUB_REPOSITORY:-}"
if [[ -z "$repo" ]] && command -v gh >/dev/null 2>&1; then
  repo="$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || true)"
fi
if [[ -z "$repo" ]]; then
  repo="$(parse_origin_repo "$(git remote get-url origin 2>/dev/null || true)")"
fi
if [[ -z "$repo" ]]; then
  refuse "could not determine the GitHub repository."
fi

api_get() {
  local path="$1"
  if command -v gh >/dev/null 2>&1; then
    gh api "$path"
    return
  fi
  if ! command -v curl >/dev/null 2>&1; then
    refuse "neither gh nor curl is available to query the Actions API."
  fi
  curl -fsS \
    -H "Authorization: Bearer ${GH_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/${path}"
}

if ! command -v python3 >/dev/null 2>&1; then
  refuse "python3 is required to read the Actions API response."
fi

found_run=""
for page in 1 2; do
  if ! payload="$(api_get "repos/${repo}/actions/workflows/android-smoke.yml/runs?head_sha=${sha}&status=success&per_page=20&page=${page}")"; then
    refuse "could not list android-smoke runs for ${sha}."
  fi
  ids="$(python3 -c 'import json,sys
try:
    data=json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(2)
if "workflow_runs" not in data:
    sys.stderr.write(data.get("message","unexpected Actions response")+"\n")
    sys.exit(3)
print("\n".join(str(run["id"]) for run in data["workflow_runs"]))' <<<"$payload")" || refuse "could not parse android-smoke runs for ${sha}."
  if [[ -z "$ids" ]]; then
    break
  fi
  while IFS= read -r id; do
    [[ -z "$id" ]] && continue
    if ! jobs="$(api_get "repos/${repo}/actions/runs/${id}/jobs")"; then
      refuse "could not read jobs for Actions run ${id}."
    fi
    job_status=0
    python3 -c 'import json,sys
try:
    data=json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(2)
ok=any(j.get("name")=="android-smoke" and j.get("conclusion")=="success" for j in data.get("jobs",[]))
sys.exit(0 if ok else 1)' <<<"$jobs" || job_status=$?
    if [[ "$job_status" -eq 0 ]]; then
      found_run="$id"
      break
    elif [[ "$job_status" -ne 1 ]]; then
      refuse "could not parse jobs for Actions run ${id}."
    fi
  done <<<"$ids"
  if [[ -n "$found_run" ]]; then
    break
  fi
done

if [[ -z "$found_run" ]]; then
  refuse "no successful android-smoke job for ${sha}."
fi

echo "android-smoke gate: passed for ${sha} (run ${found_run})."
