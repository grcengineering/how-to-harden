#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-4.1
#   guide: https://howtoharden.com/guides/devin/#41-collect-enterprise-audit-logs
#   profile: L1
#   mode: read-only
#   requires: DEVIN_API_KEY(enterprise service user with ViewAccountAuditLogs), DEVIN_AUDIT_AFTER(Unix seconds), DEVIN_AUDIT_BEFORE(Unix seconds), DEVIN_AUDIT_OUTPUT(new private JSONL path), HTH_PROFILE_LEVEL(1 or higher)
# HTH Devin 4.1: Collect Enterprise Audit Logs
# Framework: NIST 800-53 AU-6, AU-9
# Sources: https://docs.devin.ai/api-reference/v3/audit-logs/enterprise-audit-logs
#          https://docs.devin.ai/api-reference/authentication
#          https://docs.devin.ai/v3-openapi.json (v3 available, fetched 2026-10-29)
# Full records contain user emails and arbitrary data; keep output out of git and logs.
# Exit 0 = collection completed, NOT logging completeness proven; 2 = unknown/not run.
# The 31-day window cap is local pack policy, not the vendor API limit (100 days).
# Optional DEVIN_AUDIT_ACTION filters a documented action, e.g. ai_guardrail_violation.
# Reconcile adjacent time windows with a small overlap and deduplicate by audit_log_id.
set +x
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin collect-audit-logs
hth_init 1
[[ -n "${DEVIN_AUDIT_OUTPUT:-}" ]] || hth_unknown 'set DEVIN_AUDIT_OUTPUT to a new private evidence file'
[[ "${DEVIN_AUDIT_AFTER:-}" =~ ^[0-9]{1,11}$ && "${DEVIN_AUDIT_BEFORE:-}" =~ ^[0-9]{1,11}$ ]] || \
  hth_unknown 'set DEVIN_AUDIT_AFTER and DEVIN_AUDIT_BEFORE to Unix seconds'
after=$((10#$DEVIN_AUDIT_AFTER)); before=$((10#$DEVIN_AUDIT_BEFORE))
(( before > after && before - after <= 2678400 )) || hth_unknown 'request a positive time window of at most 31 days'
query="order=asc&time_after=${after}&time_before=${before}"
if [[ -n "${DEVIN_AUDIT_ACTION:-}" ]]; then
  [[ "$DEVIN_AUDIT_ACTION" =~ ^[a-z][a-z0-9_]*$ ]] || hth_unknown 'invalid audit action name'
  query+="&action=${DEVIN_AUDIT_ACTION}"
fi
hth_paginate '/v3/enterprise/audit-logs' "$HTH_TEMP/events.jsonl" "$query"
jq -se --argjson after "$after" --argjson before "$before" --arg action "${DEVIN_AUDIT_ACTION:-}" '
  all(.[]; (.audit_log_id | type == "string" and length > 0) and
    (.action | type == "string") and ($action == "" or .action == $action) and
    (.created_at | type == "number" and . == floor) and
    .created_at >= $after and .created_at <= $before and (.data | type == "object"))' \
  "$HTH_TEMP/events.jsonl" >/dev/null || hth_unknown 'malformed audit event or response outside requested filter'
jq -sc 'unique_by(.audit_log_id) | sort_by(.created_at, .audit_log_id)[]' \
  "$HTH_TEMP/events.jsonl" > "$HTH_TEMP/export.jsonl"
hth_save_private "$HTH_TEMP/export.jsonl" "$DEVIN_AUDIT_OUTPUT"
printf 'COLLECTED: %s unique audit events in the requested window; verify expected activity and ingest the private JSONL into your SIEM.\n' \
  "$(wc -l < "$HTH_TEMP/export.jsonl" | tr -d ' ')"
# HTH Guide Excerpt: end collect-audit-logs
