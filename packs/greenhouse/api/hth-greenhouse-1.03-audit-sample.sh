#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: greenhouse-1.3
#   guide: https://howtoharden.com/guides/greenhouse/#13-sample-harvest-v3-audit-evidence-without-exporting-personal-data
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq, eligible tenant, Harvest v3 OAuth token with audit access
# Source (checked 2026-11-27): https://docs.greenhouse.io/audit-log.html#events
# Review locally; protect evidence from unnecessary disclosure.

# HTH Guide Excerpt: begin greenhouse-evidence
set +x
set -euo pipefail
: "${HTH_GREENHOUSE_AUDIT_TOKEN:?Set an authorized Harvest v3 OAuth token with audit access.}"
: "${HTH_GREENHOUSE_ORG_ID:?Set the expected Greenhouse organization ID.}"
[[ "$HTH_GREENHOUSE_AUDIT_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ &&
   "$HTH_GREENHOUSE_ORG_ID" =~ ^[1-9][0-9]{0,14}$ ]] ||
  { printf 'Invalid OAuth token or organization ID.\n' >&2; exit 2; }
printf 'Authorization: Bearer %s\n' "$HTH_GREENHOUSE_AUDIT_TOKEN" |
  curl -q --silent --show-error --fail --proto '=https' --connect-timeout 10 --max-time 30 --header @- --header 'Size: 100'     'https://auditlog.us.greenhouse.io/events/?magic_time=last15minutes&event_types=harvest_access&paging=true' |
  jq -es --arg id "$HTH_GREENHOUSE_ORG_ID" '
    if length != 1 then error("Expected one audit response") else .[0] end
    | if (.results | type) != "array" or (.results | length) > 100 or (.paging | type) != "object"
      or (all(.results[]; (.organization_id | tostring) == $id and .event.type == "harvest_access") | not)
      then error("Unexpected audit response, filter or organization")
      else {window:"last15minutes",sample_count:(.results | length),
        organization_verified:((.results | length) > 0), more:(.paging.next_search_after != null)} end'
# HTH Guide Excerpt: end greenhouse-evidence
