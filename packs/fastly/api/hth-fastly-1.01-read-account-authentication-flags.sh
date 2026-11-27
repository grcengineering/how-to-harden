#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: fastly-1.1
#   guide: https://howtoharden.com/guides/fastly/#11-enforce-two-factor-authentication
#   profile: L1
#   mode: read-only
#   requires: Bash, curl, jq, FASTLY_CUSTOMER_ID, FASTLY_API_TOKEN
# Fastly 1.1 | L1 | NIST IA-2 | https://howtoharden.com/guides/fastly/#11-enforce-two-factor-authentication
# Account flags only, not evidence of organization-tier enforcement.
# https://www.fastly.com/documentation/reference/api/account/customer/
# HTH Guide Excerpt: begin read-fastly-customer-authentication
set +x
set -euo pipefail

: "${FASTLY_CUSTOMER_ID:?Set a Fastly customer ID}"
: "${FASTLY_API_TOKEN:?Inject an authorized Fastly API token}"
[[ "$FASTLY_CUSTOMER_ID" =~ ^[A-Za-z0-9]+$ ]] || exit 2
[[ "$FASTLY_API_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || exit 2

response=$(
  printf 'Fastly-Key: %s\n' "$FASTLY_API_TOKEN" |
    curl -q --fail --silent --show-error --proto '=https' --max-time 30 \
      --header @- "https://api.fastly.com/customer/$FASTLY_CUSTOMER_ID"
)
jq -e --arg account "$FASTLY_CUSTOMER_ID" '
    if (.id != $account) or ((.force_2fa | type) != "boolean") or ((.force_sso | type) != "boolean")
    then error("invalid Fastly customer authentication response")
    else {customer_id: .id, force_2fa, force_sso}
    end' <<< "$response"
# HTH Guide Excerpt: end read-fastly-customer-authentication
