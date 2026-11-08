#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ramp-2.3
#   guide: https://howtoharden.com/guides/ramp/#23-review-accounting-integrations
#   profile: L1
#   mode: read-only
#   requires: bash, curl, python3; RAMP_ACCESS_TOKEN with accounting:read
# HTH Ramp 2.3: Review Accounting Integrations
# Profile: L1 | NIST: AC-6, AU-6 | CIS: 6.8, 8.2
# Available interfaces verified against https://docs.ramp.com/openapi/developer-api.json on 2026-11-08.
# Keep this file beside common.sh, response.py and response-shapes.json.
# HTH Guide Excerpt: begin review-accounting-integrations
source "$(dirname -- "$0")/common.sh"
ramp_collect accounting /developer/v1/accounting/all-connections "" no
ramp_report accounting
# HTH Guide Excerpt: end review-accounting-integrations
