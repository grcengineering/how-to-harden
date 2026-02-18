# =============================================================================
# HTH Microsoft Entra ID Control 2.2: Require MFA for All Users
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.3, NIST IA-2(1), CIS Azure 1.1.3
# Source: https://howtoharden.com/guides/microsoft-entra-id/#22-require-mfa-for-all-users
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Conditional Access policy requiring MFA for all interactive sign-ins
resource "azuread_conditional_access_policy" "require_mfa_all_users" {
  display_name = "HTH: Require MFA for all users"
  state        = var.mfa_policy_state

  conditions {
    users {
      included_users  = ["All"]
      excluded_groups = [azuread_group.emergency_access.object_id]
    }

    applications {
      included_applications = ["All"]
    }

    client_app_types = ["browser", "mobileAppsAndDesktopClients"]
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }
}
# HTH Guide Excerpt: end terraform
