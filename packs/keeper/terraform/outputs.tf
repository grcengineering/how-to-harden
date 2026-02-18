# =============================================================================
# Keeper Security Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: Protect Administrator Accounts
# -----------------------------------------------------------------------------

output "break_glass_record_id" {
  description = "ID of the break-glass admin credential record in Keeper vault"
  value       = var.break_glass_account_email != "" ? secretsmanager_login.break_glass_admin[0].id : null
}

output "admin_redundancy_status" {
  description = "Admin account redundancy validation status"
  value = {
    admin_count          = length(var.admin_usernames)
    minimum_met          = length(var.admin_usernames) >= 2
    break_glass_enrolled = var.break_glass_account_email != ""
  }
}


# -----------------------------------------------------------------------------
# Section 1.2: IP Address Allowlisting for Admins (L2+)
# -----------------------------------------------------------------------------

output "admin_ip_allowlist_configured" {
  description = "Whether admin IP allowlisting is configured (L2+ only)"
  value       = var.profile_level >= 2 && length(var.admin_allowed_ips) > 0
}

output "admin_ip_allowlist_record_id" {
  description = "ID of the IP allowlist configuration record (L2+ only)"
  value       = var.profile_level >= 2 && length(var.admin_allowed_ips) > 0 ? secretsmanager_login.ip_allowlist_record[0].id : null
}


# -----------------------------------------------------------------------------
# Section 1.3: Administrative Event Alerts
# -----------------------------------------------------------------------------

output "siem_integration_configured" {
  description = "Whether SIEM integration is configured for event alerts"
  value       = var.siem_endpoint != ""
}

output "alert_config_record_id" {
  description = "ID of the alert configuration record"
  value       = var.siem_endpoint != "" ? secretsmanager_login.alert_config_record[0].id : null
}


# -----------------------------------------------------------------------------
# Section 2.1: Master Password Requirements
# -----------------------------------------------------------------------------

output "password_policy_record_id" {
  description = "ID of the password policy configuration record"
  value       = secretsmanager_login.password_policy_record.id
}

output "password_policy_settings" {
  description = "Current master password policy settings"
  value = {
    min_length      = var.master_password_min_length
    require_upper   = var.master_password_require_upper
    require_lower   = var.master_password_require_lower
    require_digits  = var.master_password_require_digits
    require_special = var.master_password_require_special
  }
}


# -----------------------------------------------------------------------------
# Section 2.2: Two-Factor Authentication
# -----------------------------------------------------------------------------

output "tfa_policy_record_id" {
  description = "ID of the 2FA policy configuration record"
  value       = secretsmanager_login.tfa_policy_record.id
}

output "tfa_policy_settings" {
  description = "Current 2FA enforcement settings"
  value = {
    required        = var.tfa_required
    allowed_methods = var.tfa_allowed_methods
    sms_disabled    = var.tfa_disable_sms
    dual_2fa        = var.profile_level >= 3
  }
}


# -----------------------------------------------------------------------------
# Section 2.3: Sharing and Export Restrictions
# -----------------------------------------------------------------------------

output "sharing_policy_record_id" {
  description = "ID of the sharing policy configuration record"
  value       = secretsmanager_login.sharing_policy_record.id
}


# -----------------------------------------------------------------------------
# Section 2.4: Browser Extension Restrictions (L2+)
# -----------------------------------------------------------------------------

output "extension_policy_configured" {
  description = "Whether browser extension restrictions are configured (L2+ only)"
  value       = var.profile_level >= 2
}

output "extension_policy_record_id" {
  description = "ID of the browser extension policy record (L2+ only)"
  value       = var.profile_level >= 2 ? secretsmanager_login.extension_policy_record[0].id : null
}


# -----------------------------------------------------------------------------
# Section 4.1: SAML SSO (L2+)
# -----------------------------------------------------------------------------

output "sso_configured" {
  description = "Whether SAML SSO is configured (L2+ only)"
  value       = var.profile_level >= 2 && var.sso_entity_id != ""
}

output "sso_config_record_id" {
  description = "ID of the SSO configuration record (L2+ only)"
  value       = var.profile_level >= 2 && var.sso_entity_id != "" ? secretsmanager_login.sso_config_record[0].id : null
}


# -----------------------------------------------------------------------------
# Section 4.2: Just-in-Time Provisioning (L2+)
# -----------------------------------------------------------------------------

output "scim_configured" {
  description = "Whether SCIM provisioning is configured (L2+ only)"
  value       = var.profile_level >= 2 && var.scim_endpoint != ""
}

output "scim_config_record_id" {
  description = "ID of the SCIM configuration record (L2+ only)"
  value       = var.profile_level >= 2 && var.scim_endpoint != "" ? secretsmanager_login.scim_config_record[0].id : null
}


# -----------------------------------------------------------------------------
# Section 5.3: BreachWatch
# -----------------------------------------------------------------------------

output "breachwatch_record_id" {
  description = "ID of the BreachWatch configuration record"
  value       = var.breachwatch_enabled ? secretsmanager_login.breachwatch_config_record[0].id : null
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
    admin_redundancy           = length(var.admin_usernames) >= 2
    break_glass_account        = var.break_glass_account_email != ""
    ip_allowlisting            = var.profile_level >= 2 && length(var.admin_allowed_ips) > 0
    siem_integration           = var.siem_endpoint != ""
    master_password_min_length = var.master_password_min_length
    tfa_required               = var.tfa_required
    tfa_sms_disabled           = var.tfa_disable_sms
    sharing_restricted_to_org  = var.profile_level >= 2 || var.restrict_sharing_to_org
    export_disabled            = var.profile_level >= 2 || var.disable_export
    browser_extensions_locked  = var.profile_level >= 2
    sso_configured             = var.profile_level >= 2 && var.sso_entity_id != ""
    scim_provisioning          = var.profile_level >= 2 && var.scim_endpoint != ""
    breachwatch                = var.breachwatch_enabled
  }
}
