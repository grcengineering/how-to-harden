#!/usr/bin/env bash
# HTH Anthropic Claude Control 2.3: Eliminate Static API Keys via Workload Identity Federation
# Profile: L2 | NIST: IA-5(1), IA-9, AC-3 | SOC 2: CC6.1
# https://howtoharden.com/guides/anthropic-claude/#23-eliminate-static-api-keys-via-workload-identity-federation
#
# Exchanges an OIDC JWT from your IdP for a short-lived Anthropic access token
# via the documented OAuth 2.0 token endpoint:
#   POST https://api.anthropic.com/v1/oauth/token
# Reference: https://platform.claude.com/docs/en/manage-claude/wif-reference
#
# Federation issuers, rules, and service accounts are created in the Claude
# Console (Settings → Workload identity) — there is no documented public REST
# admin endpoint for those resources, so this script focuses on the runtime
# token exchange and validation.

set -euo pipefail

# ── Inputs (set from your secrets manager / CI environment) ──
: "${ANTHROPIC_FEDERATION_RULE_ID:?Set ANTHROPIC_FEDERATION_RULE_ID (fdrl_...)}"
: "${ANTHROPIC_ORGANIZATION_ID:?Set ANTHROPIC_ORGANIZATION_ID (UUID — Settings → Organization)}"
: "${ANTHROPIC_SERVICE_ACCOUNT_ID:?Set ANTHROPIC_SERVICE_ACCOUNT_ID (svac_...)}"
: "${ANTHROPIC_IDENTITY_TOKEN_FILE:?Set ANTHROPIC_IDENTITY_TOKEN_FILE — path to your IdP's JWT}"
ANTHROPIC_API_BASE="${ANTHROPIC_API_BASE:-https://api.anthropic.com}"

# HTH Guide Excerpt: begin api-wif-token-exchange
# Read the IdP-issued JWT from the projected token file (Kubernetes / GHA / etc.)
JWT=$(cat "${ANTHROPIC_IDENTITY_TOKEN_FILE}")

# Build the token-exchange body — workspace_id is required when the rule
# is enabled for more than one workspace
WORKSPACE_FIELD=""
if [ -n "${ANTHROPIC_WORKSPACE_ID:-}" ]; then
  WORKSPACE_FIELD=$(printf ',\n  "workspace_id": "%s"' "${ANTHROPIC_WORKSPACE_ID}")
fi

RESPONSE=$(curl -sS -f --max-time 10 "${ANTHROPIC_API_BASE}/v1/oauth/token" \
  -H "content-type: application/json" \
  --data @- <<JSON
{
  "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
  "assertion": "${JWT}",
  "federation_rule_id": "${ANTHROPIC_FEDERATION_RULE_ID}",
  "organization_id": "${ANTHROPIC_ORGANIZATION_ID}",
  "service_account_id": "${ANTHROPIC_SERVICE_ACCOUNT_ID}"${WORKSPACE_FIELD}
}
JSON
)

ACCESS_TOKEN=$(echo "${RESPONSE}" | jq -r '.access_token')
EXPIRES_IN=$(echo "${RESPONSE}" | jq -r '.expires_in')
SCOPE=$(echo "${RESPONSE}" | jq -r '.scope')

# Sanity-check the prefix — federated tokens are sk-ant-oat01-…
case "${ACCESS_TOKEN}" in
  sk-ant-oat01-*) echo "Got federated access token (scope=${SCOPE}, expires_in=${EXPIRES_IN}s)" ;;
  *) echo "ERROR: token-exchange did not return an oat01 token: ${RESPONSE}" >&2; exit 1 ;;
esac
# HTH Guide Excerpt: end api-wif-token-exchange

# HTH Guide Excerpt: begin api-wif-call-messages
# Call the Claude API with the short-lived federated token (Bearer auth)
curl -sS -f "${ANTHROPIC_API_BASE}/v1/messages" \
  -H "authorization: Bearer ${ACCESS_TOKEN}" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  --data @- <<'JSON' | jq -r '.content[0].text'
{
  "model": "claude-sonnet-4-6",
  "max_tokens": 1024,
  "messages": [{"role": "user", "content": "Hello, Claude"}]
}
JSON
# HTH Guide Excerpt: end api-wif-call-messages

# HTH Guide Excerpt: begin api-wif-detect-static-keys-in-env
# Pre-deploy guardrail: fail the build if a static API key is present in
# the environment of a workload that is supposed to use WIF. ANTHROPIC_API_KEY
# sits ABOVE federation in the SDK's credential precedence chain, so a
# leftover key silently shadows federation.
for VAR in ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN; do
  if [ -n "${!VAR:-}" ]; then
    echo "FAIL: \$${VAR} is set; it will shadow Workload Identity Federation." >&2
    echo "      Unset it (\`unset ${VAR}\`) — empty-string also wins precedence." >&2
    exit 2
  fi
done
echo "OK: no static API key shadows the federation credentials"
# HTH Guide Excerpt: end api-wif-detect-static-keys-in-env
