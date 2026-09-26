#!/usr/bin/env bash
# HTH GitHub Control 4.04: Audit OAuth App Access
# Profile: L1 | NIST: AC-6, AC-17
# https://howtoharden.com/guides/github/#41-audit-and-restrict-oauth-app-access
source "$(dirname "$0")/common.sh"

banner "4.04: Audit OAuth Apps"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "4.04 Auditing OAuth app access for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-list-oauth-apps
# List OAuth app credentials that members have authorized against the organization.
# Requires GitHub Enterprise Cloud with SAML SSO; without SAML SSO there is no API
# for the organization's approved OAuth app list (review it under Third-party Access).
info "4.04 Listing OAuth app credential authorizations for ${GITHUB_ORG}..."
AUTHS=$(gh_get "/orgs/${GITHUB_ORG}/credential-authorizations?per_page=100") || {
  fail "4.04 credential-authorizations requires GitHub Enterprise Cloud with SAML SSO"
  increment_failed
  summary
  exit 0
}
OAUTH=$(echo "${AUTHS}" | jq '[.[] | select(.credential_type | test("OAuth"; "i"))]')
echo "${OAUTH}" | jq '.[] | {login, scopes, credential_authorized_at, credential_accessed_at}'
# HTH Guide Excerpt: end api-list-oauth-apps

APP_COUNT=$(echo "${OAUTH}" | jq 'length')
if [ "${APP_COUNT}" -gt 20 ]; then
  warn "4.04 ${APP_COUNT} OAuth app authorizations -- review and revoke unused apps"
fi

increment_applied
summary
