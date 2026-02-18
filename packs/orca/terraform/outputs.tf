# =============================================================================
# Orca Security Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: SAML SSO
# -----------------------------------------------------------------------------

output "sso_group_id" {
  description = "ID of the SSO user group"
  value       = orcasecurity_group.sso_users.id
}


# -----------------------------------------------------------------------------
# Section 1.2: MFA Enforcement
# -----------------------------------------------------------------------------

output "mfa_alert_id" {
  description = "ID of the MFA enforcement monitoring alert"
  value       = orcasecurity_custom_sonar_alert.mfa_not_enforced.id
}


# -----------------------------------------------------------------------------
# Section 2.1: Role-Based Access Control
# -----------------------------------------------------------------------------

output "security_analyst_role_id" {
  description = "ID of the Security Analyst (read-only) custom role"
  value       = orcasecurity_custom_role.security_analyst.id
}

output "viewer_role_id" {
  description = "ID of the Viewer custom role"
  value       = orcasecurity_custom_role.viewer.id
}

output "excessive_permissions_alert_id" {
  description = "ID of the excessive permissions monitoring alert"
  value       = orcasecurity_custom_sonar_alert.excessive_permissions.id
}


# -----------------------------------------------------------------------------
# Section 2.2: Account Scope (L2+)
# -----------------------------------------------------------------------------

output "scoped_business_unit_id" {
  description = "ID of the scoped business unit (L2+ only)"
  value       = var.profile_level >= 2 ? orcasecurity_business_unit.scoped_environment[0].id : null
}

output "restricted_business_unit_id" {
  description = "ID of the restricted production business unit (L3 only)"
  value       = var.profile_level >= 3 ? orcasecurity_business_unit.restricted_production[0].id : null
}


# -----------------------------------------------------------------------------
# Section 2.3: Limit Admin Access
# -----------------------------------------------------------------------------

output "admin_group_id" {
  description = "ID of the platform admin group"
  value       = orcasecurity_group.platform_admins.id
}

output "excessive_admins_alert_id" {
  description = "ID of the excessive admins monitoring alert"
  value       = orcasecurity_custom_sonar_alert.excessive_admins.id
}


# -----------------------------------------------------------------------------
# Section 3.1: Cloud Account Security
# -----------------------------------------------------------------------------

output "trusted_cloud_account_ids" {
  description = "Map of cloud provider IDs to Orca trusted account IDs"
  value       = { for k, v in orcasecurity_trusted_cloud_account.trusted : k => v.id }
}

output "overprivileged_integration_alert_id" {
  description = "ID of the overprivileged integration monitoring alert"
  value       = orcasecurity_custom_sonar_alert.overprivileged_integration.id
}

output "cloud_accounts_discovery_view_id" {
  description = "ID of the cloud accounts inventory discovery view"
  value       = orcasecurity_discovery_view.cloud_accounts_inventory.id
}


# -----------------------------------------------------------------------------
# Section 3.2: API Security (L2+)
# -----------------------------------------------------------------------------

output "stale_api_keys_alert_id" {
  description = "ID of the stale API keys monitoring alert (L2+ only)"
  value       = var.profile_level >= 2 ? orcasecurity_custom_sonar_alert.stale_api_keys[0].id : null
}

output "api_key_automation_id" {
  description = "ID of the API key alert automation (L2+ only, if enabled)"
  value       = var.profile_level >= 2 && var.enable_api_automation && length(var.api_alert_emails) > 0 ? orcasecurity_automation.api_key_alert[0].id : null
}

output "api_key_discovery_view_id" {
  description = "ID of the API key inventory discovery view (L3 only)"
  value       = var.profile_level >= 3 ? orcasecurity_discovery_view.api_key_inventory[0].id : null
}


# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

output "profile_level_applied" {
  description = "The hardening profile level that was applied"
  value       = var.profile_level
}

output "hardening_summary" {
  description = "Summary of hardening controls applied at the selected profile level"
  value = {
    profile_level              = var.profile_level
    l1_controls_applied        = true
    l2_controls_applied        = var.profile_level >= 2
    l3_controls_applied        = var.profile_level >= 3
    sso_group                  = "configured"
    mfa_monitoring             = "enabled"
    rbac_custom_roles          = "configured"
    account_scoping            = var.profile_level >= 2 ? "configured" : "not_applied"
    admin_access_limited       = "configured"
    cloud_account_security     = "configured"
    api_security_monitoring    = var.profile_level >= 2 ? "enabled" : "not_applied"
    api_key_inventory          = var.profile_level >= 3 ? "enabled" : "not_applied"
    trusted_accounts_count     = length(var.trusted_cloud_accounts)
  }
}
