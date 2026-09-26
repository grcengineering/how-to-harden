#!/usr/bin/env bash
# HTH GitHub Control 1.10: Verify SAML SSO Status
# Profile: L2 | NIST: IA-2, IA-4, IA-8
# https://howtoharden.com/guides/github/#13-enable-saml-single-sign-on-sso-and-scim-provisioning
#
# SAML SSO is configured in the web UI + IdP. Its status is exposed only through
# GraphQL (the REST organization object has no SAML field). Set GITHUB_ENTERPRISE
# to check the enterprise; otherwise the organization is checked.
source "$(dirname "$0")/common.sh"

banner "1.10: Verify SAML SSO Status"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "1.10 Verifying SAML SSO status..."

# HTH Guide Excerpt: begin api-verify-saml-sso
if [ -n "${GITHUB_ENTERPRISE:-}" ]; then
  IDP=$(gh api graphql -f slug="${GITHUB_ENTERPRISE}" -f query='
    query($slug: String!) {
      enterprise(slug: $slug) { ownerInfo { samlIdentityProvider { ssoUrl issuer } } }
    }' --jq '.data.enterprise.ownerInfo.samlIdentityProvider')
else
  IDP=$(gh api graphql -f org="${GITHUB_ORG}" -f query='
    query($org: String!) {
      organization(login: $org) { samlIdentityProvider { ssoUrl issuer } }
    }' --jq '.data.organization.samlIdentityProvider')
fi
echo "SAML identity provider: ${IDP:-none}"
# HTH Guide Excerpt: end api-verify-saml-sso

if [ -n "${IDP}" ] && [ "${IDP}" != "null" ]; then
  pass "1.10 SAML SSO identity provider is configured"
  increment_applied
else
  fail "1.10 No SAML SSO identity provider configured"
  increment_failed
fi
summary
