# =============================================================================
# HTH Microsoft Entra ID Control 4.1: Restrict User Consent to Applications
# Profile Level: L1 (Baseline)
# Frameworks: CIS 2.5, NIST AC-3/CM-7, CIS Azure 2.1
# Source: https://howtoharden.com/guides/microsoft-entra-id/#41-restrict-user-consent-to-applications
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Disable user consent to third-party applications.
# Prevents OAuth consent phishing by requiring admin approval for
# all new application access requests.
resource "azuread_authorization_policy" "consent_policy" {
  display_name = "Authorization Policy"

  # Disable user consent -- users cannot grant OAuth permissions
  default_user_role_permissions {
    allowed_to_create_apps             = false
    allowed_to_create_security_groups  = true
    allowed_to_create_tenants          = false
    allowed_to_read_bitlocker_keys_for_owned_device = true
    allowed_to_read_other_users        = true

    # Empty list = no user consent policies assigned = user consent disabled
    permission_grant_policies_assigned = []
  }
}

# Configure admin consent workflow so users can request access
# and designated reviewers approve or deny.
#
# NOTE: The admin consent workflow configuration requires Microsoft Graph API
# or the Entra admin center. Terraform manages the authorization policy;
# configure the consent workflow reviewers via:
#   Applications > Enterprise applications > Consent and permissions > Admin consent settings
#
# Graph API equivalent:
#   PATCH https://graph.microsoft.com/v1.0/policies/adminConsentRequestPolicy
#   {
#     "isEnabled": true,
#     "notifyReviewers": true,
#     "remindersEnabled": true,
#     "requestDurationInDays": 30,
#     "reviewers": [
#       { "query": "/users/<reviewer-id>", "queryType": "MicrosoftGraph" }
#     ]
#   }
locals {
  admin_consent_workflow = {
    enabled              = true
    reviewer_ids         = var.admin_consent_reviewer_ids
    request_duration     = 30
    notify_reviewers     = true
    reminders_enabled    = true
    manual_configuration = "Configure reviewers via Entra admin center: Applications > Enterprise applications > Consent and permissions"
  }
}
# HTH Guide Excerpt: end terraform
