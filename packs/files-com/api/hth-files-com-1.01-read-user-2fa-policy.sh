#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: files-com-1.1
#   guide: https://howtoharden.com/guides/files-com/#11-review-authentication-and-2fa-per-user
#   profile: L1
#   mode: read-only
#   requires: curl, jq, authorized Files.com user or site API key
# Source (reviewed 2026-11-27): https://developers.files.com/rest/resources/user-accounts/users/
# HTH Guide Excerpt: begin read-user-2fa-policy
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${FILES_USER_ID:-}" =~ ^[1-9][0-9]{0,14}$ ]] || fail 'Missing or invalid FILES_USER_ID'
[[ "${FILES_SITE:-}" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]] || fail 'Missing or invalid FILES_SITE'
[[ "${FILES_API_KEY:-}" =~ ^[[:alnum:]_=-]+$ ]] || fail 'Missing or invalid FILES_API_KEY'

response=$(printf 'header = "X-FilesAPI-Key: %s"\n' "$FILES_API_KEY" |
  curl --disable --config - --silent --show-error --fail --proto '=https' \
    --connect-timeout 10 --max-time 45 "https://$FILES_SITE.files.com/api/rest/v1/users/$FILES_USER_ID.json") || fail 'Files.com user request did not succeed'

jq -e --argjson expected "$FILES_USER_ID" '(.id==$expected and (.authentication_method|type)=="string" and (.require_2fa|type)=="string" and (.disabled|type)=="boolean")' <<<"$response" >/dev/null || fail 'Wrong user or incomplete authentication response'
jq '{scope:"one user configuration; not effective MFA evidence",user:{id,authentication_method,require_2fa,disabled}}' <<<"$response"
# HTH Guide Excerpt: end read-user-2fa-policy
