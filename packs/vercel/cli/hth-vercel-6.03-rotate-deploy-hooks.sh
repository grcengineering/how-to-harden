#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 6.3: Rotate Deploy Hooks
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5, SA-15
# Source: https://howtoharden.com/guides/vercel/#63-rotate-deploy-hooks
# Rationale: Deploy Hook URLs are unauthenticated — the URL IS the credential.
# Anyone with the URL can trigger a deployment. Rotate quarterly or on team
# membership changes.
# Reference: https://vercel.com/docs/deploy-hooks
# =============================================================================

set -euo pipefail

: "${VERCEL_TOKEN:?Set VERCEL_TOKEN}"
: "${VERCEL_TEAM_ID:?Set VERCEL_TEAM_ID}"
: "${VERCEL_PROJECT_ID:?Set VERCEL_PROJECT_ID}"

# HTH Guide Excerpt: begin cli

# --- 1. Inventory existing deploy hooks for this project ---
echo "=== Existing Deploy Hooks for ${VERCEL_PROJECT_ID} ==="
curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  "https://api.vercel.com/v1/projects/${VERCEL_PROJECT_ID}/deploy-hooks?teamId=${VERCEL_TEAM_ID}" | \
  jq '.[] | {id, name, ref, createdAt}'

# --- 2. Rotate: delete the old hook and create a new one with the same name/ref ---
# Usage: HTH_HOOK_ID=<hook_id> HTH_HOOK_NAME="ci-deploy" HTH_HOOK_REF="main" ./rotate.sh
rotate_hook() {
  local old_id="$1"
  local name="$2"
  local ref="$3"

  echo ""
  echo "=== Creating replacement hook: ${name} (ref: ${ref}) ==="
  local new_hook
  new_hook=$(curl -s -X POST \
    -H "Authorization: Bearer ${VERCEL_TOKEN}" \
    -H "Content-Type: application/json" \
    "https://api.vercel.com/v1/projects/${VERCEL_PROJECT_ID}/deploy-hooks?teamId=${VERCEL_TEAM_ID}" \
    -d "$(jq -n --arg name "${name}" --arg ref "${ref}" '{name: $name, ref: $ref}')")

  local new_url
  new_url=$(echo "${new_hook}" | jq -r '.url')
  echo "NEW URL: ${new_url}"
  echo "STORE THIS IN YOUR SECRETS MANAGER (not in git)"

  echo ""
  echo "=== Deleting old hook ${old_id} ==="
  curl -s -X DELETE \
    -H "Authorization: Bearer ${VERCEL_TOKEN}" \
    "https://api.vercel.com/v1/projects/${VERCEL_PROJECT_ID}/deploy-hooks/${old_id}?teamId=${VERCEL_TEAM_ID}"
  echo "Old hook ${old_id} deleted."
}

if [ -n "${HTH_HOOK_ID:-}" ] && [ -n "${HTH_HOOK_NAME:-}" ] && [ -n "${HTH_HOOK_REF:-}" ]; then
  rotate_hook "${HTH_HOOK_ID}" "${HTH_HOOK_NAME}" "${HTH_HOOK_REF}"
else
  echo ""
  echo "To rotate a specific hook, rerun with:"
  echo "  HTH_HOOK_ID=<id> HTH_HOOK_NAME=<name> HTH_HOOK_REF=<branch> $0"
fi

# --- 3. Detect deploy hooks committed to git (common mistake) ---
echo ""
echo "=== Scanning current git repo for leaked deploy hook URLs ==="
if command -v git >/dev/null 2>&1 && [ -d ".git" ]; then
  leaked=$(git grep -E 'api\.vercel\.com/v1/(integrations|projects)/[^/]+/deploy-hooks/[A-Za-z0-9]+' -- '*.yml' '*.yaml' '*.md' '*.sh' '*.ts' '*.js' '*.json' '*.tf' 2>/dev/null || true)
  if [ -n "${leaked}" ]; then
    echo "WARNING: Deploy hook URL pattern found in git history:"
    echo "${leaked}"
    echo "Action required: rotate these hooks and remove from git history (git-filter-repo or BFG)."
  else
    echo "No leaked deploy hook URLs detected in tracked files."
  fi
else
  echo "(Skipping — not in a git repo or git not installed.)"
fi

# HTH Guide Excerpt: end cli
