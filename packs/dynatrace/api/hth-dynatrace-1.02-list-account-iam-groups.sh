#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: dynatrace-1.2
#   guide: https://howtoharden.com/guides/dynatrace/#12-limit-account-and-environment-role-grants
#   profile: L1
#   mode: read-only
#   requires: Bash, curl, jq, DT_ACCOUNT_UUID, DT_ACCOUNT_BEARER_TOKEN with account-idm-read
# Vendor contract: https://docs.dynatrace.com/docs/dynatrace-api/account-management-api/group-management-api/get-all-groups
# HTH Guide Excerpt: begin list-account-iam-groups
set +x
set -euo pipefail

: "${DT_ACCOUNT_UUID:?Set the approved SaaS account UUID}"
: "${DT_ACCOUNT_BEARER_TOKEN:?Inject an OAuth account token with account-idm-read}"
[[ "$DT_ACCOUNT_UUID" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]] || exit 2
[[ "$DT_ACCOUNT_BEARER_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || exit 2

response=$(
  printf 'Authorization: Bearer %s\n' "$DT_ACCOUNT_BEARER_TOKEN" |
    curl -q --fail --silent --show-error --proto '=https' --max-time 30 \
      --header @- "https://api.dynatrace.com/iam/v1/accounts/$DT_ACCOUNT_UUID/groups"
)
jq -e '
  if (.items | type) != "array" then error("invalid IAM group inventory")
  elif (.count != (.items | length)) then error("IAM group count mismatch")
  elif any(.items[]; ((.uuid | type) != "string") or ((.name | type) != "string"))
  then error("invalid IAM group metadata")
  else {count, groups: [.items[] | {uuid, name, owner}]} end
' <<< "$response"
# HTH Guide Excerpt: end list-account-iam-groups
