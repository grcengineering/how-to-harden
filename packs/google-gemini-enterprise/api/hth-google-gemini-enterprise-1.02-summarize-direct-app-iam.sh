#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: google-gemini-enterprise-1.2
#   guide: https://howtoharden.com/guides/google-gemini-enterprise/#12-restrict-access-at-each-gemini-enterprise-app
#   profile: L1
#   mode: read-only
#   requires: Bash, curl, jq, and a short-lived Google OAuth token with the required read permission
# HTH google-gemini-enterprise 1.2: Restrict access at each Gemini Enterprise app
# Profile: L1 (Crawl)
# Guide: https://howtoharden.com/guides/google-gemini-enterprise/
# Reference: https://docs.cloud.google.com/gemini/enterprise/docs/reference/rest/v1/projects.locations.collections.engines/getIamPolicy
# HTH Guide Excerpt: begin summarize-direct-app-iam
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
    --write-out ' %{http_code}' "https://$host/v1/${resource}:getIamPolicy?options.requestedPolicyVersion=3" |
  jq -ces '
def summarize:
  def bindings: if has("bindings") then .bindings else [] end;
  if type == "object" and
    (has("bindings") or has("etag") or length == 0) and
    ((has("version") | not) or (.version | type == "number" and (. == 0 or . == 1 or . == 3))) and
    (bindings | type == "array" and
      all(.[]; type == "object" and (.role | type == "string") and
       (.members | type == "array" and all(.[]; type == "string")) and
       (.condition == null or (.condition | type == "object"))))
  then {policy_version: (.version // null),
        direct_bindings: (bindings |
          map({role, principal_count: (.members | length),
               public_principal_count: ([.members[] | select(. == "allUsers" or . == "allAuthenticatedUsers")] | length),
               conditional: (.condition != null)}))}
  else error("Unexpected IAM policy response") end;
if length == 2 and .[1] == 200 then .[0] | summarize
             else error("Expected one direct resource IAM policy") end'
# HTH Guide Excerpt: end summarize-direct-app-iam
