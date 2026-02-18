# =============================================================================
# HTH Harness Control 1.1: Configure SAML Single Sign-On
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.3/12.5, NIST IA-2/IA-8
# Source: https://howtoharden.com/guides/harness/#11-configure-saml-single-sign-on
# =============================================================================

# HTH Guide Excerpt: begin terraform
# SAML SSO provider configuration for centralized authentication
resource "harness_platform_connector_customhealthsource" "saml_placeholder" {
  # Note: Harness SAML SSO is configured via the harness_platform_sso resource
  # or account-level settings. The provider exposes SSO management through
  # the account authentication configuration.
  count = 0 # Placeholder -- see resource below
}

# Configure SAML SSO login mechanism at the account level
resource "harness_platform_usergroup" "sso_linked_admins" {
  identifier         = "sso_linked_admins"
  name               = "SSO Linked Administrators"
  linked_sso_type    = "SAML"
  externally_managed = true

  notification_configs {
    type              = "EMAIL"
    group_email       = length(var.admin_user_emails) > 0 ? var.admin_user_emails[0] : ""
    send_email_to_all = true
  }
}

# User group for SAML-linked general access
resource "harness_platform_usergroup" "sso_users" {
  identifier               = "sso_users"
  name                     = "SSO Users"
  linked_sso_type          = "SAML"
  externally_managed       = true
  sso_group_name           = var.saml_group_attribute
  linked_sso_display_name  = var.saml_provider_name
}
# HTH Guide Excerpt: end terraform
