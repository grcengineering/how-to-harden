#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 3.3: Configure Firewall Persistent Actions
# Profile Level: L2 (Walk)
# Frameworks: NIST SC-5, SI-4
# Source: https://howtoharden.com/guides/vercel/#33-configure-firewall-persistent-actions
# Reference: https://vercel.com/docs/vercel-firewall/vercel-waf/custom-rules#persistent-actions
# API: PATCH /v1/security/firewall/config (updateFirewallConfig) with
#      action "rules.insert". PUT on the same path REPLACES the whole firewall
#      config, so it is never used here. Persistence is the mitigate
#      "actionDuration" (the dashboard's "for" timeframe) -- there is no
#      "persistentAction" field. MUTATING: inserts two custom rules, or
#      updates them in place ("rules.update" by id) when a rule of the same
#      name is already in the active config, so a re-run adds no duplicates.
# Rationale: Persistent actions block repeat abusers BEFORE the request reaches
# the CDN, so blocked traffic does not count toward bandwidth/compute billing.
# =============================================================================

set -euo pipefail

: "${VERCEL_TOKEN:?Set VERCEL_TOKEN}"
: "${VERCEL_TEAM_ID:?Set VERCEL_TEAM_ID}"
: "${VERCEL_PROJECT_ID:?Set VERCEL_PROJECT_ID}"

# HTH Guide Excerpt: begin api

# WARNING: if the Terraform module manages this project's firewall
# (vercel_firewall_config, 3.1/3.2), its next apply REPLACES the whole config
# and removes these rules. Manage custom rules in one place, not both.

FW_URL="https://api.vercel.com/v1/security/firewall/config?projectId=${VERCEL_PROJECT_ID}&teamId=${VERCEL_TEAM_ID}"

# curl -f aborts on HTTP 4xx/5xx; a 2xx body carrying .error also fails the run.
fw_patch() {
  local resp
  resp="$(curl -fsS -X PATCH \
    -H "Authorization: Bearer ${VERCEL_TOKEN}" \
    -H "Content-Type: application/json" \
    "${FW_URL}" -d @-)"
  if echo "${resp}" | jq -e 'type == "object" and has("error")' >/dev/null; then
    echo "${resp}" | jq '.error' >&2
    return 1
  fi
  echo "OK"
}

# A re-run must not duplicate rules (each duplicate also spends the plan's
# custom-rule quota), so a rule whose name already exists in the ACTIVE config is
# updated in place with "rules.update" instead of inserted again.
fw_upsert() {
  local body name id
  body="$(cat)"
  name="$(printf '%s' "${body}" | jq -r '.value.name')"
  id="$(printf '%s' "${ACTIVE_JSON}" | jq -r --arg n "${name}" '[.rules[]? | select(.name == $n) | .id][0] // empty')"
  if [ -n "${id}" ]; then
    echo "(rule ${name} already exists as ${id}: updating it in place)"
    printf '%s' "${body}" | jq -c --arg id "${id}" '{action: "rules.update", id: $id, value: .value}' | fw_patch
  else
    printf '%s' "${body}" | fw_patch
  fi
}

# --- Read current (active) firewall configuration ---
echo "=== Current Firewall Configuration ==="
ACTIVE_JSON="$(curl -fsS -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  "https://api.vercel.com/v1/security/firewall/config/active?projectId=${VERCEL_PROJECT_ID}&teamId=${VERCEL_TEAM_ID}")"
printf '%s' "${ACTIVE_JSON}" | jq '{
    firewallEnabled,
    ruleCount: (.rules // [] | length),
    managedRules: (.managedRules // {} | keys),
    ipBlockCount: (.ips // [] | length)
  }'

# --- Persistent deny: block sources probing scanner paths for 24h on first
#     match (pre-CDN, zero billing cost) ---
echo ""
echo "=== Deploying Persistent-Action Block Rule ==="
fw_upsert <<'JSON'
{
  "action": "rules.insert",
  "id": null,
  "value": {
    "name": "hth-persistent-block-scanners",
    "description": "Block scanner IPs for 24h on hit to common probe paths",
    "active": true,
    "conditionGroup": [
      { "conditions": [ { "type": "path", "op": "pre", "value": "/.env" } ] },
      { "conditions": [ { "type": "path", "op": "pre", "value": "/.git" } ] },
      { "conditions": [ { "type": "path", "op": "pre", "value": "/wp-admin" } ] }
    ],
    "action": {
      "mitigate": {
        "action": "deny",
        "actionDuration": "24h"
      }
    }
  }
}
JSON

# --- Rate-limit authentication endpoints with a persistent follow-up ban ---
echo ""
echo "=== Deploying Auth Rate Limit with Persistent Ban ==="
fw_upsert <<'JSON'
{
  "action": "rules.insert",
  "id": null,
  "value": {
    "name": "hth-auth-rate-limit-persistent",
    "description": "Rate limit /api/auth/* and ban for 1h on violation",
    "active": true,
    "conditionGroup": [
      { "conditions": [ { "type": "path", "op": "pre", "value": "/api/auth" } ] }
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
        "actionDuration": "1h"
      }
    }
  }
}
JSON

# HTH Guide Excerpt: end api
