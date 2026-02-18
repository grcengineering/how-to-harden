# =============================================================================
# HTH Buildkite Control 1.1: Configure SAML Single Sign-On
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.3, 12.5 | NIST IA-2, IA-8
# Source: https://howtoharden.com/guides/buildkite/#11-configure-saml-single-sign-on
#
# NOTE: SAML SSO configuration is not managed by the Buildkite Terraform
# provider. SSO must be configured through the Buildkite UI:
#   Organization Settings > SSO > Configure SAML provider
#
# This file serves as a placeholder to document the control requirement.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# SAML SSO is configured via the Buildkite UI, not Terraform.
# This control requires:
#   1. Enterprise or Business tier Buildkite plan
#   2. SAML 2.0 compatible Identity Provider (Okta, Azure AD, etc.)
#   3. Configuration at: Organization Settings > SSO
#
# After SSO is configured in the UI, enforce it for all members.
# The buildkite_organization resource below ensures 2FA is active
# as a complementary authentication control.
#
# Validation: Verify SSO enforcement via the Buildkite API
# GET https://api.buildkite.com/v2/organizations/{org}/sso
# HTH Guide Excerpt: end terraform
