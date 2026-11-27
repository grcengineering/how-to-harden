#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: expensify-1.3
#   guide: https://howtoharden.com/guides/expensify/#13-verify-integration-credential-workspace-scope
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq, OAuth access token authorized for the selected policy
# Source (checked 2026-11-27): https://integrations.expensify.com/Integration-Server/doc/index.html
# Review locally; protect evidence from unnecessary disclosure.

# HTH Guide Excerpt: begin expensify-evidence
set +x
set -euo pipefail
: "${HTH_EXPENSIFY_ACCESS_TOKEN:?Set a current authorized OAuth access token.}"
: "${HTH_EXPENSIFY_POLICY_ID:?Set your exact workspace policy ID.}"
[[ "$HTH_EXPENSIFY_ACCESS_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ && "$HTH_EXPENSIFY_POLICY_ID" =~ ^[A-Za-z0-9_-]+$ ]] ||
  { printf 'Invalid token or policy ID.\n' >&2; exit 2; }
printf '%s' "$HTH_EXPENSIFY_ACCESS_TOKEN" |
  jq -Rsc '{type:"get",credentials:{authToken:.},inputSettings:{type:"policyList"}}' |
  curl -q --silent --show-error --fail --proto '=https' --connect-timeout 10 --max-time 30 \
    --data-urlencode 'requestJobDescription@-' 'https://integrations.expensify.com/Integration-Server/ExpensifyIntegrations' |
  jq -e -s --arg id "$HTH_EXPENSIFY_POLICY_ID" '
    if length != 1 or .[0].responseCode != 200 or (.[0].policyList | type) != "array"
    then error("Policy inventory unavailable") else .[0].policyList end
    | map(select(.id == $id))
    | if length != 1 or (.[0].role | IN("admin","auditor","user") | not)
      then error("Expected policy and documented role not found")
      else .[0] | {id,role} end'
# HTH Guide Excerpt: end expensify-evidence
