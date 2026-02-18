# =============================================================================
# Microsoft 365 Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: Phishing-Resistant MFA
# -----------------------------------------------------------------------------

output "require_mfa_policy_id" {
  description = "ID of the Conditional Access policy requiring MFA for all users"
  value       = azuread_conditional_access_policy.require_mfa.id
}

output "phishing_resistant_strength_id" {
  description = "ID of the phishing-resistant authentication strength policy (L2+ only)"
  value       = var.profile_level >= 2 ? azuread_authentication_strength_policy.phishing_resistant[0].id : null
}

output "phishing_resistant_admin_policy_id" {
  description = "ID of the phishing-resistant MFA policy for admins (L2+ only)"
  value       = var.profile_level >= 2 ? azuread_conditional_access_policy.require_phishing_resistant_mfa[0].id : null
}


# -----------------------------------------------------------------------------
# Section 1.2: Block Legacy Authentication
# -----------------------------------------------------------------------------

output "block_legacy_auth_policy_id" {
  description = "ID of the Conditional Access policy blocking legacy authentication"
  value       = azuread_conditional_access_policy.block_legacy_auth.id
}


# -----------------------------------------------------------------------------
# Section 1.3: Privileged Identity Management (L2+)
# -----------------------------------------------------------------------------

output "pim_eligible_assignments" {
  description = "Number of PIM eligible Global Admin assignments created (L2+ only)"
  value       = var.profile_level >= 2 ? length(var.pim_eligible_admin_upns) : 0
}


# -----------------------------------------------------------------------------
# Section 1.4: Break-Glass Emergency Access
# -----------------------------------------------------------------------------

output "break_glass_account_01_id" {
  description = "Object ID of break-glass emergency access account 1"
  value       = local.create_break_glass ? azuread_user.break_glass_01[0].object_id : null
}

output "break_glass_account_02_id" {
  description = "Object ID of break-glass emergency access account 2"
  value       = local.create_break_glass ? azuread_user.break_glass_02[0].object_id : null
}


# -----------------------------------------------------------------------------
# Section 2.1: Named Locations (L2+)
# -----------------------------------------------------------------------------

output "corporate_network_location_id" {
  description = "ID of the corporate network named location (L2+ only)"
  value       = var.profile_level >= 2 && length(var.trusted_ip_ranges) > 0 ? azuread_named_location.corporate_network[0].id : null
}

output "blocked_countries_location_id" {
  description = "ID of the blocked countries named location (L2+ only)"
  value       = var.profile_level >= 2 && length(var.blocked_country_codes) > 0 ? azuread_named_location.blocked_countries[0].id : null
}

output "block_countries_policy_id" {
  description = "ID of the Conditional Access policy blocking restricted countries (L2+ only)"
  value       = var.profile_level >= 2 && length(var.blocked_country_codes) > 0 ? azuread_conditional_access_policy.block_countries[0].id : null
}


# -----------------------------------------------------------------------------
# Section 3.1: Restrict User Consent
# -----------------------------------------------------------------------------

output "external_sharing_group_id" {
  description = "ID of the group for users authorized to share externally"
  value       = azuread_group.external_sharing_authorized.object_id
}


# -----------------------------------------------------------------------------
# Section 4.1: Sensitivity Labels / DLP (L2+)
# -----------------------------------------------------------------------------

output "sensitivity_label_users_group_id" {
  description = "ID of the sensitivity label users group (L2+ only)"
  value       = var.profile_level >= 2 ? azuread_group.sensitivity_label_users[0].object_id : null
}

output "dlp_policy_scope_group_id" {
  description = "ID of the DLP policy scope group (L2+ only)"
  value       = var.profile_level >= 2 ? azuread_group.dlp_policy_scope[0].object_id : null
}


# -----------------------------------------------------------------------------
# Section 5.1: Unified Audit Logging
# -----------------------------------------------------------------------------

output "audit_log_reviewers_group_id" {
  description = "ID of the audit log reviewers group"
  value       = azuread_group.audit_log_reviewers.object_id
}

output "siem_integration_app_id" {
  description = "Application ID of the SIEM integration app registration (L2+ only)"
  value       = var.profile_level >= 2 ? azuread_application.siem_integration[0].client_id : null
}


# -----------------------------------------------------------------------------
# Section 5.2: Security Alerts / Defender
# -----------------------------------------------------------------------------

output "security_operations_group_id" {
  description = "ID of the security operations group for alert routing"
  value       = azuread_group.security_operations.object_id
}

output "risky_signin_mfa_policy_id" {
  description = "ID of the Conditional Access policy requiring MFA for risky sign-ins"
  value       = azuread_conditional_access_policy.risky_signin_mfa.id
}

output "block_high_risk_signin_policy_id" {
  description = "ID of the Conditional Access policy blocking high-risk sign-ins (L2+ only)"
  value       = var.profile_level >= 2 ? azuread_conditional_access_policy.block_high_risk_signin[0].id : null
}

output "risky_user_remediation_policy_id" {
  description = "ID of the Conditional Access policy for risky user remediation (L2+ only)"
  value       = var.profile_level >= 2 ? azuread_conditional_access_policy.risky_user_remediation[0].id : null
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
    profile_level                = var.profile_level
    l1_controls_applied          = true
    l2_controls_applied          = var.profile_level >= 2
    l3_controls_applied          = var.profile_level >= 3
    mfa_enforced                 = true
    legacy_auth_blocked          = true
    pim_enabled                  = var.profile_level >= 2
    break_glass_accounts         = local.create_break_glass
    named_locations              = var.profile_level >= 2 && length(var.trusted_ip_ranges) > 0
    country_blocking             = var.profile_level >= 2 && length(var.blocked_country_codes) > 0
    user_consent_restricted      = true
    sensitivity_labels_scoped    = var.profile_level >= 2
    dlp_scoped                   = var.profile_level >= 2
    siem_integration             = var.profile_level >= 2
    risky_signin_protection      = true
    high_risk_signin_blocking    = var.profile_level >= 2
    risky_user_remediation       = var.profile_level >= 2
  }
}
