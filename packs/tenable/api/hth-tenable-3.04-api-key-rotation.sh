#!/usr/bin/env bash
# HTH Tenable Control 3.4: Manage API Keys
# Profile: L1 | CIS Controls: 5.4, 6.3 | NIST 800-53: IA-5, AC-2, AC-6
# https://howtoharden.com/guides/tenable/#34-manage-api-keys
#
# Inventories which Tenable Vulnerability Management accounts can authenticate
# to the API, and rotates (regenerates) a named user's API keys.
#   List users:    GET https://cloud.tenable.com/users
#                  https://developer.tenable.com/reference/users-list
#   Generate keys: PUT https://cloud.tenable.com/users/{user_id}/keys
#                  https://developer.tenable.com/reference/users-keys
#                  (requires the Administrator [64] role; response returns the
#                  new accessKey and secretKey)
#   Auth:          X-ApiKeys: accessKey=ACCESS_KEY;secretKey=SECRET_KEY
#
# WARNING: Tenable API keys have no expiry, and regeneration invalidates the
# user's existing keys THE MOMENT it happens — every integration still using
# the old pair breaks instantly. Schedule rotation; do not run it casually.
#
# Environment: TENABLE_ACCESS_KEY, TENABLE_SECRET_KEY.
#   Rotation additionally requires ROTATE_USER_ID and CONFIRM_ROTATION=yes.
set -euo pipefail

command -v curl >/dev/null 2>&1 || { echo "ERROR: curl not found" >&2; exit 1; }
command -v jq   >/dev/null 2>&1 || { echo "ERROR: jq not found" >&2; exit 1; }

AUTH="X-ApiKeys: accessKey=${TENABLE_ACCESS_KEY};secretKey=${TENABLE_SECRET_KEY}"

# HTH Guide Excerpt: begin api-inventory-api-capable-users
# Every enabled account with api_permitted=true can hold a standing API
# credential. This is the inventory to reconcile against your list of named
# applications and owners — one key pair per application.
USERS_JSON=$(curl -sf -H "${AUTH}" "https://cloud.tenable.com/users")

echo "Enabled accounts permitted to authenticate to the API:"
echo "${USERS_JSON}" | jq -r \
  '.users[] | select(.enabled == true and .api_permitted == true)
    | "  id=\(.id)\t\(.username)\tpermissions=\(.permissions)\tlast_ui_login=\(.lastlogin // "never")"'
# HTH Guide Excerpt: end api-inventory-api-capable-users

# HTH Guide Excerpt: begin api-rotate-user-keys
# Regenerate API keys for one user (rotation cadence, offboarding, or
# suspected exposure). Requires Administrator [64]. The new secret is shown
# only in this response — store it in a secrets manager immediately.
if [ "${CONFIRM_ROTATION:-no}" = "yes" ] && [ -n "${ROTATE_USER_ID:-}" ]; then
  echo "Regenerating API keys for user id ${ROTATE_USER_ID} — existing keys are invalidated immediately"
  NEW_KEYS=$(curl -sf -X PUT -H "${AUTH}" \
    "https://cloud.tenable.com/users/${ROTATE_USER_ID}/keys")
  # Do not echo the keys to the terminal or CI logs; write them to a
  # restricted file for transfer into your secrets manager.
  KEY_FILE="tenable-keys-${ROTATE_USER_ID}.json"
  umask 177
  echo "${NEW_KEYS}" | jq '{accessKey, secretKey}' > "${KEY_FILE}"
  echo "New key pair written to ${KEY_FILE} (mode 600) — move it to your secrets manager and delete the file"
else
  echo "Rotation skipped: set ROTATE_USER_ID and CONFIRM_ROTATION=yes to regenerate a user's keys"
fi
# HTH Guide Excerpt: end api-rotate-user-keys
