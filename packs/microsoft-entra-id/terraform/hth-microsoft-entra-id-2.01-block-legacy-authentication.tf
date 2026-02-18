# =============================================================================
# HTH Microsoft Entra ID Control 2.1: Block Legacy Authentication
# Profile Level: L1 (Baseline)
# Frameworks: CIS 4.2, NIST IA-2/AC-17, CIS Azure 1.1.2
# Source: https://howtoharden.com/guides/microsoft-entra-id/#21-block-legacy-authentication
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Conditional Access policy to block legacy authentication protocols
# (Basic Auth, POP, IMAP, SMTP AUTH) that cannot enforce MFA
resource "azuread_conditional_access_policy" "block_legacy_auth" {
  display_name = "HTH: Block legacy authentication"
  state        = var.legacy_auth_policy_state

  conditions {
    users {
      included_users = ["All"]
      excluded_groups = [azuread_group.emergency_access.object_id]
    }

    applications {
      included_applications = ["All"]
    }

    client_app_types = ["exchangeActiveSync", "other"]
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}
# HTH Guide Excerpt: end terraform
