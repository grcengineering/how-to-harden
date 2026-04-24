#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 3.4: Configure AI Bots Managed Ruleset
# Profile Level: L2 (Hardened)
# Frameworks: NIST SC-7, SI-4
# Source: https://howtoharden.com/guides/vercel/#34-configure-ai-bots-managed-ruleset
# Reference: https://vercel.com/docs/vercel-waf/managed-rulesets#configure-ai-bots-managed-ruleset
# Note: AI Bots and Bot Protection rulesets are currently dashboard/API-only
# (not exposed by the Vercel Terraform provider as of ~>2.0).
# =============================================================================

set -euo pipefail

: "${VERCEL_TOKEN:?Set VERCEL_TOKEN}"
: "${VERCEL_TEAM_ID:?Set VERCEL_TEAM_ID}"
: "${VERCEL_PROJECT_ID:?Set VERCEL_PROJECT_ID}"

# HTH Guide Excerpt: begin api

# --- List currently active managed rulesets ---
echo "=== Active Managed Rulesets ==="
curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  "https://api.vercel.com/v1/security/firewall/config/active?projectId=${VERCEL_PROJECT_ID}&teamId=${VERCEL_TEAM_ID}" | \
  jq '.managedRulesets // {}'

# --- Enable AI Bots Managed Ruleset in LOG mode first (observe before denying) ---
echo ""
echo "=== Enabling AI Bots Managed Ruleset (log mode) ==="
curl -s -X PUT \
  -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  -H "Content-Type: application/json" \
  "https://api.vercel.com/v1/security/firewall/config?projectId=${VERCEL_PROJECT_ID}&teamId=${VERCEL_TEAM_ID}" \
  -d @- <<'JSON' | jq '.'
{
  "action": "managedRules.update",
  "id": "ai_bots",
  "value": {
    "active": true,
    "action": "log"
  }
}
JSON

# --- Enable Bot Protection Managed Ruleset in CHALLENGE mode ---
echo ""
echo "=== Enabling Bot Protection Managed Ruleset (challenge mode) ==="
curl -s -X PUT \
  -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  -H "Content-Type: application/json" \
  "https://api.vercel.com/v1/security/firewall/config?projectId=${VERCEL_PROJECT_ID}&teamId=${VERCEL_TEAM_ID}" \
  -d @- <<'JSON' | jq '.'
{
  "action": "managedRules.update",
  "id": "bot_protection",
  "value": {
    "active": true,
    "action": "challenge"
  }
}
JSON

# --- After 7 days of LOG mode, flip AI Bots to DENY (manual review required) ---
echo ""
echo "=== Switch AI Bots to DENY after review (uncomment when ready) ==="
cat <<'REVIEW'
# Review the Firewall observability dashboard for 7 days to confirm no
# business-critical AI-assistant traffic is being matched. When ready:
#
# curl -X PUT \
#   -H "Authorization: Bearer ${VERCEL_TOKEN}" \
#   -H "Content-Type: application/json" \
#   "https://api.vercel.com/v1/security/firewall/config?projectId=${VERCEL_PROJECT_ID}&teamId=${VERCEL_TEAM_ID}" \
#   -d '{"action":"managedRules.update","id":"ai_bots","value":{"active":true,"action":"deny"}}'
REVIEW

# HTH Guide Excerpt: end api
