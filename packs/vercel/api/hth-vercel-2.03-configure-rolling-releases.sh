#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 2.3: Configure Rolling Releases
# Profile Level: L2 (Hardened)
# Frameworks: NIST CM-3(2)
# Source: https://howtoharden.com/guides/vercel/#23-configure-rolling-releases
# =============================================================================

set -euo pipefail

# HTH Guide Excerpt: begin api

# --- Check current project deployment settings ---
echo "=== Project Deployment Configuration ==="
curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  "https://api.vercel.com/v9/projects/${VERCEL_PROJECT_ID}?teamId=${VERCEL_TEAM_ID}" | \
  jq '{
    name: .name,
    framework: .framework,
    productionDeploymentWorkflow: .productionDeploymentWorkflow,
    skewProtection: .skewProtection
  }'

# --- List recent deployments with rollout status ---
echo ""
echo "=== Recent Deployments ==="
curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  "https://api.vercel.com/v6/deployments?projectId=${VERCEL_PROJECT_ID}&teamId=${VERCEL_TEAM_ID}&limit=5" | \
  jq '.deployments[] | {uid, state, createdAt, meta: .meta.githubCommitMessage}'

# --- Verify skew protection is enabled ---
echo ""
echo "=== Skew Protection Status ==="
curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  "https://api.vercel.com/v9/projects/${VERCEL_PROJECT_ID}?teamId=${VERCEL_TEAM_ID}" | \
  jq '.skewProtection // "not configured"'

# HTH Guide Excerpt: end api
