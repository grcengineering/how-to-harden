#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: acronis-cyber-protect-cloud-2.1
#   guide: https://howtoharden.com/guides/acronis-cyber-protect-cloud/
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq; ACRONIS_DC_HOST, ACRONIS_CLIENT_ID, ACRONIS_EXPECTED_TENANT_ID, ACRONIS_ACCESS_TOKEN
# HTH Guide Excerpt: begin verify-api-client-tenant
set +x
set -euo pipefail
umask 077
token="${ACRONIS_ACCESS_TOKEN:?Set ACRONIS_ACCESS_TOKEN from your approved secret store}"
[[ "$token" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || { printf '%s\n' 'Invalid credential format.' >&2; exit 2; }
host="${ACRONIS_DC_HOST:?Set ACRONIS_DC_HOST to the approved Acronis cloud data-center hostname}"
client="${ACRONIS_CLIENT_ID:?Set ACRONIS_CLIENT_ID}"
tenant="${ACRONIS_EXPECTED_TENANT_ID:?Set ACRONIS_EXPECTED_TENANT_ID}"
uuid='^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$'
[[ "$host" =~ ^[a-z0-9][a-z0-9-]*-cloud[.]acronis[.]com$ && "$client" =~ ^[A-Za-z0-9_-]+$ && "$tenant" =~ $uuid ]] || {
  printf '%s\n' 'Unsupported data-center host, client identifier or tenant UUID.' >&2
  exit 2
}
printf 'header = "Authorization: Bearer %s"\n' "$token" |
  curl -q --config - --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 45 \
    "https://$host/api/2/clients/$client" |
  jq -e --arg expected "$tenant" '
    if .type != "api_client" or (.tenant_id | type) != "string"
    then error("Unexpected client response")
    elif (.tenant_id | ascii_downcase) != ($expected | ascii_downcase)
    then error("API client belongs to a different tenant")
    else {tenantMatch: true, clientType: .type}
    end'

# HTH Guide Excerpt: end verify-api-client-tenant
