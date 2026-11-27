#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: weights-biases-3.1
#   guide: https://howtoharden.com/guides/weights-biases/#31-sample-multitenant-cloud-organization-audit-events
#   profile: L2
#   mode: read-only
#   requires: bash, curl, jq, approved W&B scoped audit or SCIM principal
# HTH weights-biases 3.1: Sample Multi-tenant Cloud organization audit events
# Profile: L2 (Walk)
# Guide: https://howtoharden.com/guides/weights-biases/
# Reference: https://github.com/wandb/docs/blob/main/platform/hosting/monitoring-usage/audit-logging.mdx
# HTH Guide Excerpt: begin sample-multitenant-audit-events
set -euo pipefail
set +x
: "${WANDB_AUDIT_USER:?Set the approved audit username}"
: "${WANDB_AUDIT_API_KEY:?Set the scoped approved audit key}"
: "${WANDB_AUDIT_DATE:?Choose the UTC day in YYYY-MM-DD form}"
[[ "$WANDB_AUDIT_USER" =~ ^[A-Za-z0-9@._-]+$ && "$WANDB_AUDIT_API_KEY" =~ ^[A-Za-z0-9._~-]+$ &&
   "$WANDB_AUDIT_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || exit 2
auth=$(printf '%s:%s' "$WANDB_AUDIT_USER" "$WANDB_AUDIT_API_KEY" | base64 | tr -d '\r\n')
printf 'header = "Authorization: Basic %s"\n' "$auth" |
  curl --disable --config - --proto '=https' --fail --silent --show-error \
    --connect-timeout 10 --max-time 30 \
    "https://api.wandb.ai/audit_logs?startDate=$WANDB_AUDIT_DATE&numDays=0&limit=25" |
  jq -e 'if (.audit_logs | type) == "array" then {range_start_time,range_end_time,count,has_more:(.next_cursor != null),events:[.audit_logs[] | {timestamp,action,response_code}]} else error("Unexpected audit response") end'
# HTH Guide Excerpt: end sample-multitenant-audit-events
