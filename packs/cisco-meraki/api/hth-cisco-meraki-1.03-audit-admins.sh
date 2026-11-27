#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cisco-meraki-1.3
#   guide: https://howtoharden.com/guides/cisco-meraki/
#   profile: L1
#   mode: read-only
#   requires: Bash, curl, jq and approved scoped API access
# HTH cisco-meraki 1.3: audit-admins
# Profile: see the corresponding control in the guide.
# Framework: NIST SP 800-53 Rev. 5 AC-2, AC-6
# Guide: https://howtoharden.com/guides/cisco-meraki/
# HTH Guide Excerpt: begin audit-admins
set -euo pipefail
umask 077

token="${MERAKI_DASHBOARD_API_KEY:?Set MERAKI_DASHBOARD_API_KEY using your secret manager}"
[[ "$token" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || { printf '%s\n' 'Invalid bearer token format.' >&2; exit 2; }
org="${MERAKI_ORG_ID:?Set MERAKI_ORG_ID}"
[[ "$org" =~ ^[0-9]+$ ]] || { printf '%s\n' 'MERAKI_ORG_ID must be numeric.' >&2; exit 2; }
printf 'header = "Authorization: Bearer %s"\n' "$token" |
  curl -q --config - --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 45 \
    "https://api.meraki.com/api/v1/organizations/$org/admins" |
  jq -e 'if type != "array" or any(.[]; (.id | type) != "string" or (.orgAccess | type) != "string") then error("Unexpected administrator response") else map({id, orgAccess, accountStatus, twoFactorAuthEnabled, hasApiKey}) end'

# HTH Guide Excerpt: end audit-admins
