#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: perplexity-3.2
#   guide: https://howtoharden.com/guides/perplexity/#32-enable-audit-logging-and-sample-stored-admin-events
#   profile: L2
#   mode: read-only
#   requires: bash, curl, jq, organization Audit API key
# HTH perplexity 3.2: Enable audit logging and sample stored admin events
# Profile: L2 (Walk)
# Guide: https://howtoharden.com/guides/perplexity/
# Reference: https://docs.perplexity.ai/docs/admin/audit-api
# HTH Guide Excerpt: begin sample-organization-audit-events
set -euo pipefail
set +x
: "${PERPLEXITY_AUDIT_API_KEY:?Set the approved read-only API key}"
[[ "${PERPLEXITY_AUDIT_API_KEY}" =~ ^[A-Za-z0-9._~-]+$ ]] ||
  { printf '%s\n' 'Invalid bearer token characters.' >&2; exit 2; }
printf 'header = "Authorization: Bearer %s"\n' "${PERPLEXITY_AUDIT_API_KEY}" |
  curl --disable --config - --proto '=https' --fail --silent --show-error \
    --connect-timeout 10 --max-time 30 \
    "https://api.perplexity.ai/v1/admin/audit-events?event_type=organization_settings_update&limit=25" |
  jq -e 'if (.data | type) == "array" and (.has_more | type) == "boolean" then {has_more, events: [.data[] | {id, created_at, type}]} else error("Unexpected Audit API response") end'
# HTH Guide Excerpt: end sample-organization-audit-events
