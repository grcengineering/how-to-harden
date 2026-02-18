# =============================================================================
# HTH Microsoft 365 Control 4.2: Configure External Sharing Restrictions
# Profile Level: L1 (Baseline)
# Source: https://howtoharden.com/guides/microsoft-365/#42-configure-external-sharing-restrictions
# =============================================================================

# HTH Guide Excerpt: begin terraform

# NOTE: SharePoint Online sharing settings are managed through the Microsoft 365
# admin APIs, not the azuread provider. Use the SPO PowerShell module or
# Microsoft Graph API for direct configuration:
#
#   Set-SPOTenant -SharingCapability ExistingExternalUserSharingOnly
#   Set-SPOTenant -RequireAcceptingAccountMatchInvitedAccount $true
#   Set-SPOTenant -PreventExternalUsersFromResharing $true
#
# This file creates the Azure AD groups needed for conditional sharing policies.

# Group for users authorized to share externally
resource "azuread_group" "external_sharing_authorized" {
  display_name     = "HTH: External Sharing Authorized"
  description      = "Users permitted to share documents with external parties"
  security_enabled = true
  mail_enabled     = false
}

# Conditional Access: Restrict unmanaged device access to web-only
# Prevents downloading/syncing sensitive data on personal devices
resource "azuread_conditional_access_policy" "restrict_unmanaged_devices" {
  count = var.profile_level >= 2 ? 1 : 0

  display_name = "HTH: Restrict unmanaged device access"
  state        = "enabled"

  conditions {
    users {
      included_users = ["All"]
      excluded_users = [for u in data.azuread_user.break_glass : u.object_id]
    }

    applications {
      # SharePoint Online and OneDrive application IDs
      included_applications = [
        "00000003-0000-0ff1-ce00-000000000000", # SharePoint Online
      ]
    }

    client_app_types = ["browser"]
  }

  session_controls {
    application_enforced_restrictions_enabled = true
  }
}

# L3: Block external sharing entirely except to allowed domains
resource "azuread_group" "allowed_external_domains" {
  count = var.profile_level >= 3 && length(var.allowed_external_domains) > 0 ? 1 : 0

  display_name     = "HTH: Allowed External Domains"
  description      = "Reference group for external domain allow-list (domains: ${join(", ", var.allowed_external_domains)})"
  security_enabled = true
  mail_enabled     = false
}

# HTH Guide Excerpt: end terraform
