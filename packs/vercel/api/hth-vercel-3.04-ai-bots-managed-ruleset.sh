#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 3.4: Configure AI Bots Managed Ruleset
# Profile Level: L2 (Walk)
# Frameworks: NIST SC-7, SI-4
# Source: https://howtoharden.com/guides/vercel/#34-configure-ai-bots-managed-ruleset
# Reference: https://vercel.com/docs/vercel-firewall/vercel-waf/managed-rulesets#configure-ai-bots-managed-ruleset
# API: PATCH /v1/security/firewall/config with action "managedRules.update"
#      (id: ai_bots | bot_protection). PUT would REPLACE the whole config.
#      The same rulesets are also Terraform-managed via
#      vercel_firewall_config.managed_rulesets.{ai_bots,bot_protection}.
#      MUTATING: changes two managed-ruleset actions.
# Dashboard actions: AI Bots = Log | Deny; Bot Protection = Log | Challenge.
# =============================================================================

set -euo pipefail

: "${VERCEL_TOKEN:?Set VERCEL_TOKEN}"
: "${VERCEL_TEAM_ID:?Set VERCEL_TEAM_ID}"
: "${VERCEL_PROJECT_ID:?Set VERCEL_PROJECT_ID}"

# Start in log mode; after 7 days of observation re-run with HTH_AI_BOTS_ACTION=deny.
AI_BOTS_ACTION="${HTH_AI_BOTS_ACTION:-log}"
case "${AI_BOTS_ACTION}" in
  log|deny) ;;
  *) echo "HTH_AI_BOTS_ACTION must be log or deny" >&2; exit 2 ;;
esac

# HTH Guide Excerpt: begin api

FW_URL="https://api.vercel.com/v1/security/firewall/config?projectId=${VERCEL_PROJECT_ID}&teamId=${VERCEL_TEAM_ID}"

# curl -f aborts on HTTP 4xx/5xx; a 2xx body carrying .error also fails the run.
fw_patch() {
  local resp
  resp="$(curl -fsS -X PATCH \
    -H "Authorization: Bearer ${VERCEL_TOKEN}" \
    -H "Content-Type: application/json" \
    "${FW_URL}" -d "$1")"
  if echo "${resp}" | jq -e 'type == "object" and has("error")' >/dev/null; then
    echo "${resp}" | jq '.error' >&2
    return 1
  fi
  echo "OK"
}

# --- Currently active managed rulesets (the config field is managedRules) ---
echo "=== Active Managed Rulesets ==="
curl -fsS -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  "https://api.vercel.com/v1/security/firewall/config/active?projectId=${VERCEL_PROJECT_ID}&teamId=${VERCEL_TEAM_ID}" | \
  jq '.managedRules // {}'

# --- AI Bots Managed Ruleset: LOG first (observe before denying) ---
echo ""
echo "=== Setting AI Bots Managed Ruleset to ${AI_BOTS_ACTION} ==="
fw_patch "$(jq -n --arg a "${AI_BOTS_ACTION}" \
  '{action: "managedRules.update", id: "ai_bots", value: {active: true, action: $a}}')"

# --- Bot Protection Managed Ruleset: CHALLENGE ---
echo ""
echo "=== Enabling Bot Protection Managed Ruleset (challenge mode) ==="
fw_patch '{"action":"managedRules.update","id":"bot_protection","value":{"active":true,"action":"challenge"}}'

# HTH Guide Excerpt: end api
