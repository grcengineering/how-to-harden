#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: document360-1.2
#   guide: https://howtoharden.com/guides/document360/#12-verify-v3-api-key-project-scope
#   profile: L1
#   mode: read-only
#   requires: curl, jq, approved v3 project credential
# Source (reviewed 2026-11-27): https://apidocs.document360.com/apidocs/making-your-first-request
# HTH Guide Excerpt: begin check-v3-project-visibility
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${DOCUMENT360_API_KEY:-}" =~ ^[[:alnum:]_.~+/=-]+$ ]] || fail 'Missing or invalid DOCUMENT360_API_KEY'
[[ "${DOCUMENT360_PROJECT_ID:-}" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]] || fail 'Missing or invalid DOCUMENT360_PROJECT_ID'

case "${DOCUMENT360_REGION:-eu}" in
  eu) host=apihub.document360.io ;;
  us) host=apihub.us.document360.io ;;
  ca) host=apihub.ca.document360.io ;;
  *) fail 'DOCUMENT360_REGION must be eu, us or ca' ;;
esac
response=$(printf 'header = "X-API-Key: %s"\n' "$DOCUMENT360_API_KEY" |
  curl --disable --config - --silent --show-error --fail --proto '=https' \
    --connect-timeout 10 --max-time 45 "https://$host/v3/projects") ||
  fail 'Project read did not succeed'
jq -e '
  .success==true and (.data|type=="array") and
  all(.data[];(.id|type=="string")) and
  .pagination.page==1 and (.pagination.has_more|type=="boolean")
' <<<"$response" >/dev/null 2>&1 || fail 'Unexpected project response'
jq -e --arg expected "$DOCUMENT360_PROJECT_ID" '
  {matches_expected_project_only:
    (.pagination.has_more==false and .pagination.total_count==1 and (.data|length)==1 and
    ((.data[0].id // "")|ascii_downcase)==($expected|ascii_downcase)),
   returned_project_count:(.data|length),additional_pages:.pagination.has_more,
   action_grants_checked:false}
  | if .matches_expected_project_only then . else false end
' <<<"$response" || fail 'First page did not establish exclusive visibility of the expected project'
# HTH Guide Excerpt: end check-v3-project-visibility
