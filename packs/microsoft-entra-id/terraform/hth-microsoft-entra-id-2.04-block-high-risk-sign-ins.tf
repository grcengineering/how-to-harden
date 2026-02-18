# =============================================================================
# HTH Microsoft Entra ID Control 2.4: Block High-Risk Sign-Ins
# Profile Level: L2 (Hardened)
# Frameworks: CIS 6.4, NIST SI-4
# Source: https://howtoharden.com/guides/microsoft-entra-id/#24-block-high-risk-sign-ins
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Conditional Access policy to block high-risk sign-ins using
# Entra ID Protection machine learning detection (requires P2 license)
resource "azuread_conditional_access_policy" "block_high_risk_signins" {
  count = var.profile_level >= 2 ? 1 : 0

  display_name = "HTH: Block high-risk sign-ins"
  state        = var.high_risk_policy_state

  conditions {
    users {
      included_users  = ["All"]
      excluded_groups = [azuread_group.emergency_access.object_id]
    }

    applications {
      included_applications = ["All"]
    }

    client_app_types = ["browser", "mobileAppsAndDesktopClients"]

    sign_in_risk_levels = ["high"]
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}

# Conditional Access policy requiring MFA + password change for medium-risk sign-ins
resource "azuread_conditional_access_policy" "remediate_medium_risk_signins" {
  count = var.profile_level >= 2 ? 1 : 0

  display_name = "HTH: Require MFA for medium-risk sign-ins"
  state        = var.high_risk_policy_state

  conditions {
    users {
      included_users  = ["All"]
      excluded_groups = [azuread_group.emergency_access.object_id]
    }

    applications {
      included_applications = ["All"]
    }

    client_app_types = ["browser", "mobileAppsAndDesktopClients"]

    sign_in_risk_levels = ["medium"]
  }

  grant_controls {
    operator          = "AND"
    built_in_controls = ["mfa", "passwordChange"]
  }
}
# HTH Guide Excerpt: end terraform
