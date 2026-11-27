#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tabnine-1.1
#   guide: https://howtoharden.com/guides/tabnine/#11-require-explicit-assignment-to-an-approved-team
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq, approved tenant origin and scoped Tabnine PAT
# HTH tabnine 1.1: Require explicit assignment to an approved team
# Profile: L1 (Crawl)
# Guide: https://howtoharden.com/guides/tabnine/
# Reference: https://raw.githubusercontent.com/codota/t9-api-yamls/refs/heads/main/docs/unified-tabnine-api.yaml
# HTH Guide Excerpt: begin sample-active-unassigned-users
set -euo pipefail
set +x
: "${TABNINE_BASE_URL:?Set the verified Tabnine tenant HTTPS origin}"
[[ "$TABNINE_BASE_URL" =~ ^https://[A-Za-z0-9][A-Za-z0-9.-]*(:[1-9][0-9]{0,4})?$ ]] ||
  { printf '%s\n' 'Supply an HTTPS origin with no path or credentials.' >&2; exit 2; }
: "${TABNINE_PAT:?Set the approved read-only API key}"
[[ "${TABNINE_PAT}" =~ ^[A-Za-z0-9._~-]+$ ]] ||
  { printf '%s\n' 'Invalid bearer token characters.' >&2; exit 2; }
printf 'header = "Authorization: Bearer %s"\n' "${TABNINE_PAT}" |
  curl --disable --config - --proto '=https' --fail --silent --show-error \
    --connect-timeout 10 --max-time 30 \
    "$TABNINE_BASE_URL/api/v1/organization/users?limit=25&offset=0&teamMember=false&active=true" |
  jq -e 'if (.data | type) == "array" then {sample_count: (.data | length)} else error("Unexpected organization user response") end'
# HTH Guide Excerpt: end sample-active-unassigned-users
