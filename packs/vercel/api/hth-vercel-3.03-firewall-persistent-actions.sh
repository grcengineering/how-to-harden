#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 3.3: Configure Firewall Persistent Actions
# Profile Level: L2 (Hardened)
# Frameworks: NIST SC-5, SI-4
# Source: https://howtoharden.com/guides/vercel/#33-configure-firewall-persistent-actions
# Reference: https://vercel.com/docs/vercel-firewall/vercel-waf/custom-rules#persistent-actions
# Rationale: Persistent actions block repeat abusers BEFORE the request reaches
# the CDN, so blocked traffic does not count toward bandwidth/compute billing.
# =============================================================================

set -euo pipefail

: "${VERCEL_TOKEN:?Set VERCEL_TOKEN}"
: "${VERCEL_TEAM_ID:?Set VERCEL_TEAM_ID}"
: "${VERCEL_PROJECT_ID:?Set VERCEL_PROJECT_ID}"

# HTH Guide Excerpt: begin api

# --- Read current firewall configuration ---
echo "=== Current Firewall Configuration ==="
curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  "https://api.vercel.com/v1/security/firewall/config/active?projectId=${VERCEL_PROJECT_ID}&teamId=${VERCEL_TEAM_ID}" | \
  jq '{
    ruleCount: (.rules | length),
    managedRulesets: (.managedRulesets | keys),
    ipBlockCount: (.ips | length)
  }'

# --- Deploy a persistent-action rule that blocks sources hitting known
#     scanner paths for 24 hours on first match (pre-CDN, zero billing cost) ---
echo ""
echo "=== Deploying Persistent-Action Block Rule ==="
curl -s -X PUT \
  -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  -H "Content-Type: application/json" \
  "https://api.vercel.com/v1/security/firewall/config?projectId=${VERCEL_PROJECT_ID}&teamId=${VERCEL_TEAM_ID}" \
  -d @- <<'JSON' | jq '.'
{
  "action": "rules.insert",
  "id": null,
  "value": {
    "name": "hth-persistent-block-scanners",
    "description": "Block scanner IPs for 24h on hit to common probe paths",
    "active": true,
    "conditionGroup": [
      {
        "conditions": [
          {
            "type": "path",
            "op": "pre",
            "value": "/.env"
          }
        ]
      },
      {
        "conditions": [
          {
            "type": "path",
            "op": "pre",
            "value": "/.git"
          }
        ]
      },
      {
        "conditions": [
          {
            "type": "path",
            "op": "pre",
            "value": "/wp-admin"
          }
        ]
      }
    ],
    "action": {
      "mitigate": {
        "action": "deny",
        "actionDuration": "24h",
        "persistentAction": true
      }
    }
  }
}
JSON

# --- Rate-limit authentication endpoints with persistent follow-up ban ---
echo ""
echo "=== Deploying Auth Rate Limit with Persistent Ban ==="
curl -s -X PUT \
  -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  -H "Content-Type: application/json" \
  "https://api.vercel.com/v1/security/firewall/config?projectId=${VERCEL_PROJECT_ID}&teamId=${VERCEL_TEAM_ID}" \
  -d @- <<'JSON' | jq '.'
{
  "action": "rules.insert",
  "id": null,
  "value": {
    "name": "hth-auth-rate-limit-persistent",
    "description": "Rate limit /api/auth/* and ban for 1h on violation",
    "active": true,
    "conditionGroup": [
      {
        "conditions": [
          {
            "type": "path",
            "op": "pre",
            "value": "/api/auth"
          }
        ]
      }
    ],
    "action": {
      "mitigate": {
        "action": "rate_limit",
        "rateLimit": {
          "algo": "fixed_window",
          "window": 60,
          "limit": 20,
          "keys": ["ip"],
          "action": "deny"
        },
        "actionDuration": "1h",
        "persistentAction": true
      }
    }
  }
}
JSON

# HTH Guide Excerpt: end api
