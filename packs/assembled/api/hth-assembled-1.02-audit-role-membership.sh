#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: assembled-1.2
#   guide: https://howtoharden.com/guides/assembled/#12-minimize-administrative-roles
#   profile: L1
#   mode: read-only
#   requires: bash, curl, python3; ASSEMBLED_API_KEY
# HTH Assembled 1.2: Minimize Administrative Roles
# NIST: AC-6 | Available: GET /v0/roles and GET /v0/people
# Source: https://docs.assembled.com/#roles (verified 2026-11-16)
# Run from a full packs/assembled checkout; common.py is required.
# HTH Guide Excerpt: begin audit-role-membership
set +x
set -euo pipefail
umask 077
[[ $# == 0 ]] || { printf '%s\n' 'This pack accepts no arguments.' >&2; exit 1; }
python3 "$(dirname -- "$0")/common.py" roles
# HTH Guide Excerpt: end audit-role-membership
