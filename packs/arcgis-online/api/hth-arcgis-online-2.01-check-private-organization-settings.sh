#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: arcgis-online-2.1
#   guide:   https://howtoharden.com/guides/arcgis-online/
#   profile: L2
#   mode:    read-only
#   requires: ARCGIS_ONLINE_TENANT, ARCGIS_ONLINE_EXPECTED_ORG_ID, ARCGIS_ONLINE_OAUTH_TOKEN (authorized user), curl, jq
# First-party source: https://developers.arcgis.com/rest/users-groups-and-items/portal-self/
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
tenant=${ARCGIS_ONLINE_TENANT:?Set the ArcGIS Online tenant slug}
org=${ARCGIS_ONLINE_EXPECTED_ORG_ID:?Set the exact ArcGIS Online organization ID}
[[ "$tenant" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]] || exit 2
[[ "$org" =~ ^[A-Za-z0-9]+$ ]] || exit 2

token=${ARCGIS_ONLINE_OAUTH_TOKEN:?Set an authorized bearer credential}
[[ "$token" != *$'\r'* && "$token" != *$'\n'* ]] || exit 2

body=$(printf 'Authorization: Bearer %s\n' "$token" |
  curl -q --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 40 --header @- "https://$tenant.maps.arcgis.com/sharing/rest/portals/self?f=json")

result=$(jq -ce --arg id "$org" '
  if .id==$id and (has("error")|not) and (.user|type)=="object"
    and (.access=="private" or .access=="public") and (.canSharePublic|type)=="boolean"
  then {id, organization_access:.access, non_admin_public_sharing:.canSharePublic,
        matches:(.access=="private" and .canSharePublic==false)}
  else error("ArcGIS organization view or sharing fields not verified") end
' <<<"$body")
printf '%s\n' "$result"
jq -e '.matches' <<<"$result" >/dev/null
# HTH Guide Excerpt: end read-evidence
