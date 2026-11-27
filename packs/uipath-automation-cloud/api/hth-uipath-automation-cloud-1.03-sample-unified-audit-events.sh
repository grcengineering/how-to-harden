#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: uipath-automation-cloud-1.3
#   guide: https://howtoharden.com/guides/uipath-automation-cloud/#13-verify-unified-audit-collection
#   profile: L2
#   mode: read-only
#   requires: Bash, curl, jq, UIPATH_ORGANIZATION_NAME, UIPATH_AUDIT_TOKEN
# Vendor contract: https://docs.uipath.com/automation-cloud/automation-cloud/latest/api-guide/get-audit-logs
# HTH Guide Excerpt: begin sample-unified-audit-events
set +x
set -euo pipefail

: "${UIPATH_ORGANIZATION_NAME:?Set the approved commercial Cloud organization URL name}"
: "${UIPATH_AUDIT_TOKEN:?Inject the explicitly scoped PM.Audit.Read token}"
[[ "$UIPATH_ORGANIZATION_NAME" =~ ^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$ ]] || exit 2
[[ "$UIPATH_AUDIT_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || exit 2
response=$(
  printf 'Authorization: Bearer %s\n' "$UIPATH_AUDIT_TOKEN" |
    curl -q --fail --silent --show-error --proto '=https' --max-time 30 \
      --header @- --header 'Content-Type: application/json' \
      "https://cloud.uipath.com/$UIPATH_ORGANIZATION_NAME/orgaudit_/api/query/events?maxCount=25"
)
jq -e '
  if (.auditEvents | type) != "array" or (.auditEvents | length) > 25
    or any(.auditEvents[]; (.createdOn | type) != "string" or
        (.eventSource | type) != "string" or (.eventType | type) != "string" or
        (.status != 0 and .status != 1))
  then error("unexpected unified organization audit response")
  else {scope: "organization-audit-sample", returnedCount: (.auditEvents | length),
        events: [.auditEvents[] | {createdOn, eventSource, eventType, status}]}
  end
' <<< "$response"
# HTH Guide Excerpt: end sample-unified-audit-events
