# =============================================================================
# HTH Microsoft Entra ID Control 3.2: Configure Access Reviews
# Profile Level: L2 (Hardened)
# Frameworks: CIS 5.1/5.3, NIST AC-2(3)
# Source: https://howtoharden.com/guides/microsoft-entra-id/#32-configure-access-reviews
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Recurring access review for the Global Administrator role.
# Ensures continued business need for privileged access by requiring
# periodic reviewer attestation. Non-attested access is auto-removed.
#
# NOTE: The azuread provider has limited access review support.
# This resource uses the azuread_access_review_schedule_definition
# if available, otherwise configure via admin center or Graph API.

# Access review for Global Administrator eligible assignments
resource "azuread_privileged_access_group_assignment_schedule_request" "access_review_placeholder" {
  count = var.profile_level >= 2 && length(var.access_review_reviewer_ids) > 0 ? 0 : 0

  # Placeholder: Terraform azuread provider does not natively support
  # access review schedule definitions. Use one of these alternatives:
  #
  # Option 1: Microsoft Graph API (recommended)
  #   POST https://graph.microsoft.com/v1.0/identityGovernance/accessReviews/definitions
  #   {
  #     "displayName": "HTH: Global Admin Access Review",
  #     "scope": {
  #       "query": "/roleManagement/directory/roleAssignmentScheduleInstances?$filter=(roleDefinitionId eq '<global-admin-role-id>')",
  #       "queryType": "MicrosoftGraph"
  #     },
  #     "reviewers": [{ "query": "/users/<reviewer-id>", "queryType": "MicrosoftGraph" }],
  #     "settings": {
  #       "mailNotificationsEnabled": true,
  #       "reminderNotificationsEnabled": true,
  #       "justificationRequiredOnApproval": true,
  #       "defaultDecisionEnabled": true,
  #       "defaultDecision": "Deny",
  #       "autoApplyDecisionsEnabled": true,
  #       "recurrence": {
  #         "pattern": { "type": "absoluteMonthly", "interval": 3 },
  #         "range": { "type": "noEnd" }
  #       }
  #     }
  #   }
  #
  # Option 2: PowerShell (see guide Section 3.2)
  #
  # Option 3: Entra admin center
  #   Identity governance > Access reviews > + New access review

  group_id        = ""
  principal_id    = ""
  assignment_type = "member"
  justification   = "placeholder"
}

# Output a reminder for manual configuration
locals {
  access_review_config = var.profile_level >= 2 ? {
    status              = "MANUAL_CONFIGURATION_REQUIRED"
    target_role         = "Global Administrator"
    review_frequency    = var.access_review_frequency
    reviewer_ids        = var.access_review_reviewer_ids
    auto_remove_denied  = true
    instructions        = "Configure via Entra admin center: Identity governance > Access reviews"
  } : null
}
# HTH Guide Excerpt: end terraform
