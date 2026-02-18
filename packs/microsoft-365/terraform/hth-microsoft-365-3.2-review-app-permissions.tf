# =============================================================================
# HTH Microsoft 365 Control 3.2: Review and Revoke Overprivileged App Permissions
# Profile Level: L2 (Hardened)
# Source: https://howtoharden.com/guides/microsoft-365/#32-review-and-revoke-overprivileged-app-permissions
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Data source: Enumerate all enterprise applications (service principals)
# Use this to audit existing app permissions
data "azuread_service_principals" "all_enterprise_apps" {
  count        = var.profile_level >= 2 ? 1 : 0
  return_all   = true
}

# L2: Application registration restrictions
# Prevent non-admin users from registering new applications
resource "azuread_auth_policy" "restrict_app_registration" {
  count = var.profile_level >= 2 ? 1 : 0

  display_name = "HTH: Restrict Application Registration"

  default_user_role_permissions {
    allowed_to_create_apps = false
  }
}

# L3: Block applications without verified publisher
resource "azuread_conditional_access_policy" "block_unverified_apps" {
  count = var.profile_level >= 3 ? 1 : 0

  display_name = "HTH: Block access from unverified publisher apps"
  state        = "enabledForReportingButNotEnforced"

  conditions {
    users {
      included_users = ["All"]
    }

    applications {
      included_applications = ["All"]
    }

    client_app_types = ["all"]
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}

# HTH Guide Excerpt: end terraform
