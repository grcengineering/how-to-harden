#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: genesys-cloud-cx-1.2
#   guide: https://howtoharden.com/guides/genesys-cloud-cx/#12-review-role-definitions-and-division-grants
#   profile: L1
#   mode: read-only
#   requires: curl, jq, Genesys OAuth token with authorization:role:view
# Source (reviewed 2026-11-27): https://github.com/MyPureCloud/platform-client-sdk-python/blob/master/build/docs/AuthorizationApi.md
# HTH Guide Excerpt: begin inventory-role-definitions
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${GENESYS_ACCESS_TOKEN:-}" =~ ^[[:alnum:]_.~+/=-]+$ ]] || fail 'Missing or invalid GENESYS_ACCESS_TOKEN'

case "${GENESYS_REGION:-}" in
  us_east_1) host=api.mypurecloud.com ;;
  us_west_2) host=api.usw2.pure.cloud ;;
  ca_central_1) host=api.cac1.pure.cloud ;;
  eu_west_1) host=api.mypurecloud.ie ;;
  eu_west_2) host=api.euw2.pure.cloud ;;
  eu_central_1) host=api.mypurecloud.de ;;
  eu_central_2) host=api.euc2.pure.cloud ;;
  ap_southeast_2) host=api.mypurecloud.com.au ;;
  ap_northeast_1) host=api.mypurecloud.jp ;;
  ap_northeast_2) host=api.apne2.pure.cloud ;;
  ap_northeast_3) host=api.apne3.pure.cloud ;;
  ap_south_1) host=api.aps1.pure.cloud ;;
  ap_southeast_1) host=api.apse1.pure.cloud ;;
  sa_east_1) host=api.sae1.pure.cloud ;;
  me_central_1) host=api.mec1.pure.cloud ;;
  mx_central_1) host=api.mxc1.pure.cloud ;;
  *) fail 'Select a supported commercial GENESYS_REGION' ;;
esac
page=${GENESYS_PAGE:-1}
[[ "$page" =~ ^[1-9][0-9]{0,5}$ ]] || fail 'Invalid page number'
auth=$GENESYS_ACCESS_TOKEN
response=$(printf 'header = "Authorization: Bearer %s"\n' "$auth" |
  curl --disable --config - --silent --show-error --fail --proto '=https' \
    --connect-timeout 10 --max-time 45 "https://$host/api/v2/authorization/roles?pageSize=25&pageNumber=$page&userCount=false") || fail 'Read request did not succeed'

jq -e --argjson page "$page" '
  (.entities|type=="array") and all(.entities[];(.id|type=="string")) and
  .pageNumber==$page and (.total|type=="number") and
  (.nextUri==null or (.nextUri|type=="string"))
' <<<"$response" >/dev/null 2>&1 || fail 'Unexpected role collection'
jq '{page:.pageNumber,total_visible_roles:.total,next_page_present:((.nextUri // "")!=""),role_ids:[.entities[].id],effective_assignments_checked:false}' <<<"$response"
# HTH Guide Excerpt: end inventory-role-definitions
