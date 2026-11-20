#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: assembled-1.3
#   guide: https://howtoharden.com/guides/assembled/#13-provision-and-deprovision-through-scim
#   profile: L1
#   mode: read-only
#   requires: bash, curl, python3; ASSEMBLED_API_KEY; private departed-addresses file
# HTH Assembled 1.3: Provision and Deprovision Through SCIM
# NIST: AC-2 | Available: GET /v0/people?include_deleted=true
# Source: https://docs.assembled.com/#people (verified 2026-11-16)
# Directory evidence only; deleted does not prove deactivation or access revocation.
# HTH Guide Excerpt: begin reconcile-departed-people
set +x
set -euo pipefail
umask 077
[[ $# == 1 ]] || { printf '%s\n' 'Usage: bash pack.sh /private/departed-addresses.txt' >&2; exit 1; }
python3 "$(dirname -- "$0")/common.py" leavers "$1"
# HTH Guide Excerpt: end reconcile-departed-people
