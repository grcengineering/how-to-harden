#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: langchain-6.2
#   guide:   https://howtoharden.com/guides/langchain/#62-export-audit-logs-to-siem-in-ocsf-format
#   profile: L2
#   mode:    mutating
#   requires: LANGSMITH_API_KEY(Organization Admin or Operator service key, organization:manage; Enterprise plan), LANGSMITH_ORGANIZATION_ID, LANGSMITH_API_URL(optional), SPLUNK_HEC_URL + SPLUNK_HEC_TOKEN(forward-splunk only)
# =============================================================================
# HTH LangChain Control 6.2: Export Audit Logs to SIEM in OCSF Format
# Profile Level: L2 (Walk)
# Frameworks: NIST 800-53 AU-6, SI-4
# Dependencies: curl, jq
#
# Usage:
#   bash hth-langchain-6.2-export-audit-logs.sh                   # fetch last 24h + flag high-risk events (reads LangSmith only)
#   bash hth-langchain-6.2-export-audit-logs.sh forward-splunk    # also POST every event to Splunk HEC
#
# WHY `mode: mutating`. The default run only reads LangSmith and writes local files.
# forward-splunk POSTs to your SIEM, and the sync keeps one api/ file per control.
#
# Source: https://docs.langchain.com/langsmith/audit-logs and https://api.smith.langchain.com/openapi.json
#   GET /api/v1/audit-logs (start_time + end_time required; limit, cursor, operations optional)
#     -> ListAuditLogsOCSFResponse {cursor, items: OCSFApiActivity[]}
#   Each item is OCSF 1.7.0 API Activity: class_uid 6003, category_uid 6. The LangSmith
#   operation name is `.api.operation`; `.activity_id` is the OCSF integer enum (1 Create,
#   2 Read, 3 Update, 4 Delete, 0/99), never an operation name.
#
# TRAPS
#  1. The response is an object. `jq length` on it prints 2 and `.[]` walks {cursor, items}.
#  2. Results are paged: follow `.cursor` until it is null or you silently export page one.
#  3. Send X-Organization-Id on every request (docs: manage-organization-by-api).

set -euo pipefail

: "${LANGSMITH_API_KEY:?Set LANGSMITH_API_KEY (Org Admin/Operator service key; organization:manage)}"
: "${LANGSMITH_ORGANIZATION_ID:?Set LANGSMITH_ORGANIZATION_ID}"
: "${LANGSMITH_API_URL:=https://api.smith.langchain.com}"

# HTH Guide Excerpt: begin api-fetch-audit-logs
# Retrieve the last 24h of audit events, following the cursor until it is null
START_TIME=$(date -u -v-1d '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d '1 day ago' '+%Y-%m-%dT%H:%M:%SZ')
END_TIME=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

: > audit-logs.ocsf.jsonl
CURSOR=""
while : ; do
  PAGE=$(curl -sfG "${LANGSMITH_API_URL}/api/v1/audit-logs" \
    -H "X-API-Key: ${LANGSMITH_API_KEY}" \
    -H "X-Organization-Id: ${LANGSMITH_ORGANIZATION_ID}" \
    -H "Accept: application/json" \
    --data-urlencode "start_time=${START_TIME}" \
    --data-urlencode "end_time=${END_TIME}" \
    --data-urlencode "limit=100" \
    ${CURSOR:+--data-urlencode "cursor=${CURSOR}"})
  printf '%s' "${PAGE}" | jq -c '(.items // error("audit-logs: expected .items")) | .[]' >> audit-logs.ocsf.jsonl
  CURSOR=$(printf '%s' "${PAGE}" | jq -r '.cursor // empty')
  [ -n "${CURSOR}" ] || break
done

echo "Exported $(wc -l < audit-logs.ocsf.jsonl | tr -d ' ') audit events (OCSF 1.7.0 API Activity, class 6003)"
# HTH Guide Excerpt: end api-fetch-audit-logs

# HTH Guide Excerpt: begin api-detect-suspicious-events
# Surface high-risk operations by .api.operation (names from the tracked-operations reference)
jq -c 'select(.api.operation as $op | [
  "create_api_key", "create_service_key", "create_personal_access_token",
  "update_role", "update_workspace_member", "update_org_member",
  "create_sso_settings", "update_sso_settings", "delete_sso_settings",
  "update_login_methods", "delete_workspace"
] | index($op))' audit-logs.ocsf.jsonl > audit-logs.high-risk.jsonl
echo "High-risk events: $(wc -l < audit-logs.high-risk.jsonl | tr -d ' ')"
cat audit-logs.high-risk.jsonl
# HTH Guide Excerpt: end api-detect-suspicious-events

if [ "${1:-}" = "forward-splunk" ]; then
# HTH Guide Excerpt: begin api-forward-audit-logs-splunk
# Mutating (your SIEM): forward each event, one per line, to Splunk HEC
: "${SPLUNK_HEC_URL:?Set SPLUNK_HEC_URL}"
: "${SPLUNK_HEC_TOKEN:?Set SPLUNK_HEC_TOKEN}"

while IFS= read -r EVENT; do
  curl -sf -X POST "${SPLUNK_HEC_URL}/services/collector/event" \
    -H "Authorization: Splunk ${SPLUNK_HEC_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$(jq -nc --argjson e "${EVENT}" '{event: $e, sourcetype: "langsmith:audit:ocsf"}')" > /dev/null
done < audit-logs.ocsf.jsonl
echo "Forwarded $(wc -l < audit-logs.ocsf.jsonl | tr -d ' ') events to Splunk HEC"
# HTH Guide Excerpt: end api-forward-audit-logs-splunk
fi
