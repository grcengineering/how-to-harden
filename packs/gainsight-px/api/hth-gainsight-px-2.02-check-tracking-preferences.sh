#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: gainsight-px-2.2
#   guide: https://howtoharden.com/guides/gainsight-px/
#   profile: L2
#   mode: read-only
#   requires: Bash, curl, jq, an approved synthetic US PX test identity, and a User Read/Write API key
# Sources: https://support.gainsight.com/PX/Security_and_Compliance/Enablement/User_Preferences_for_Tracking_and_Engagement
#          https://support.gainsight.com/v1/docs/gainsight-px-connector
# HTH Guide Excerpt: begin check-tracking-preferences
set -euo pipefail
set +x
: "${GAINSIGHT_PX_API_KEY:?Supply a US test tenant API key}"
: "${GAINSIGHT_PX_TEST_ID:?Set a non-sensitive synthetic Identify ID}"
if [[ ! "$GAINSIGHT_PX_TEST_ID" =~ ^[a-zA-Z0-9_][a-zA-Z0-9_-]{0,127}$ ]] ||
   [[ "$GAINSIGHT_PX_API_KEY" == *$'\r'* || "$GAINSIGHT_PX_API_KEY" == *$'\n'* ]]; then
  printf 'Invalid fixture ID or credential header.\n' >&2
  exit 2
fi
key=$GAINSIGHT_PX_API_KEY
unset GAINSIGHT_PX_API_KEY
result=$(printf 'X-APTRINSIC-API-KEY: %s\n' "$key" |
  curl -q --silent --show-error --fail --proto '=https' --max-time 30 --header @- \
    "https://api.aptrinsic.com/v1/user/preferences/$GAINSIGHT_PX_TEST_ID")
jq -e '
  if type == "object" and has("trackUsage") and has("trackEmailAnalytics") and
     ([.trackUsage,.trackEmailAnalytics] | all(. == null or type == "boolean"))
  then {trackUsage,trackEmailAnalytics}
  else error("Missing or invalid documented preference fields; do not infer consent")
  end
' <<< "$result"
# HTH Guide Excerpt: end check-tracking-preferences
