# =============================================================================
# HTH Auth0 Control 2.1: Enforce Strong Password Policies
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5 | CIS 5.2
# Source: https://howtoharden.com/guides/auth0/#21-enforce-strong-password-policies
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "auth0_connection" "database" {
  name     = "Username-Password-Authentication"
  strategy = "auth0"

  options {
    password_policy        = "excellent"
    brute_force_protection = true

    password_complexity_options {
      min_length = 14
    }

    password_history {
      enable = true
      size   = 5
    }

    password_dictionary {
      enable = true
    }

    password_no_personal_info {
      enable = true
    }
  }
}
# HTH Guide Excerpt: end terraform
