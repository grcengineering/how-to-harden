#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: google-ads-1.2
#   guide: https://howtoharden.com/guides/google-ads/#12-reconcile-confirmed-users-and-manager-relationships
#   profile: L1
#   mode: read-only
#   requires: curl, jq, authorized Google Ads OAuth bearer with API access via approved Google Cloud project
# Source (reviewed 2026-11-27): https://developers.google.com/google-ads/api/reference/rpc/v26/GoogleAdsService/Search?transport=rest
# HTH Guide Excerpt: begin read-confirmed-user-access
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${HTH_GOOGLE_ADS_TOKEN:-}" =~ ^[[:alnum:]_.~+/=-]+$ ]] || fail 'Missing or invalid HTH_GOOGLE_ADS_TOKEN'
[[ "${HTH_GOOGLE_ADS_CUSTOMER_ID:-}" =~ ^[0-9]{10}$ ]] || fail 'Missing or invalid HTH_GOOGLE_ADS_CUSTOMER_ID'

manager=${HTH_GOOGLE_ADS_LOGIN_CUSTOMER_ID:-}
[[ -z "$manager" || "$manager" =~ ^[0-9]{10}$ ]] || fail 'Invalid login customer ID'
# Search uses HTTP POST, but it is read-only and cannot mutate users or campaigns.
response=$(
  {
    printf 'header = "Authorization: Bearer %s"\n' "$HTH_GOOGLE_ADS_TOKEN"
    if [[ -n "$manager" ]]; then
      printf 'header = "login-customer-id: %s"\n' "$manager"
    fi
  } | curl --disable --config - --silent --show-error --fail --proto '=https' \
    --connect-timeout 10 --max-time 45 --header 'Content-Type: application/json' \
    --data '{"query":"SELECT customer_user_access.user_id, customer_user_access.access_role FROM customer_user_access"}' \
    "https://googleads.googleapis.com/v26/customers/$HTH_GOOGLE_ADS_CUSTOMER_ID/googleAds:search"
) || fail 'Confirmed user read failed'
jq -e '
  type=="object" and (.fieldMask|type=="string" and contains("customerUserAccess")) and
  ((.results // [])|type=="array") and
  all((.results // [])[];(.customerUserAccess.userId|type=="string") and
    (.customerUserAccess.accessRole|type=="string")) and
  (.nextPageToken==null or (.nextPageToken|type=="string"))
' <<<"$response" >/dev/null 2>&1 || fail 'Unexpected or malformed Search response'
jq '{confirmed_user_access:[(.results // [])[]|.customerUserAccess|{userId,accessRole}],
   next_page_present:((.nextPageToken // "")!=""),pending_and_inherited_access_checked:false}' <<<"$response"
# HTH Guide Excerpt: end read-confirmed-user-access
