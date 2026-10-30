#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-1.3
#   guide: https://howtoharden.com/guides/devin/#13-minimize-roles-and-service-users
#   profile: L1
#   mode: read-only
#   requires: DEVIN_API_KEY(enterprise service-user credential with role and membership read permissions), DEVIN_INVENTORY_OUTPUT(new private JSON output path), HTH_PROFILE_LEVEL(1 or higher)
# HTH Devin 1.3: Minimize Roles and Service Users
# Framework: NIST 800-53 AC-6
# Sources: https://docs.devin.ai/api-reference/authentication
#          https://docs.devin.ai/enterprise/security-access/custom-roles
#          https://docs.devin.ai/v3-openapi.json (v3 available, fetched 2026-10-29)
# Exit 0 = inventory collected, NOT least privilege proven; 2 = unknown/not run.
# Evidence contains identity metadata. Store outside version control with restricted access.
set +x
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin inventory-roles-and-service-users
hth_init 1
[[ -n "${DEVIN_INVENTORY_OUTPUT:-}" ]] || hth_unknown 'set DEVIN_INVENTORY_OUTPUT to a new evidence file'
hth_get '/v3/self' "$HTH_TEMP/self.json"
jq -e '.principal_type == "service_user" and (.service_user_id | type == "string")' \
  "$HTH_TEMP/self.json" >/dev/null || hth_unknown 'use a dedicated service user, not a personal token, for this inventory'
hth_paginate '/v3/enterprise/roles' "$HTH_TEMP/roles.jsonl"
hth_paginate '/v3/enterprise/members/service-users' "$HTH_TEMP/service-users.jsonl" 'include_inactive=true'
jq -se 'all(.[]; (.role_id | type == "string" and length > 0) and
  (.role_name | type == "string") and (.role_type == "enterprise" or .role_type == "org"))' \
  "$HTH_TEMP/roles.jsonl" >/dev/null || hth_unknown 'invalid role record'
jq -se 'all(.[]; (.service_user_id | type == "string") and (.name | type == "string") and
  has("expires_at") and has("deleted_at") and (.role_assignments | type == "array") and
  all(.role_assignments[]; (.role.role_id | type == "string")))' \
  "$HTH_TEMP/service-users.jsonl" >/dev/null || hth_unknown 'invalid service-user record'
# Role listings omit permissions; fetch each detail instead of inventing them.
(( $(jq -s 'length' "$HTH_TEMP/roles.jsonl") <= 1000 )) || hth_unknown 'more than 1000 roles; scope and review before collecting details'
: > "$HTH_TEMP/role-details.jsonl"
while IFS= read -r role_id; do
  hth_get "/v3/enterprise/roles/$(jq -rn --arg id "$role_id" '$id | @uri')" "$HTH_TEMP/role.json"
  jq -e --arg id "$role_id" '.role_id == $id and (.permissions | type == "array") and
    all(.permissions[]; type == "string")' "$HTH_TEMP/role.json" >/dev/null || hth_unknown 'role permissions missing or malformed'
  jq -c '.' "$HTH_TEMP/role.json" >> "$HTH_TEMP/role-details.jsonl"
done < <(jq -r '.role_id' "$HTH_TEMP/roles.jsonl")
jq -n --slurpfile identity "$HTH_TEMP/self.json" --slurpfile roles "$HTH_TEMP/role-details.jsonl" \
  --slurpfile service_users "$HTH_TEMP/service-users.jsonl" \
  '{identity:$identity[0],roles:$roles,service_users:$service_users}' > "$HTH_TEMP/inventory.json"
hth_save_private "$HTH_TEMP/inventory.json" "$DEVIN_INVENTORY_OUTPUT"
printf 'COLLECTED: %s roles and %s service users (including inactive); review the private inventory against approved access.\n' \
  "$(jq -s 'length' "$HTH_TEMP/roles.jsonl")" "$(jq -s 'length' "$HTH_TEMP/service-users.jsonl")"
# HTH Guide Excerpt: end inventory-roles-and-service-users
