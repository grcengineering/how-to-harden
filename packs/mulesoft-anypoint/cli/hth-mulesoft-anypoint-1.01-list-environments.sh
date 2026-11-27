#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: mulesoft-anypoint-1.1
#   guide: https://howtoharden.com/guides/mulesoft-anypoint/#11-constrain-federation-and-environment-authority
#   profile: L1
#   mode: read-only
#   requires: Anypoint CLI 4.x account plugin and scoped Connected App auth
# Source (reviewed 2026-11-27): https://docs.mulesoft.com/anypoint-cli/latest/auth
# HTH Guide Excerpt: begin list-environments
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${ANYPOINT_ORG:-}" =~ ^[[:alnum:]_-]+$ ]] || fail 'Missing or invalid ANYPOINT_ORG'

: "${ANYPOINT_CLIENT_ID:?Use an approved Connected App ID}"
: "${ANYPOINT_CLIENT_SECRET:?Use an approved Connected App credential}"
command -v anypoint-cli-v4 >/dev/null || fail 'Anypoint CLI 4.x is not installed'
# Avoid running under an unreviewed credential/region override.
unset ANYPOINT_USERNAME ANYPOINT_PASSWORD ANYPOINT_BEARER
anypoint-cli-v4 account:environment:list
# HTH Guide Excerpt: end list-environments
