#!/usr/bin/env bash
# HTH LangChain Control 6.2: Export Audit Logs to SIEM (OCSF Format)
# Profile: L2 | NIST: AU-2, AU-6, AU-12
# https://howtoharden.com/guides/langchain/#62-export-audit-logs-siem
#
# Audit logs require LangSmith v0.12.33 or later (self-hosted) or Enterprise cloud.
# Logs are emitted in OCSF 1.7.0 format — directly ingestable by Splunk and Datadog.

set -euo pipefail

: "${LANGSMITH_API_KEY:?Set LANGSMITH_API_KEY (admin scope)}"
: "${LANGSMITH_API_URL:=https://api.smith.langchain.com}"

# HTH Guide Excerpt: begin api-fetch-audit-logs
# Retrieve last 24h of audit events (paginated)
START_TIME=$(date -u -v-1d '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d '1 day ago' '+%Y-%m-%dT%H:%M:%SZ')
END_TIME=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

curl -sf "${LANGSMITH_API_URL}/api/v1/audit-logs?start_time=${START_TIME}&end_time=${END_TIME}&limit=1000" \
  -H "X-API-Key: ${LANGSMITH_API_KEY}" \
  -H "Accept: application/json" > audit-logs.ocsf.json

echo "Exported $(jq 'length' audit-logs.ocsf.json) audit events in OCSF 1.7.0 format"
# HTH Guide Excerpt: end api-fetch-audit-logs

# HTH Guide Excerpt: begin api-forward-audit-logs-splunk
# Forward each event to Splunk HEC
: "${SPLUNK_HEC_URL:?Set SPLUNK_HEC_URL}"
: "${SPLUNK_HEC_TOKEN:?Set SPLUNK_HEC_TOKEN}"

jq -c '.[]' audit-logs.ocsf.json | while read -r EVENT; do
  curl -sf -X POST "${SPLUNK_HEC_URL}/services/collector/event" \
    -H "Authorization: Splunk ${SPLUNK_HEC_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"event\": ${EVENT}, \"sourcetype\": \"langsmith:audit:ocsf\"}"
done
# HTH Guide Excerpt: end api-forward-audit-logs-splunk

# HTH Guide Excerpt: begin api-detect-suspicious-events
# Surface high-risk events: API key creation, role changes, SSO config edits
jq '[.[] | select(
  .activity_id == "create_api_key" or
  .activity_id == "update_role_assignment" or
  .activity_id == "update_sso_config" or
  .activity_id == "delete_workspace"
)]' audit-logs.ocsf.json
# HTH Guide Excerpt: end api-detect-suspicious-events
