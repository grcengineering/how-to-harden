#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: make-3.1
#   guide: https://howtoharden.com/guides/make/#31-review-enterprise-organization-audit-events
#   profile: L2
#   mode: read-only
#   requires: Bash, curl and vendor read credentials; jq for structured samples
# HTH make 3.1: Review enterprise organization audit events
# Profile: L2 (Walk)
# Guide: https://howtoharden.com/guides/make/
# Reference: https://developers.make.com/api-documentation/api-reference/audit-logs.md
# HTH Guide Excerpt: begin sample-organization-audit
set +x
set -euo pipefail
: "${MAKE_PRODUCTION_HOST:?Set MAKE_PRODUCTION_HOST for the approved target}"
: "${MAKE_ORGANIZATION_ID:?Set MAKE_ORGANIZATION_ID for the approved target}"
: "${MAKE_API_TOKEN:?Set MAKE_API_TOKEN for the approved target}"
case "$MAKE_PRODUCTION_HOST" in
  eu1.make.com|eu2.make.com|us1.make.com|us2.make.com) ;;
  *) printf '%s\n' 'Use an approved Make.com production zone' >&2; exit 2 ;;
esac
if ! [[ "$MAKE_ORGANIZATION_ID" =~ ^[1-9][0-9]{0,15}$ && "$MAKE_API_TOKEN" =~ ^[A-Za-z0-9_./+~=-]+$ ]]; then
  printf '%s\n' 'Invalid Make organization ID or API token format' >&2
  exit 2
fi

printf 'header = "Authorization: Token %s"\n' "$MAKE_API_TOKEN" |
  curl --disable --config - --proto '=https' --silent --show-error --fail \
    --connect-timeout 10 --max-time 30 --max-filesize 1048576 \
    --request GET --write-out ' %{http_code}' "https://$MAKE_PRODUCTION_HOST/api/v2/audit-logs/v2/organization/$MAKE_ORGANIZATION_ID?pg%5Blimit%5D=20&pg%5BsortDir%5D=desc" |
  jq -ces 'if length == 2 and .[1] == 200 and
      (.[0] | type == "object" and (.pg | type == "object") and
       (.auditLogs | type == "array" and length <= 20 and
        all(.[]; type == "object" and (.eventName | type == "string"))))
    then .[0] | {sampled: (.auditLogs | length),
                 by_event: (.auditLogs | group_by(.eventName) |
                 map({event: .[0].eventName, count: length}))}
    else error("Unexpected Make audit log response") end'
# HTH Guide Excerpt: end sample-organization-audit
