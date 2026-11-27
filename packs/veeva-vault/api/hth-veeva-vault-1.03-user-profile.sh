#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: veeva-vault-1.3
#   guide: https://howtoharden.com/guides/veeva-vault/#13-read-one-vault-user-security-profile
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq, one authorized Vault API access token and User object ID
# Source (checked 2026-11-27): https://general.veevavault.dev/commercial/vault-api/api-reference/26.2/vault-query-language-vql/submitting-a-query/
# Review locally; protect evidence from unnecessary disclosure.

# HTH Guide Excerpt: begin veeva-vault-evidence
set +x
set -euo pipefail
: "${HTH_VAULT_SLUG:?Set the approved Vault subdomain.}"
: "${HTH_VAULT_USER_OBJECT_ID:?Set the approved user__sys record ID.}"
: "${HTH_VAULT_API_TOKEN:?Set the approved per-Vault API access token.}"
[[ "$HTH_VAULT_SLUG" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ &&
   "$HTH_VAULT_USER_OBJECT_ID" =~ ^[A-Za-z0-9]{1,40}$ &&
   "$HTH_VAULT_API_TOKEN" =~ ^veeva-vault-[A-Za-z0-9_-]+$ ]] ||
  { printf 'Invalid Vault slug, object ID or API token.\n' >&2; exit 2; }
printf 'Authorization: Bearer %s\n' "$HTH_VAULT_API_TOKEN" |
  curl -q --silent --show-error --fail --proto '=https' --connect-timeout 10 --max-time 30 --header @- \
    --header 'Accept: application/json' \
    --data-urlencode "q=SELECT id, security_profile__sys, status__v FROM user__sys WHERE id = '$HTH_VAULT_USER_OBJECT_ID'" \
    "https://$HTH_VAULT_SLUG.veevavault.com/api/v26.2/query" |
  jq -es --arg id "$HTH_VAULT_USER_OBJECT_ID" '
    if length == 1 and .[0].responseStatus == "SUCCESS"
      and .[0].responseDetails.total == 1 and (.[0].data | length) == 1
      and (.[0].data[0].id | tostring) == $id
      and (.[0].data[0].security_profile__sys | type) == "string"
      and (.[0].data[0].status__v | type) == "array"
      then .[0].data[0] | {id,security_profile: .security_profile__sys,status: .status__v}
      else error("Unexpected user/profile or incomplete Vault response") end'
# HTH Guide Excerpt: end veeva-vault-evidence
