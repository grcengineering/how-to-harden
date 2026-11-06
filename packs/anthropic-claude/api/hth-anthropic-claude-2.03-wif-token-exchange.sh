#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: anthropic-api-1.3
#   guide: https://howtoharden.com/guides/anthropic-api/#13-eliminate-static-api-keys-via-workload-identity-federation
#   profile: L2
#   mode: mutating
#   requires: ANTHROPIC_FEDERATION_RULE_ID, ANTHROPIC_ORGANIZATION_ID, ANTHROPIC_IDENTITY_TOKEN_FILE
# Source: https://platform.claude.com/docs/en/manage-claude/wif-reference
# Credential exchange is opt-in. No inference call or token printing/storage.
set -euo pipefail
# HTH Guide Excerpt: begin wif-preflight-and-optional-exchange
for name in ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_PROFILE; do
  if [[ "${!name+x}" == x ]]; then
    echo "Unset ${name} entirely before WIF (empty values still select a source)." >&2
    exit 2
  fi
done
[[ "${ANTHROPIC_API_BASE:-https://api.anthropic.com}" == https://api.anthropic.com ]] || exit 2
: "${ANTHROPIC_FEDERATION_RULE_ID:?Use a reviewed federation rule}"
: "${ANTHROPIC_ORGANIZATION_ID:?Use its organization UUID}"
: "${ANTHROPIC_IDENTITY_TOKEN_FILE:?Use the projected OIDC token file}"
[[ "${ANTHROPIC_FEDERATION_RULE_ID}" =~ ^fdrl_[A-Za-z0-9]+$ ]] || exit 2
[[ "${ANTHROPIC_ORGANIZATION_ID}" =~ ^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$ ]] || exit 2
[[ -r "${ANTHROPIC_IDENTITY_TOKEN_FILE}" ]] || exit 2
[[ -z "${ANTHROPIC_WORKSPACE_ID:-}" || "${ANTHROPIC_WORKSPACE_ID}" =~ ^wrkspc_[A-Za-z0-9]+$ ]] || exit 2
[[ -z "${ANTHROPIC_SERVICE_ACCOUNT_ID:-}" || "${ANTHROPIC_SERVICE_ACCOUNT_ID}" =~ ^svac_[A-Za-z0-9]+$ ]] || exit 2
if [[ "${HTH_EXCHANGE:-0}" != 1 ]]; then
  echo 'Preflight complete; no token minted. Review the rule and set HTH_EXCHANGE=1 for an explicit exchange.'
  exit 0
fi
# JSON escaping via jq; neither JWT nor access token enters argv.
body=$(jq -cn --rawfile jwt "${ANTHROPIC_IDENTITY_TOKEN_FILE}" \
  --arg rule "${ANTHROPIC_FEDERATION_RULE_ID}" --arg org "${ANTHROPIC_ORGANIZATION_ID}" \
  --arg account "${ANTHROPIC_SERVICE_ACCOUNT_ID:-}" --arg workspace "${ANTHROPIC_WORKSPACE_ID:-}" '
  ($jwt | sub("[\\r\\n]+$";"")) as $token |
  if ($token | test("^[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+$")) then
    {grant_type:"urn:ietf:params:oauth:grant-type:jwt-bearer",assertion:$token,federation_rule_id:$rule,organization_id:$org}
    + (if $account == "" then {} else {service_account_id:$account} end)
    + (if $workspace == "" then {} else {workspace_id:$workspace} end)
  else error("Expected a JWT") end')
response=$(printf '%s' "${body}" | curl -q --silent --show-error --fail --proto '=https' --connect-timeout 10 --max-time 30 \
  --header 'Content-Type: application/json' --data-binary @- https://api.anthropic.com/v1/oauth/token) || {
    echo 'Exchange failed; response content suppressed.' >&2; exit 1;
  }
printf '%s' "${response}" | jq -cse 'if length == 1 and (.[0].access_token | type) == "string"
  and (.[0].access_token | startswith("sk-ant-oat01-")) and (.[0].expires_in | type) == "number"
  and .[0].expires_in > 0 and (.[0].scope | type) == "string"
  then {exchange_verified:true,scope:.[0].scope,expires_in:.[0].expires_in}
  else error("Unexpected exchange response") end'
unset body response
# HTH Guide Excerpt: end wif-preflight-and-optional-exchange
