#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: celonis-2.2
#   guide: https://howtoharden.com/guides/celonis/#22-read-a-bounded-team-audit-sample
#   profile: L2
#   mode: read-only
#   requires: Bash, curl and vendor read credentials; jq for structured samples
# HTH celonis 2.2: Read a bounded team audit sample
# Profile: L2 (Walk)
# Guide: https://howtoharden.com/guides/celonis/
# Reference: https://developer.celonis.com/celonis-apis/audit-log-api/openapi/openapi-external-v2/audit-log-api
# HTH Guide Excerpt: begin sample-team-audit-access
set +x
set -euo pipefail
: "${CELONIS_TEAM_HOST:?Set CELONIS_TEAM_HOST for the approved target}"
: "${CELONIS_AUDIT_OAUTH_TOKEN:?Set CELONIS_AUDIT_OAUTH_TOKEN for the approved target}"
if ! [[ "$CELONIS_TEAM_HOST" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)?\.celonis\.cloud$ && "$CELONIS_AUDIT_OAUTH_TOKEN" =~ ^[A-Za-z0-9_./+~=-]+$ ]]; then
  printf '%s\n' 'Use a Celonis team or team.cluster host and valid OAuth token' >&2
  exit 2
fi

printf 'header = "Authorization: Bearer %s"\n' "$CELONIS_AUDIT_OAUTH_TOKEN" |
  curl --disable --config - --proto '=https' --silent --show-error --fail \
    --connect-timeout 10 --max-time 30 --max-filesize 1048576 \
    --request GET --write-out ' %{http_code}' "https://$CELONIS_TEAM_HOST/log/api/external/v2/audit?limit=1" |
  jq -ces 'if length == 1 and .[0] == 204 then {sampled: 0, more: false}
    elif length == 2 and .[1] == 200 and
      (.[0] | type == "object" and (.content | type == "array" and length <= 1) and
      (.nextPageToken == null or (.nextPageToken | type == "string")))
    then .[0] | {sampled: (.content | length), more: ((.nextPageToken // "") != "")}
    else error("Unexpected Celonis audit response") end'
# HTH Guide Excerpt: end sample-team-audit-access
