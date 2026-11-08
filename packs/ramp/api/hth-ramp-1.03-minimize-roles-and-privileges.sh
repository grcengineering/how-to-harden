#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ramp-1.3
#   guide: https://howtoharden.com/guides/ramp/#13-minimize-roles-and-privileges
#   profile: L1
#   mode: read-only
#   requires: bash, curl, python3; RAMP_ACCESS_TOKEN with users:read
# HTH Ramp 1.3: Minimize Roles and Privileges
# Profile: L1 | NIST: AC-6, AU-6 | CIS: 6.8, 8.2
# Available interfaces verified against https://docs.ramp.com/openapi/developer-api.json on 2026-11-08.
# Keep this file beside common.sh, response.py and response-shapes.json.
# HTH Guide Excerpt: begin minimize-roles-and-privileges
source "$(dirname -- "$0")/common.sh"
ramp_collect users /developer/v1/users "?page_size=100" yes
ramp_collect roles /developer/v1/roles "" no
ramp_report users roles
# HTH Guide Excerpt: end minimize-roles-and-privileges
