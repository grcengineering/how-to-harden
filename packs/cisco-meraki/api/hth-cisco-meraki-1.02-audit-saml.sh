#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cisco-meraki-1.2
#   guide: https://howtoharden.com/guides/cisco-meraki/
#   profile: L1
#   mode: read-only
#   requires: Bash, curl, jq and approved scoped API access
# HTH cisco-meraki 1.2: audit-saml
# Profile: see the corresponding control in the guide.
# Framework: NIST SP 800-53 Rev. 5 AC-2, AC-6, IA-8
# Guide: https://howtoharden.com/guides/cisco-meraki/
# HTH Guide Excerpt: begin audit-saml
set -euo pipefail
umask 077

token="${MERAKI_DASHBOARD_API_KEY:?Set MERAKI_DASHBOARD_API_KEY using your secret manager}"
[[ "$token" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || { printf '%s\n' 'Invalid bearer token format.' >&2; exit 2; }
org="${MERAKI_ORG_ID:?Set MERAKI_ORG_ID}"
[[ "$org" =~ ^[0-9]+$ ]] || { printf '%s\n' 'MERAKI_ORG_ID must be numeric.' >&2; exit 2; }
printf 'header = "Authorization: Bearer %s"\n' "$token" |
  curl -q --config - --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 45 \
    "https://api.meraki.com/api/v1/organizations/$org/saml" |
  jq -e 'if (.enabled | type) == "boolean" then {enabled} else error("Missing expected SAML field") end'

# HTH Guide Excerpt: end audit-saml
