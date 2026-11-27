#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: anodot-1.2
#   guide: https://howtoharden.com/guides/anodot/#12-review-privileged-users-and-group-coverage
#   profile: L1
#   mode: read-only
#   requires: Bash, curl, jq, ANODOT_HOST, ANODOT_BEARER_TOKEN, ANODOT_EXPECTED_ORG
# Vendor contract: https://support.anodot.com/reference/create-group
# HTH Guide Excerpt: begin summarize-user-privilege
set +x
set -euo pipefail

: "${ANODOT_HOST:?Set the approved account hostname with no scheme or path}"
: "${ANODOT_BEARER_TOKEN:?Inject the authorized short-lived Anodot API bearer token}"
[[ "$ANODOT_HOST" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.anodot\.com$ ]] || exit 2
[[ "$ANODOT_BEARER_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || exit 2

: "${ANODOT_EXPECTED_ORG:?Set the approved ownerOrganization ID from your admin records}"
[[ "$ANODOT_EXPECTED_ORG" =~ ^[A-Za-z0-9][A-Za-z0-9-]{0,127}$ ]] || exit 2

response=$(
  printf 'Authorization: Bearer %s\n' "$ANODOT_BEARER_TOKEN" |
    curl -q --fail --silent --show-error --proto '=https' --max-time 30 \
      --header @- --header 'Accept: application/json' \
      "https://$ANODOT_HOST/api/v2/users"
)

# The vendor's example sends a role array; normalize an enum string if returned.
jq -es --arg org "$ANODOT_EXPECTED_ORG" '
  def role_array: .roles | if type == "string" then [.] else . end;
  def admin: role_array | index("customer-admin") != null;
  def unknown_role: any(role_array[]; . != "customer-admin" and . != "customer-user");
  if length != 1 or (.[0] | type) != "array" or (.[0] | length) == 0
  then error("no verifiable Anodot user inventory")
  else .[0] end
  | if any(.[]; .ownerOrganization != $org or (.disabled | type) != "boolean" or
                 (.groups | type) != "array" or (role_array | type) != "array" or
                 (role_array | length) == 0 or any(role_array[]; type != "string"))
    then error("organization mismatch or malformed user metadata")
    else {users: length, active: ([.[] | select(.disabled == false)] | length),
          activeAdmins: ([.[] | select(.disabled == false and admin)] | length),
          activeWithUnrecognizedRole: ([.[] | select(.disabled == false and unknown_role)] | length),
          activeRegularUsersWithoutGroup: ([.[] | select(.disabled == false and (admin | not) and (unknown_role | not)
                                         and (.groups | length) == 0)] | length),
          disabled: ([.[] | select(.disabled)] | length)}
    end
' <<< "$response"
# HTH Guide Excerpt: end summarize-user-privilege
