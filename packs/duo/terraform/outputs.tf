# =============================================================================
# HTH Duo Security Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 2.1: Global Policy - ISE Policy Set
# -----------------------------------------------------------------------------

output "duo_mfa_enforcement_policy_set_id" {
  description = "ID of the ISE network access policy set enforcing Duo MFA"
  value       = ise_network_access_policy_set.duo_mfa_enforcement.id
}


# -----------------------------------------------------------------------------
# Section 2.3: Phishing-Resistant MFA (L2+)
# -----------------------------------------------------------------------------

output "phishing_resistant_protocols_id" {
  description = "ID of the ISE allowed protocols profile for phishing-resistant auth (L2+ only)"
  value       = var.profile_level >= 2 ? ise_allowed_protocols.duo_phishing_resistant[0].id : null
}


# -----------------------------------------------------------------------------
# Section 3.2: User Enrollment - ISE Identity Group
# -----------------------------------------------------------------------------

output "pending_enrollment_group_id" {
  description = "ID of the ISE identity group for Duo enrollment-pending users"
  value       = ise_user_identity_group.duo_pending_enrollment.id
}


# -----------------------------------------------------------------------------
# Section 4.1: Trusted Endpoints (L2+)
# -----------------------------------------------------------------------------

output "trusted_devices_group_id" {
  description = "ID of the ISE endpoint identity group for Duo-trusted devices (L2+ only)"
  value       = var.profile_level >= 2 && var.trusted_endpoints_enabled ? ise_endpoint_identity_group.duo_trusted_devices[0].id : null
}

output "untrusted_devices_group_id" {
  description = "ID of the ISE endpoint identity group for untrusted devices (L2+ only)"
  value       = var.profile_level >= 2 && var.trusted_endpoints_enabled ? ise_endpoint_identity_group.duo_untrusted_devices[0].id : null
}

output "trusted_access_profile_id" {
  description = "ID of the ISE authorization profile for trusted endpoint access (L2+ only)"
  value       = var.profile_level >= 2 && var.trusted_endpoints_enabled ? ise_authorization_profile.duo_trusted_access[0].id : null
}

output "untrusted_deny_profile_id" {
  description = "ID of the ISE authorization profile denying untrusted endpoints (L2+ only)"
  value       = var.profile_level >= 2 && var.trusted_endpoints_enabled && var.block_untrusted_devices ? ise_authorization_profile.duo_untrusted_deny[0].id : null
}


# -----------------------------------------------------------------------------
# Section 4.2: Device Registration Tracking
# -----------------------------------------------------------------------------

output "registration_date_attribute_id" {
  description = "ID of the ISE endpoint custom attribute for Duo registration date"
  value       = ise_endpoint_custom_attribute.duo_registration_date.id
}

output "registration_user_attribute_id" {
  description = "ID of the ISE endpoint custom attribute for Duo registration user"
  value       = ise_endpoint_custom_attribute.duo_registration_user.id
}


# -----------------------------------------------------------------------------
# Section 5.1: Application-Specific Policies (L2+)
# -----------------------------------------------------------------------------

output "critical_apps_policy_set_id" {
  description = "ID of the ISE policy set for critical Duo-protected applications (L2+ only)"
  value       = var.profile_level >= 2 ? ise_network_access_policy_set.duo_critical_apps[0].id : null
}

output "standard_apps_policy_set_id" {
  description = "ID of the ISE policy set for standard Duo-protected applications (L2+ only)"
  value       = var.profile_level >= 2 ? ise_network_access_policy_set.duo_standard_apps[0].id : null
}

output "critical_app_access_profile_id" {
  description = "ID of the ISE authorization profile for critical application access (L2+ only)"
  value       = var.profile_level >= 2 ? ise_authorization_profile.duo_critical_app_access[0].id : null
}


# -----------------------------------------------------------------------------
# Section 5.2: Windows Logon/RDP
# -----------------------------------------------------------------------------

output "windows_rdp_policy_set_id" {
  description = "ID of the ISE device admin policy set for Windows/RDP"
  value       = ise_device_admin_policy_set.duo_windows_rdp.id
}


# -----------------------------------------------------------------------------
# Section 6.1: Logging - ISE Identity Source Sequence
# -----------------------------------------------------------------------------

output "logging_identity_source_id" {
  description = "ID of the ISE identity source sequence for Duo auth logging"
  value       = ise_identity_source_sequence.duo_logging.id
}


# -----------------------------------------------------------------------------
# Section 6.3: Session Hijacking Protection (L2+)
# -----------------------------------------------------------------------------

output "session_timeout_condition_id" {
  description = "ID of the ISE device admin condition for session timeout (L2+ only)"
  value       = var.profile_level >= 2 ? ise_device_admin_condition.duo_session_timeout[0].id : null
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
    global_policy_enforced     = true
    new_user_policy            = var.global_policy_new_user_action
    bypass_audit               = "enabled"
    phishing_resistant_mfa     = var.profile_level >= 2
    verified_push              = var.profile_level >= 2 ? var.verified_push_enabled : false
    sms_disabled               = var.profile_level >= 2 ? var.disable_sms_passcodes : false
    phone_callback_disabled    = var.profile_level >= 2 ? var.disable_phone_callback : false
    authorized_networks        = var.profile_level >= 2 && length(var.authorized_networks_cidrs) > 0
    inactive_account_audit     = true
    enrollment_security        = true
    trusted_endpoints          = var.profile_level >= 2 ? var.trusted_endpoints_enabled : false
    device_registration_monitor = true
    application_tiered_policies = var.profile_level >= 2
    windows_rdp_hardened       = true
    rdp_fail_mode              = var.rdp_fail_mode
    siem_integration           = var.siem_integration_enabled
    trust_monitor              = var.trust_monitor_enabled
    session_protection         = var.profile_level >= 2
  }
}
