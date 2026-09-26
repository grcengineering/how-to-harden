#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 2.3: Configure Rolling Releases
# Profile Level: L2 (Walk)
# Frameworks: NIST CM-3(2)
# Source: https://howtoharden.com/guides/vercel/#23-configure-rolling-releases
# API: GET /v9/projects/{idOrName} (skewProtectionMaxAge, rollingRelease),
#      GET /v1/projects/{idOrName}/rolling-release/config, GET /v7/deployments.
#      Read-only.
# =============================================================================

set -euo pipefail

: "${VERCEL_TOKEN:?Set VERCEL_TOKEN}"
: "${VERCEL_TEAM_ID:?Set VERCEL_TEAM_ID}"
: "${VERCEL_PROJECT_ID:?Set VERCEL_PROJECT_ID}"

# HTH Guide Excerpt: begin api

# curl -f: an HTTP 4xx/5xx aborts the audit instead of reporting nulls.
vercel_get() {
  curl -fsS -H "Authorization: Bearer ${VERCEL_TOKEN}" "https://api.vercel.com$1"
}

PROJECT_JSON="$(vercel_get "/v9/projects/${VERCEL_PROJECT_ID}?teamId=${VERCEL_TEAM_ID}")"

# --- Project deployment configuration ---
echo "=== Project Deployment Configuration ==="
echo "${PROJECT_JSON}" | jq '{name, framework, skewProtectionMaxAge, rollingRelease}'

# --- Rolling release configuration (stages, target, approval gate) ---
echo ""
echo "=== Rolling Release Configuration ==="
vercel_get "/v1/projects/${VERCEL_PROJECT_ID}/rolling-release/config?teamId=${VERCEL_TEAM_ID}" | \
  jq '.rollingRelease'

# --- Recent deployments ---
echo ""
echo "=== Recent Deployments ==="
vercel_get "/v7/deployments?projectId=${VERCEL_PROJECT_ID}&teamId=${VERCEL_TEAM_ID}&limit=5" | \
  jq '.deployments[] | {uid, state, target, createdAt, commit: .meta.githubCommitMessage}'

# --- Skew Protection is the prerequisite for a safe rollout ---
echo ""
echo "=== Skew Protection Status ==="
if [ "$(echo "${PROJECT_JSON}" | jq -r '.skewProtectionMaxAge // empty')" = "" ]; then
  echo "NOT CONFIGURED: skewProtectionMaxAge is unset -- enable Skew Protection first."
  exit 1
fi
echo "${PROJECT_JSON}" | jq '{skewProtectionMaxAge}'

# HTH Guide Excerpt: end api
