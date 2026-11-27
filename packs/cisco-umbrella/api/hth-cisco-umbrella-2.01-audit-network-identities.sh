#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cisco-umbrella-2.1
#   guide: https://howtoharden.com/guides/cisco-umbrella/
#   profile: L2
#   mode: read-only
#   requires: Bash, curl, jq and approved scoped API access
# HTH cisco-umbrella 2.1: audit-network-identities
# Profile: see the corresponding control in the guide.
# Framework: NIST SP 800-53 Rev. 5 CM-8, SC-7
# Guide: https://howtoharden.com/guides/cisco-umbrella/
# HTH Guide Excerpt: begin audit-network-identities
set -euo pipefail
umask 077

token="${UMBRELLA_ACCESS_TOKEN:?Set UMBRELLA_ACCESS_TOKEN using your secret manager}"
[[ "$token" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || { printf '%s\n' 'Invalid bearer token format.' >&2; exit 2; }
page="${UMBRELLA_PAGE:-1}"
[[ "$page" =~ ^[1-9][0-9]{0,8}$ ]] || { printf '%s\n' 'Invalid page.' >&2; exit 2; }
printf 'header = "Authorization: Bearer %s"\n' "$token" |
  curl -q --config - --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 45 \
    --get --data-urlencode "page=$page" --data-urlencode 'limit=100' \
    'https://api.umbrella.com/deployments/v2/networks' |
  jq -e --argjson page "$page" 'if type != "array" or any(.[]; (.originId | type) != "number") then error("Unexpected network response") else {page: $page, count: length, originIds: map(.originId)} end'

# HTH Guide Excerpt: end audit-network-identities
