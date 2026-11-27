#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: genesys-cloud-cx-1.2
#   guide: https://howtoharden.com/guides/genesys-cloud-cx/#12-review-role-definitions-and-division-grants
#   profile: L1
#   mode: read-only
#   requires: Genesys Cloud CLI gc, jq, preconfigured read-only profile
# Source (reviewed 2026-11-27): https://github.com/MyPureCloud/platform-client-sdk-cli
# HTH Guide Excerpt: begin list-visible-role-definitions
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${GENESYS_CLI_PROFILE:-}" =~ ^[[:alnum:]_.-]+$ ]] || fail 'Missing or invalid GENESYS_CLI_PROFILE'

command -v gc >/dev/null || fail 'Genesys Cloud CLI is not installed'
# Use only a reviewed profile with no unapproved proxy or gateway configuration.
response=$(gc authorization roles list --profile "$GENESYS_CLI_PROFILE" --pageSize 25 --pageNumber 1 --autopaginate=false --userCount=false --outputformat JSON) ||
  fail 'Genesys CLI role read did not succeed'
jq -e '(.entities|type=="array") and all(.entities[];(.id|type=="string"))' <<<"$response" >/dev/null 2>&1 ||
  fail 'Unexpected CLI response'
jq '{returned_role_ids:[.entities[].id],next_page_present:((.nextUri // "")!=""),effective_assignments_checked:false}' <<<"$response"
# HTH Guide Excerpt: end list-visible-role-definitions
