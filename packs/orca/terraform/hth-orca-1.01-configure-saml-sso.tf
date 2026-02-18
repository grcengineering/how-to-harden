# =============================================================================
# HTH Orca Control 1.1: Configure SAML Single Sign-On
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.3/12.5, NIST IA-2/IA-8
# Source: https://howtoharden.com/guides/orca/#11-configure-saml-single-sign-on
#
# Note: SAML SSO configuration in Orca Security is performed through the
# platform UI (Settings > Authentication > SSO). The Terraform provider does
# not expose SAML IdP configuration resources directly.
#
# This file creates the SSO user group to organize SSO-authenticated users
# and enforce group-based access policies once SSO is configured.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# SSO user group -- assign SSO-authenticated users here for group-based policies
resource "orcasecurity_group" "sso_users" {
  name        = var.sso_group_name
  description = "Group for SSO-authenticated users. Assign this group in SAML IdP attribute mappings to enforce group-based access control."
  sso_group   = true
  users       = var.sso_user_ids
}
# HTH Guide Excerpt: end terraform
