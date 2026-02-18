# =============================================================================
# Jamf Pro Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: Console Access - RBAC Roles
# -----------------------------------------------------------------------------

output "helpdesk_role_id" {
  description = "ID of the HTH Help Desk API role"
  value       = jamfpro_api_role.helpdesk.id
}

output "deployment_role_id" {
  description = "ID of the HTH Deployment API role"
  value       = jamfpro_api_role.deployment.id
}

output "security_role_id" {
  description = "ID of the HTH Security API role"
  value       = jamfpro_api_role.security.id
}

output "helpdesk_account_id" {
  description = "ID of the HTH Help Desk service account"
  value       = jamfpro_account.helpdesk.id
}

output "deployment_account_id" {
  description = "ID of the HTH Deployment service account"
  value       = jamfpro_account.deployment.id
}


# -----------------------------------------------------------------------------
# Section 1.2: API Integration
# -----------------------------------------------------------------------------

output "api_integration_id" {
  description = "ID of the security automation API integration"
  value       = jamfpro_api_integration.security_automation.id
}

output "api_integration_client_id" {
  description = "Client ID of the security automation API integration"
  value       = jamfpro_api_integration.security_automation.client_id
}

output "api_integration_hardened_id" {
  description = "ID of the hardened API integration (L2+ only)"
  value       = var.profile_level >= 2 ? jamfpro_api_integration.security_automation_hardened[0].id : null
}


# -----------------------------------------------------------------------------
# Section 2.1: Password Policy Profile
# -----------------------------------------------------------------------------

output "password_policy_profile_id" {
  description = "ID of the password policy configuration profile"
  value       = jamfpro_macos_configuration_profile_plist.password_policy.id
}


# -----------------------------------------------------------------------------
# Section 2.2: FileVault Encryption
# -----------------------------------------------------------------------------

output "filevault_config_id" {
  description = "ID of the FileVault disk encryption configuration"
  value       = jamfpro_disk_encryption_configuration.filevault.id
}

output "filevault_profile_id" {
  description = "ID of the FileVault enforcement configuration profile"
  value       = jamfpro_macos_configuration_profile_plist.filevault.id
}

output "filevault_not_enabled_group_id" {
  description = "Smart group ID for computers without FileVault"
  value       = jamfpro_smart_computer_group.filevault_not_enabled.id
}


# -----------------------------------------------------------------------------
# Section 2.3: Firewall
# -----------------------------------------------------------------------------

output "firewall_profile_id" {
  description = "ID of the firewall configuration profile"
  value       = jamfpro_macos_configuration_profile_plist.firewall.id
}

output "firewall_disabled_group_id" {
  description = "Smart group ID for computers with firewall disabled"
  value       = jamfpro_smart_computer_group.firewall_disabled.id
}


# -----------------------------------------------------------------------------
# Section 2.4: Software Updates
# -----------------------------------------------------------------------------

output "software_update_profile_id" {
  description = "ID of the software update configuration profile"
  value       = jamfpro_macos_configuration_profile_plist.software_updates.id
}

output "software_update_deferral_profile_id" {
  description = "ID of the software update deferral profile (L2+ only)"
  value       = var.profile_level >= 2 ? jamfpro_macos_configuration_profile_plist.software_update_deferral[0].id : null
}

output "os_not_current_group_id" {
  description = "Smart group ID for computers with outdated OS"
  value       = jamfpro_smart_computer_group.os_not_current.id
}


# -----------------------------------------------------------------------------
# Section 3.1: CIS Benchmark Profiles (L2+)
# -----------------------------------------------------------------------------

output "cis_gatekeeper_profile_id" {
  description = "ID of the CIS Gatekeeper enforcement profile (L2+ only)"
  value       = var.profile_level >= 2 ? jamfpro_macos_configuration_profile_plist.cis_gatekeeper[0].id : null
}

output "cis_screensaver_profile_id" {
  description = "ID of the CIS screen saver idle time profile (L2+ only)"
  value       = var.profile_level >= 2 ? jamfpro_macos_configuration_profile_plist.cis_screensaver[0].id : null
}

output "cis_remote_login_profile_id" {
  description = "ID of the CIS disable remote login profile (L2+ only)"
  value       = var.profile_level >= 2 && var.cis_disable_remote_login ? jamfpro_macos_configuration_profile_plist.cis_disable_remote_login[0].id : null
}


# -----------------------------------------------------------------------------
# Section 3.2: CIS Compliance Monitoring (L2+)
# -----------------------------------------------------------------------------

output "cis_compliance_ea_id" {
  description = "ID of the CIS compliance extension attribute (L2+ only)"
  value       = var.profile_level >= 2 ? jamfpro_computer_extension_attribute.cis_compliance[0].id : null
}

output "cis_non_compliant_group_id" {
  description = "Smart group ID for CIS non-compliant computers (L2+ only)"
  value       = var.profile_level >= 2 ? jamfpro_smart_computer_group.cis_non_compliant[0].id : null
}


# -----------------------------------------------------------------------------
# Section 4.1: Audit Logging
# -----------------------------------------------------------------------------

output "webhook_admin_login_id" {
  description = "ID of the admin login webhook (if SIEM URL configured)"
  value       = var.siem_webhook_url != "" ? jamfpro_webhook.admin_login[0].id : null
}

output "webhook_policy_change_id" {
  description = "ID of the policy change webhook (if SIEM URL configured)"
  value       = var.siem_webhook_url != "" ? jamfpro_webhook.policy_change[0].id : null
}

output "webhook_computer_enrollment_id" {
  description = "ID of the computer enrollment webhook (if SIEM URL configured)"
  value       = var.siem_webhook_url != "" ? jamfpro_webhook.computer_enrollment[0].id : null
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
    profile_level           = var.profile_level
    l1_controls_applied     = true
    l2_controls_applied     = var.profile_level >= 2
    l3_controls_applied     = var.profile_level >= 3
    rbac_roles_created      = 3
    api_integration         = "configured"
    password_policy         = "enforced"
    filevault_encryption    = "enforced"
    firewall                = "enabled"
    stealth_mode            = var.firewall_stealth_mode
    block_all_incoming      = var.firewall_block_all_incoming || var.profile_level >= 3
    software_updates        = "automatic"
    update_deferral         = var.profile_level >= 2 ? "${var.software_update_deferral_days} days" : "none"
    cis_benchmarks          = var.profile_level >= 2
    cis_compliance_monitor  = var.profile_level >= 2
    siem_webhooks           = var.siem_webhook_url != "" ? "configured" : "not configured"
    siem_webhook_count      = var.siem_webhook_url != "" ? (var.profile_level >= 2 ? 6 : 3) : 0
  }
}
