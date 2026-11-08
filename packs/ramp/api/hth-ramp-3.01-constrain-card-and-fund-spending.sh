#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ramp-3.1
#   guide: https://howtoharden.com/guides/ramp/#31-constrain-card-and-fund-spending
#   profile: L1
#   mode: read-only
#   requires: bash, curl, python3; RAMP_ACCESS_TOKEN with funds:read and spend_programs:read
# HTH Ramp 3.1: Constrain Card and Fund Spending
# Profile: L1 | NIST: AC-6, AU-6 | CIS: 6.8, 8.2
# Available interfaces verified against https://docs.ramp.com/openapi/developer-api.json on 2026-11-08.
# Keep this file beside common.sh, response.py and response-shapes.json.
# HTH Guide Excerpt: begin constrain-card-and-fund-spending
source "$(dirname -- "$0")/common.sh"
ramp_collect funds /developer/v1/funds "?page_size=100" yes
ramp_collect programs /developer/v1/spend-programs "?page_size=100" yes
ramp_report funds programs
# HTH Guide Excerpt: end constrain-card-and-fund-spending
