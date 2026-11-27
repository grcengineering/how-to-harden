#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: files-com-1.1
#   guide: https://howtoharden.com/guides/files-com/#11-review-authentication-and-2fa-per-user
#   profile: L1
#   mode: read-only
#   requires: files-cli authenticated to approved site, jq
# Source (reviewed 2026-11-27): https://developers.files.com/cli/resources/user-accounts/users/ ; https://github.com/Files-com/files-cli
# HTH Guide Excerpt: begin read-user-2fa-policy-cli
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${FILES_USER_ID:-}" =~ ^[1-9][0-9]{0,14}$ ]] || fail 'Missing or invalid FILES_USER_ID'

response=$(files-cli users find --id="$FILES_USER_ID" --format json --non-interactive) || fail 'Files.com CLI did not return user evidence'

jq -e --argjson expected "$FILES_USER_ID" '(.id==$expected and (.authentication_method|type)=="string" and (.require_2fa|type)=="string" and (.disabled|type)=="boolean")' <<<"$response" >/dev/null || fail 'Wrong user or incomplete authentication response'
jq '{scope:"one user configuration; not effective MFA evidence",user:{id,authentication_method,require_2fa,disabled}}' <<<"$response"
# HTH Guide Excerpt: end read-user-2fa-policy-cli
