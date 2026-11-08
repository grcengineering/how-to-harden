#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ramp-5.1
#   guide: https://howtoharden.com/guides/ramp/#51-collect-and-preserve-audit-logs
#   profile: L1
#   mode: read-only
#   requires: bash, curl, python3; RAMP_ACCESS_TOKEN with audit_logs:read and Ramp Plus
# HTH Ramp 5.1: Collect and Preserve Audit Logs
# Profile: L1 | NIST: AC-6, AU-6 | CIS: 6.8, 8.2
# Available interfaces verified against https://docs.ramp.com/openapi/developer-api.json on 2026-11-08.
# Keep this file beside common.sh, response.py and response-shapes.json.
# HTH Guide Excerpt: begin collect-and-preserve-audit-logs
source "$(dirname -- "$0")/common.sh"
: "${RAMP_FROM_UTC:?Set explicit UTC start, e.g. 2026-11-01T00:00:00Z}"
: "${RAMP_TO_UTC:?Set explicit UTC end, e.g. 2026-11-02T00:00:00Z}"
query=$(python3 "$RAMP_HELPER" dates "$RAMP_FROM_UTC" "$RAMP_TO_UTC")
ramp_collect audit /developer/v1/audit-logs/events "$query" yes
ramp_report audit
# HTH Guide Excerpt: end collect-and-preserve-audit-logs
