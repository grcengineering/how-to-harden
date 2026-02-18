# =============================================================================
# HTH Datadog Control 1.1: Configure SAML Single Sign-On
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.3/12.5, NIST IA-2/IA-8
# Source: https://howtoharden.com/guides/datadog/#11-configure-saml-single-sign-on
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Enable SAML SSO for the Datadog organization
resource "datadog_organization_settings" "saml_sso" {
  name = "HTH Hardened Organization"

  settings {
    saml {
      enabled = true
    }

    saml_autocreate_users_domains {
      enabled = length(var.saml_autocreate_users_domains) > 0
      domains = var.saml_autocreate_users_domains
    }

    saml_idp_initiated_login {
      enabled = true
    }
  }
}
# HTH Guide Excerpt: end terraform
