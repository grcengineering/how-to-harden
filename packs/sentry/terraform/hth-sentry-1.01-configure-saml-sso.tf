# =============================================================================
# HTH Sentry Control 1.1: Configure SAML Single Sign-On
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.3/12.5, NIST IA-2/IA-8
# Source: https://howtoharden.com/guides/sentry/#11-configure-saml-single-sign-on
#
# NOTE: The jianyuan/sentry provider does not expose SAML SSO configuration
# as a managed resource. SSO must be configured via the Sentry UI or API.
# This file retrieves the organization data source for audit verification
# and documents the required API approach.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Reference the Sentry organization for SSO audit verification
data "sentry_organization" "main" {
  slug = var.sentry_organization
}

# ---------------------------------------------------------------------------
# SAML SSO must be configured via Sentry UI or API:
#
#   1. Navigate to Settings > Auth > Configure SAML2
#   2. Provide IdP Entity ID, SSO URL, and X.509 certificate
#   3. Configure attribute mapping (email, firstName, lastName)
#   4. Download Sentry SP metadata for your IdP
#   5. Test authentication, then enable SSO enforcement
#
# API alternative (requires owner-level auth token):
#   PUT /api/0/organizations/{org_slug}/
#     { "require_sso": true }
#
# Verify SSO status:
#   GET /api/0/organizations/{org_slug}/
#     -> check "require2FA" and SSO provider fields
# ---------------------------------------------------------------------------
# HTH Guide Excerpt: end terraform
