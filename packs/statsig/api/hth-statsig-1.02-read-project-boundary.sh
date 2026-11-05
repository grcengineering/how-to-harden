#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: statsig-1.2
#   guide: https://howtoharden.com/guides/statsig/#12-close-projects-and-restrict-roles
#   profile: L1
#   mode: read-only
#   requires: STATSIG_CONSOLE_KEY, STATSIG_OUTPUT, bash, curl, jq, Bun
# HTH Statsig 1.2 — Close Projects and Restrict Roles; NIST AC-3, AC-6; SOC 2 CC6.1
# Source: https://api.statsig.com/openapi/20240601.json, settings/project GET (2026-11-05)
set +x
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
# HTH Guide Excerpt: begin read-project-boundary
statsig_api_init 1 console
statsig_request GET /console/v1/settings/project "$STATSIG_TEMP/response"
bun "$STATSIG_HELPER" project "$STATSIG_TEMP/response" "$STATSIG_TEMP/evidence"
statsig_finish "$STATSIG_TEMP/evidence"
# HTH Guide Excerpt: end read-project-boundary
