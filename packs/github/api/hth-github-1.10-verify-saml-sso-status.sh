#!/usr/bin/env bash
# HTH GitHub Control 1.10: Verify SAML SSO Status
# Profile: L2 | NIST: IA-2, IA-4, IA-8
# https://howtoharden.com/guides/github/#13-enable-saml-single-sign-on-sso-and-scim-provisioning
source "$(dirname "$0")/common.sh"

banner "1.10: Verify SAML SSO Status"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "1.10 Verifying SAML SSO status for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-verify-saml-sso
# Enable SAML SSO (requires Enterprise Cloud)
# Configuration done via GitHub web UI + IdP
# API can verify status:

gh api /orgs/{org} --jq '.saml_identity_provider'
# HTH Guide Excerpt: end api-verify-saml-sso

increment_applied
summary
