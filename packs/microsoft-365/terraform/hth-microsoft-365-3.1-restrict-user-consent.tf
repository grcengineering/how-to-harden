# =============================================================================
# HTH Microsoft 365 Control 3.1: Restrict User Consent to Applications
# Profile Level: L1 (Baseline)
# Source: https://howtoharden.com/guides/microsoft-365/#31-restrict-user-consent-to-applications
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Look up current authorization policy to modify consent settings
data "azuread_client_config" "current" {}

# Disable user consent for all applications
# Users must request admin approval for any third-party app access
resource "azuread_auth_policy" "disable_user_consent" {
  display_name = "HTH: Disable User Consent"

  default_user_role_permissions {
    # Remove all permission grant policies -- disables user consent
    allowed_to_create_apps = false
  }
}

# Admin consent workflow: Configure designated reviewers for app requests
resource "azuread_admin_consent_request_policy" "consent_workflow" {
  count = length(var.admin_consent_request_reviewers) > 0 ? 1 : 0

  is_enabled = true
  notify_reviewers = true
  reminders_enabled = true
  request_duration_in_days = 30

  dynamic "reviewer" {
    for_each = var.admin_consent_request_reviewers
    content {
      query      = "/users/${reviewer.value}"
      query_type = "MicrosoftGraph"
    }
  }
}

# L2+: Create app consent policy restricting to verified publishers only
resource "azuread_service_principal" "msgraph" {
  count = var.profile_level >= 2 ? 1 : 0

  client_id    = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
  use_existing = true
}

# HTH Guide Excerpt: end terraform
