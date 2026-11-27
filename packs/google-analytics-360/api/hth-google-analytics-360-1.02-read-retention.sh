#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: google-analytics-360-1.2
#   guide: https://howtoharden.com/guides/google-analytics-360/
#   profile: L1
#   mode: read-only
#   requires: Bash, curl, jq, a property-authorized analytics.readonly OAuth token
# Source: https://developers.google.com/analytics/devguides/config/admin/v1/rest/v1beta/properties/getDataRetentionSettings
# HTH Guide Excerpt: begin read-retention
set -euo pipefail
set +x
: "${GA4_ACCESS_TOKEN:?Supply an approved Analytics read-only OAuth token}"
: "${GA4_PROPERTY_ID:?Supply the numeric GA4 property ID}"
if [[ ! "$GA4_PROPERTY_ID" =~ ^[0-9]{1,24}$ ||
      "$GA4_ACCESS_TOKEN" == *$'\r'* || "$GA4_ACCESS_TOKEN" == *$'\n'* ]]; then
  printf 'Invalid property ID or credential header.\n' >&2
  exit 2
fi
key=$GA4_ACCESS_TOKEN
unset GA4_ACCESS_TOKEN
resource="properties/$GA4_PROPERTY_ID/dataRetentionSettings"
result=$(printf 'Authorization: Bearer %s\n' "$key" |
  curl -q --silent --show-error --fail --proto '=https' --max-time 30 --header @- \
    "https://analyticsadmin.googleapis.com/v1beta/$resource")
jq -e --arg resource "$resource" '
  if .name == $resource and
     (.eventDataRetention | type == "string" and . != "RETENTION_DURATION_UNSPECIFIED" and length > 0)
     and (.userDataRetention | type == "string" and . != "RETENTION_DURATION_UNSPECIFIED" and length > 0)
     and (.resetUserDataOnNewActivity | . == null or type == "boolean")
  then {eventDataRetention,userDataRetention,resetUserDataOnNewActivity}
  else error("Unexpected Analytics retention state; no evidence reported") end
' <<< "$result"
# HTH Guide Excerpt: end read-retention
