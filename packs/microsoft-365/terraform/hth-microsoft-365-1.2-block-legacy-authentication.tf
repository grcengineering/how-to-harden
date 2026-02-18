# =============================================================================
# HTH Microsoft 365 Control 1.2: Block Legacy Authentication Protocols
# Profile Level: L1 (Baseline)
# Source: https://howtoharden.com/guides/microsoft-365/#12-block-legacy-authentication-protocols
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Conditional Access policy: Block legacy authentication protocols
# Blocks POP3, IMAP, SMTP AUTH, Basic Auth that bypass MFA
resource "azuread_conditional_access_policy" "block_legacy_auth" {
  display_name = "HTH: Block legacy authentication"
  state        = var.legacy_auth_policy_state

  conditions {
    users {
      included_users = ["All"]
    }

    applications {
      included_applications = ["All"]
    }

    # Target only legacy auth client types
    client_app_types = ["exchangeActiveSync", "other"]
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}

# HTH Guide Excerpt: end terraform
