#!/usr/bin/env bash
# HTH OneLogin Control 3.3: Protect Privileged Accounts
# Profile: L1 | CIS Controls: 5.4 | NIST 800-53: AC-6
# https://howtoharden.com/guides/onelogin/#33-protect-privileged-accounts
#
# Interface: OneLogin REST API v2 (first-party).
#   OAuth token: https://developers.onelogin.com/api-docs/2/oauth20-tokens/generate-tokens-2
#   List Roles:  https://developers.onelogin.com/api-docs/2/roles/list-roles
# The Roles API's fields parameter accepts "apps", "users", and "admins",
# which makes it the inventory surface for who holds administrative roles.
#
# Environment:
#   ONELOGIN_SUBDOMAIN      e.g. mycompany (for mycompany.onelogin.com)
#   ONELOGIN_CLIENT_ID      API credential pair client ID (Read All or higher)
#   ONELOGIN_CLIENT_SECRET  API credential pair client secret

set -euo pipefail
: "${ONELOGIN_SUBDOMAIN:?Set ONELOGIN_SUBDOMAIN}"
: "${ONELOGIN_CLIENT_ID:?Set ONELOGIN_CLIENT_ID}"
: "${ONELOGIN_CLIENT_SECRET:?Set ONELOGIN_CLIENT_SECRET}"
BASE_URL="https://${ONELOGIN_SUBDOMAIN}.onelogin.com"

# HTH Guide Excerpt: begin api-get-token
# Client-credentials access token (valid 10 hours).
ACCESS_TOKEN=$(curl -sf "${BASE_URL}/auth/oauth2/v2/token" \
  -X POST \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=client_credentials' \
  --data-urlencode "client_id=${ONELOGIN_CLIENT_ID}" \
  --data-urlencode "client_secret=${ONELOGIN_CLIENT_SECRET}" | jq -r '.access_token')
# HTH Guide Excerpt: end api-get-token

# HTH Guide Excerpt: begin api-role-admin-inventory
# Enumerate every role with its admins and members. Document each admin
# assignment, verify the business need, and flag roles whose admin list
# has grown beyond the documented set.
curl -sf "${BASE_URL}/api/2/roles?fields=admins,users" \
  -H "Authorization: bearer ${ACCESS_TOKEN}" |
  jq -r '.[] | "role=\(.id) name=\(.name // "-") admins=\((.admins // []) | length) users=\((.users // []) | length) admin_ids=\((.admins // []) | map(tostring) | join(","))"'
# HTH Guide Excerpt: end api-role-admin-inventory

# HTH Guide Excerpt: begin api-resolve-admin-users
# Resolve a privileged user ID from the inventory above to a named account
# (v2 Users API). Repeat per admin ID and record the mapping in the
# privileged-account register this control requires.
ADMIN_USER_ID="12345678"
curl -sf "${BASE_URL}/api/2/users?user_ids=${ADMIN_USER_ID}&fields=id,username,email,state,status,last_login" \
  -H "Authorization: bearer ${ACCESS_TOKEN}" | jq .
# HTH Guide Excerpt: end api-resolve-admin-users
