#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: microsoft-dynamics-365-1.2
#   guide: https://howtoharden.com/guides/microsoft-dynamics-365/#12-confirm-the-environment-audit-configuration
#   profile: L1
#   mode: read-only
#   requires: curl, jq, Dataverse bearer for exact environment
# Source (reviewed 2026-11-27): https://learn.microsoft.com/en-us/power-apps/developer/data-platform/auditing/configure
# HTH Guide Excerpt: begin read-dataverse-audit-flags
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${HTH_DATAVERSE_HOST:-}" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.crm[0-9]{0,2}\.dynamics\.com$ ]] || fail 'Missing or invalid HTH_DATAVERSE_HOST'
[[ "${HTH_DATAVERSE_ORG_ID:-}" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]] || fail 'Missing or invalid HTH_DATAVERSE_ORG_ID'
[[ "${HTH_DATAVERSE_TOKEN:-}" =~ ^[[:alnum:]_.~+/=-]+$ ]] || fail 'Missing or invalid HTH_DATAVERSE_TOKEN'

response=$(printf 'header = "Authorization: Bearer %s"\n' "$HTH_DATAVERSE_TOKEN" |
  curl --disable --config - --silent --show-error --fail --proto '=https' \
    --connect-timeout 10 --max-time 45 --header 'Accept: application/json' \
    "https://$HTH_DATAVERSE_HOST/api/data/v9.2/organizations($HTH_DATAVERSE_ORG_ID)?\$select=organizationid,isauditenabled,isuseraccessauditenabled,auditretentionperiodv2") ||
  fail 'Dataverse audit setting read failed'
jq -e --arg id "$HTH_DATAVERSE_ORG_ID" '
  (.organizationid|ascii_downcase)==($id|ascii_downcase) and
  (.isauditenabled|type=="boolean") and (.isuseraccessauditenabled|type=="boolean") and
  (.auditretentionperiodv2|type=="number")
' <<<"$response" >/dev/null 2>&1 || fail 'Unexpected organization ID or audit flags'
jq '{environment_auditing_enabled:.isauditenabled,user_access_auditing_enabled:.isuseraccessauditenabled,
   audit_retention_days:.auditretentionperiodv2,table_coverage_checked:false,event_delivery_checked:false}' <<<"$response"
# HTH Guide Excerpt: end read-dataverse-audit-flags
