# =============================================================================
# HTH Microsoft Entra ID Control 4.2: Review and Restrict Application Permissions
# Profile Level: L2 (Hardened)
# Frameworks: CIS 2.6, NIST AC-6
# Source: https://howtoharden.com/guides/microsoft-entra-id/#42-review-and-restrict-application-permissions
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Data source to enumerate all service principals (enterprise applications)
# for permission auditing. Use this to identify apps with dangerous permissions
# such as Mail.ReadWrite, Directory.ReadWrite.All, full_access_as_app.
#
# NOTE: Terraform is not the ideal tool for ongoing permission auditing.
# This control provides data sources for initial discovery; recurring
# audits should use PowerShell scripts or SSPM tooling.

# Retrieve all service principals for audit
data "azuread_service_principals" "all_apps" {
  count = var.profile_level >= 2 ? 1 : 0

  return_all = true
}

# Identify high-risk Microsoft Graph permissions for audit output
locals {
  high_risk_permissions = var.profile_level >= 2 ? [
    "Mail.ReadWrite",
    "Mail.ReadWrite.All",
    "Files.ReadWrite.All",
    "Directory.ReadWrite.All",
    "Application.ReadWrite.All",
    "RoleManagement.ReadWrite.Directory",
    "full_access_as_app",
  ] : []

  app_permission_audit = var.profile_level >= 2 ? {
    status                = "AUDIT_DATA_AVAILABLE"
    total_service_principals = length(try(data.azuread_service_principals.all_apps[0].service_principals, []))
    high_risk_permissions = local.high_risk_permissions
    instructions          = "Review each app's API permissions in Entra admin center: Applications > App registrations > [App] > API permissions"
    remediation           = "Remove unnecessary permissions or delete unused applications"
  } : null
}
# HTH Guide Excerpt: end terraform
