#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: anaplan-1.3
#   guide: https://howtoharden.com/guides/anaplan/#13-collect-tenant-audit-evidence
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq, licensed Audit and approved Tenant Auditor token
# Source (checked 2026-11-27): https://help.anaplan.com/retrieve-audit-events-in-json-format-3f35be02-532c-47df-a75b-74ecc2b21397
# Collect narrow evidence; review locally and protect output from disclosure.

# HTH Guide Excerpt: begin anaplan-evidence
set +x
set -euo pipefail
fail() { printf '%s\n' "$*" >&2; exit 2; }
: "${HTH_ANAPLAN_TOKEN:?Set an approved Tenant Auditor token.}"
[[ "$HTH_ANAPLAN_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || fail 'Invalid token format.'
printf 'Authorization: AnaplanAuthToken %s\n' "$HTH_ANAPLAN_TOKEN" |
  curl -q --silent --show-error --fail --proto '=https' --connect-timeout 10 --max-time 30 --header @- --header 'Accept: application/json' \
    'https://audit.anaplan.com/audit/api/1/events?type=all&intervalInHours=24&limit=20' |
  jq -e -s 'if length == 1 and (.[0].response | type) == "array"
    then .[0] | {sampleCount: (.response | length), totalSize: .meta.paging.totalSize,
      sample: [.response[] | {eventTypeId, eventDate, success}]}
    else error("No usable audit sample; validate auth, entitlement and the event window") end'
# HTH Guide Excerpt: end anaplan-evidence
