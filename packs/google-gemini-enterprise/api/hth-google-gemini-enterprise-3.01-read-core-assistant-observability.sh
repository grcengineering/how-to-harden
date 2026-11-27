#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: google-gemini-enterprise-3.1
#   guide: https://howtoharden.com/guides/google-gemini-enterprise/#31-collect-usage-metadata-without-prompt-payloads-by-default
#   profile: L2
#   mode: read-only
#   requires: Bash, curl, jq, and a short-lived Google OAuth token with the required read permission
# HTH google-gemini-enterprise 3.1: Collect usage metadata without prompt payloads by default
# Profile: L2 (Walk)
# Guide: https://howtoharden.com/guides/google-gemini-enterprise/
# Reference: https://docs.cloud.google.com/gemini/enterprise/docs/reference/rest/v1alpha/projects.locations.collections.engines/get
# HTH Guide Excerpt: begin read-core-assistant-observability
set +x
set -euo pipefail
: "${GEMINI_PROJECT_ID:?Set the explicitly approved Google Cloud project ID}"
if ! [[ "$GEMINI_PROJECT_ID" =~ ^[a-z][a-z0-9-]{4,28}[a-z0-9]$ ]]; then
  printf '%s\n' 'Use an ordinary Google Cloud project ID (6–30 characters)' >&2
  exit 2
fi
: "${GEMINI_LOCATION:?Use global, us or eu}"
: "${GEMINI_APP_ID:?Set the approved resource ID}"
: "${GEMINI_OAUTH_TOKEN:?Set a short-lived Google OAuth access token}"
case "$GEMINI_LOCATION" in
  global) host=discoveryengine.googleapis.com ;;
  us|eu) host="$GEMINI_LOCATION-discoveryengine.googleapis.com" ;;
  *) printf '%s\n' 'Unsupported Gemini Enterprise location' >&2; exit 2 ;;
esac
if ! [[ "$GEMINI_APP_ID" =~ ^[a-z0-9][a-z0-9_-]{0,62}$ &&
        "$GEMINI_OAUTH_TOKEN" =~ ^[A-Za-z0-9_./+~=-]+$ ]]; then
  printf '%s\n' 'Invalid Gemini resource ID or OAuth token format' >&2
  exit 2
fi
resource="projects/$GEMINI_PROJECT_ID/locations/$GEMINI_LOCATION/collections/default_collection/engines/$GEMINI_APP_ID"
printf 'header = "Authorization: Bearer %s"\n' "$GEMINI_OAUTH_TOKEN" |
  curl --disable --config - --proto '=https' --silent --show-error --fail \
    --connect-timeout 10 --max-time 30 --max-filesize 1048576 --request GET \
    --write-out ' %{http_code}' "https://$host/v1alpha/${resource}?fields=appType%2CobservabilityConfig" |
  jq -ces 'def boolean_or_absent: . == null or type == "boolean";
     if length == 2 and .[1] == 200 and
       (.[0] | type == "object" and .appType == "APP_TYPE_INTRANET" and
       (.observabilityConfig == null or (.observabilityConfig | type == "object" and
        (.observabilityEnabled | boolean_or_absent) and
        (.sensitiveLoggingEnabled | boolean_or_absent))))
     then .[0] | {app_type: .appType,
                  observability_enabled: .observabilityConfig.observabilityEnabled,
                  sensitive_logging_enabled: .observabilityConfig.sensitiveLoggingEnabled}
     else error("Unexpected Gemini Enterprise observability response") end'
# HTH Guide Excerpt: end read-core-assistant-observability
