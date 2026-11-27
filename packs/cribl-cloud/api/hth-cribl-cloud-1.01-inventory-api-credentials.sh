#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cribl-cloud-1.1
#   guide: https://howtoharden.com/guides/cribl-cloud/#11-restrict-organization-api-credentials
#   profile: L1
#   mode: read-only
#   requires: Bash, curl, jq, CRIBL_ORGANIZATION_ID, CRIBL_BEARER_TOKEN
# Vendor contract: https://docs.cribl.io/cribl-as-code/api-reference/management-plane/
# HTH Guide Excerpt: begin inventory-api-credentials
set +x
set -euo pipefail

: "${CRIBL_ORGANIZATION_ID:?Set the approved commercial Cloud organization ID}"
: "${CRIBL_BEARER_TOKEN:?Inject the authorized organization bearer token}"
[[ "$CRIBL_ORGANIZATION_ID" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]] || exit 2
[[ "$CRIBL_BEARER_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || exit 2

response=$(
  printf 'Authorization: Bearer %s\n' "$CRIBL_BEARER_TOKEN" |
    curl -q --fail --silent --show-error --proto '=https' --max-time 30 \
      --header @- "https://gateway.cribl.cloud/v1/organizations/$CRIBL_ORGANIZATION_ID/api-credentials"
)
jq -e --arg org "$CRIBL_ORGANIZATION_ID" '
  if (.items | type) != "array" then error("invalid credential inventory")
  elif (.count != (.items | length)) then error("credential count mismatch")
  elif any(.items[]; .organizationId != $org or ((.name | type) != "string") or
    ((.enabled | type) != "boolean") or ((.roles | type) != "object") or ((.ipAllowlist | type) != "array"))
  then error("invalid credential metadata")
  else {credentials: [.items[] | {name, enabled, roles, ipAllowlist}]} end
' <<< "$response"
# HTH Guide Excerpt: end inventory-api-credentials
