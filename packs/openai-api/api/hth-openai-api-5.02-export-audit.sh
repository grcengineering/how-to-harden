#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: openai-api-5.2
#   guide: https://howtoharden.com/guides/openai-api/#52-export-audit-records-and-read-back-security-policy
#   profile: L2
#   mode: read-only
#   requires: OPENAI_ADMIN_KEY(Audit Logs read), OPENAI_AUDIT_START(unix seconds), curl, jq
# Source: https://developers.openai.com/api/reference/resources/admin/subresources/organization/subresources/audit_logs/methods/list
# NIST 800-53 AU-2, AU-6. JSONL stdout can contain identities; protect the sink.
source "$(dirname "$0")/common.sh"
openai_require_admin
: "${OPENAI_AUDIT_START:?Set the inclusive export-window start in Unix seconds}"
[[ "${OPENAI_AUDIT_START}" =~ ^[0-9]+$ ]] || exit 2
# HTH Guide Excerpt: begin export-audit
openai_list '/organization/audit_logs' \
  --data-urlencode "effective_at[gte]=${OPENAI_AUDIT_START}"
# Persist only after the command exits 0. Use an overlapping next window and
# deduplicate on event id; this helper never advances an external checkpoint.
# HTH Guide Excerpt: end export-audit
