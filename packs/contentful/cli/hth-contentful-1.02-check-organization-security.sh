#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: contentful-1.2
#   guide: https://howtoharden.com/guides/contentful/#12-enforce-verified-saml-sign-in
#   profile: L1
#   mode: read-only
#   requires: Contentful CLI with sec-check, existing organization admin/owner login, jq
# Source: https://www.contentful.com/developers/docs/tutorials/cli/cli-security-check/
# HTH Guide Excerpt: begin check-organization-security
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${CONTENTFUL_ORG_ID:-}" =~ ^[[:alnum:]_-]+$ ]] || fail 'Missing or invalid CONTENTFUL_ORG_ID'
command -v contentful >/dev/null || fail 'Contentful CLI is not installed'

umask 077
scratch=$(mktemp -d) || fail 'Cannot create a private temporary directory'
trap 'rm -f "$scratch/report.json"; rmdir "$scratch"' EXIT
contentful organization sec-check --organization-id "$CONTENTFUL_ORG_ID" \
  --output-file "$scratch/report.json" >/dev/null 2>&1 || fail 'Contentful security check did not finish'
jq -e '
  (.permission_check.pass == true) and
  (.sso_enabled.pass|type=="boolean") and
  (.sso_enforced.pass|type=="boolean") and
  (.sso_exempt_users.pass|type=="boolean") and
  (.sso_exempt_users_with_mfa_disabled.pass|type=="boolean")
' "$scratch/report.json" >/dev/null 2>&1 || fail 'Missing or unauthorized SSO evidence'
jq '{
  scope:"Contentful CLI SSO results only; manually review permitted exceptions and IdP policy",
  enabled:.sso_enabled.pass,enforced:.sso_enforced.pass,
  no_exempt_users:.sso_exempt_users.pass,
  no_exempt_users_without_mfa:.sso_exempt_users_with_mfa_disabled.pass
}' "$scratch/report.json"
# HTH Guide Excerpt: end check-organization-security
