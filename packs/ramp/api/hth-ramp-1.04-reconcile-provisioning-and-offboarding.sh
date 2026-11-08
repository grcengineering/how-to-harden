#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ramp-1.4
#   guide: https://howtoharden.com/guides/ramp/#14-reconcile-provisioning-and-offboarding
#   profile: L1
#   mode: read-only
#   requires: bash, curl, python3; RAMP_ACCESS_TOKEN with users:read
# HTH Ramp 1.4: Reconcile Provisioning and Offboarding
# Profile: L1 | NIST: AC-6, AU-6 | CIS: 6.8, 8.2
# Available interfaces verified against https://docs.ramp.com/openapi/developer-api.json on 2026-11-08.
# Keep this file beside common.sh, response.py and response-shapes.json.
# HTH Guide Excerpt: begin reconcile-provisioning-and-offboarding
source "$(dirname -- "$0")/common.sh"
# Read-only reconciliation, NOT an approved deactivation list. No PATCH is sent.
# List explicitly suspended users as well: the default endpoint omits them.
ramp_collect users /developer/v1/users "?page_size=100" yes
cp "$RAMP_TMP/users.ndjson" "$RAMP_TMP/default-users"
ramp_collect users /developer/v1/users "?page_size=100&status=USER_SUSPENDED" yes
cat "$RAMP_TMP/default-users" >> "$RAMP_TMP/users.ndjson"
ramp_report users
# HTH Guide Excerpt: end reconcile-provisioning-and-offboarding
