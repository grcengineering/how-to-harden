#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: statsig-5.2
#   guide: https://howtoharden.com/guides/statsig/#52-verify-retention-and-data-deletion-outcomes
#   profile: L2
#   mode: read-only
#   requires: STATSIG_SERVER_KEY, STATSIG_REQUEST_ID, STATSIG_OUTPUT, bash, curl, jq, Bun
# HTH Statsig 5.2 — Verify Retention and Data Deletion Outcomes; NIST SI-12; SOC 2 CC6.5
# Source: https://docs.statsig.com/compliance/user_data_deletion_requests (2026-11-05)
# POST here reads an EXISTING request status. No deletion submission is implemented.
set +x
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
# HTH Guide Excerpt: begin read-existing-deletion-status
statsig_api_init 2 server
[[ "${STATSIG_REQUEST_ID:-}" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$ ]] || statsig_unknown 'set one reviewed existing request ID'
jq -n --arg request_id "$STATSIG_REQUEST_ID" '{request_id:$request_id}' > "$STATSIG_TEMP/request"
statsig_request POST /v1/get_delete_user_data_request_status "$STATSIG_TEMP/response" "$STATSIG_TEMP/request"
bun "$STATSIG_HELPER" status "$STATSIG_TEMP/response" "$STATSIG_TEMP/evidence"
statsig_finish "$STATSIG_TEMP/evidence"
# HTH Guide Excerpt: end read-existing-deletion-status
