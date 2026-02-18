# =============================================================================
# HTH Datadog Control 1.2: Enable SAML Strict Mode
# Profile Level: L2 (Hardened)
# Frameworks: CIS 6.3, NIST IA-2
# Source: https://howtoharden.com/guides/datadog/#12-enable-saml-strict-mode
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Enforce SAML strict mode -- disables password and Google login
# Only applied at profile level 2 (Hardened) and above
resource "datadog_organization_settings" "saml_strict" {
  count = var.profile_level >= 2 ? 1 : 0

  name = "HTH Hardened Organization"

  settings {
    saml {
      enabled = true
    }

    saml_strict_mode {
      enabled = var.saml_strict_mode_enabled
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
