#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 1.4: Harden API Token Lifecycle
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5, IA-4
# Source: https://howtoharden.com/guides/vercel/#14-harden-api-token-lifecycle
# =============================================================================

set -euo pipefail

# HTH Guide Excerpt: begin cli

# --- Audit existing tokens via Vercel API ---
echo "=== Auditing Vercel API Tokens ==="
curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  "https://api.vercel.com/v5/user/tokens" | \
  jq '.tokens[] | {id, name, activeAt, expiresAt, type}'

# --- List tokens with no expiration (security risk) ---
echo ""
echo "=== Tokens Without Expiration (ACTION REQUIRED) ==="
curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  "https://api.vercel.com/v5/user/tokens" | \
  jq '.tokens[] | select(.expiresAt == null) | {id, name, createdAt}'

# --- Create a scoped token with 90-day max expiration ---
echo ""
echo "=== Creating Scoped Token (example) ==="
# Uncomment and customize:
# curl -s -X POST -H "Authorization: Bearer ${VERCEL_TOKEN}" \
#   -H "Content-Type: application/json" \
#   "https://api.vercel.com/v5/user/tokens" \
#   -d '{
#     "name": "github-actions-deploy",
#     "expiresAt": '"$(($(date +%s) + 7776000))000"',
#     "type": "oauth2-token"
#   }'

# --- Verify OIDC federation status ---
echo ""
echo "=== OIDC Federation Status ==="
curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  "https://api.vercel.com/v1/teams/${VERCEL_TEAM_ID}" | \
  jq '{oidcTokenConfig: .oidcTokenConfig}'

# HTH Guide Excerpt: end cli
