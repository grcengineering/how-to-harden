# =============================================================================
# HTH Microsoft 365 Control 4.1: Enable Sensitivity Labels and Data Loss Prevention
# Profile Level: L2 (Hardened)
# Source: https://howtoharden.com/guides/microsoft-365/#41-enable-sensitivity-labels-and-data-loss-prevention
# =============================================================================

# HTH Guide Excerpt: begin terraform

# NOTE: Microsoft Purview sensitivity labels and DLP policies are not directly
# manageable via the azuread Terraform provider. These must be configured via
# Microsoft Graph API or PowerShell (Security & Compliance module).
#
# This file provisions the prerequisite Azure AD group structure for label
# scoping and DLP policy targeting.

# Group for users who should receive sensitivity labels
resource "azuread_group" "sensitivity_label_users" {
  count = var.profile_level >= 2 ? 1 : 0

  display_name     = "HTH: Sensitivity Label Users"
  description      = "Users scoped for Microsoft Purview sensitivity labels"
  security_enabled = true
  mail_enabled     = false
}

# Group for DLP policy scoping
resource "azuread_group" "dlp_policy_scope" {
  count = var.profile_level >= 2 ? 1 : 0

  display_name     = "HTH: DLP Policy Scope"
  description      = "Users and groups scoped for Data Loss Prevention policies"
  security_enabled = true
  mail_enabled     = false
}

# L3: Dedicated group for auto-labeling policy scope
resource "azuread_group" "auto_labeling_scope" {
  count = var.profile_level >= 3 ? 1 : 0

  display_name     = "HTH: Auto-Labeling Scope"
  description      = "Users scoped for automatic sensitivity label application (E5 required)"
  security_enabled = true
  mail_enabled     = false
}

# HTH Guide Excerpt: end terraform
