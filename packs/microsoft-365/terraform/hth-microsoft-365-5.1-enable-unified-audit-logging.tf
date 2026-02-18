# =============================================================================
# HTH Microsoft 365 Control 5.1: Enable Unified Audit Logging
# Profile Level: L1 (Baseline)
# Source: https://howtoharden.com/guides/microsoft-365/#51-enable-unified-audit-logging
# =============================================================================

# HTH Guide Excerpt: begin terraform

# NOTE: Unified audit logging is managed through Exchange Online PowerShell,
# not the azuread provider. Enable via:
#
#   Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
#   Get-Mailbox -ResultSize Unlimited | Set-Mailbox -AuditEnabled $true
#
# This file creates the Azure AD groups and Conditional Access signals needed
# to support audit logging infrastructure and monitoring.

# Security group for audit log reviewers (SIEM integration service accounts)
resource "azuread_group" "audit_log_reviewers" {
  display_name     = "HTH: Audit Log Reviewers"
  description      = "Security team members and service accounts with audit log access"
  security_enabled = true
  mail_enabled     = false
}

# Group for mailbox auditing scope (users requiring enhanced auditing)
resource "azuread_group" "enhanced_audit_scope" {
  count = var.profile_level >= 2 ? 1 : 0

  display_name     = "HTH: Enhanced Audit Scope"
  description      = "Users with enhanced mailbox auditing (MailItemsAccessed, Send)"
  security_enabled = true
  mail_enabled     = false
}

# L2+: Application registration for SIEM integration
resource "azuread_application" "siem_integration" {
  count = var.profile_level >= 2 ? 1 : 0

  display_name = "HTH: SIEM Audit Log Integration"

  required_resource_access {
    # Microsoft Graph
    resource_app_id = "00000003-0000-0000-c000-000000000000"

    resource_access {
      # AuditLog.Read.All (Application)
      id   = "b0afded3-3588-46d8-8b3d-9842eff778da"
      type = "Role"
    }

    resource_access {
      # Directory.Read.All (Application)
      id   = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"
      type = "Role"
    }
  }

  web {
    redirect_uris = []
  }
}

# Service principal for the SIEM integration app
resource "azuread_service_principal" "siem_integration" {
  count = var.profile_level >= 2 ? 1 : 0

  client_id = azuread_application.siem_integration[0].client_id
}

# HTH Guide Excerpt: end terraform
