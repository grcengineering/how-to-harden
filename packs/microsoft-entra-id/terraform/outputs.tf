# =============================================================================
# Microsoft Entra ID Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: Phishing-Resistant MFA
# -----------------------------------------------------------------------------

output "auth_methods_policy_id" {
  description = "ID of the authentication methods policy"
  value       = azuread_authentication_methods_policy.main.id
}

output "phishing_resistant_strength_id" {
  description = "ID of the phishing-resistant authentication strength policy"
  value       = azuread_authentication_strength_policy.phishing_resistant.id
}


# -----------------------------------------------------------------------------
# Section 1.2: Emergency Access (Break-Glass) Accounts
# -----------------------------------------------------------------------------

output "emergency_account_ids" {
  description = "Object IDs of the emergency access accounts"
  value       = azuread_user.emergency_admin[*].object_id
}

output "emergency_account_upns" {
  description = "User principal names of the emergency access accounts"
  value       = azuread_user.emergency_admin[*].user_principal_name
}

output "emergency_access_group_id" {
  description = "Object ID of the emergency access accounts group (for CA exclusions)"
  value       = azuread_group.emergency_access.object_id
}

output "emergency_initial_passwords" {
  description = "Initial passwords for emergency accounts (store securely and rotate)"
  value       = random_password.emergency[*].result
  sensitive   = true
}


# -----------------------------------------------------------------------------
# Section 2.1: Block Legacy Authentication
# -----------------------------------------------------------------------------

output "block_legacy_auth_policy_id" {
  description = "ID of the Conditional Access policy blocking legacy authentication"
  value       = azuread_conditional_access_policy.block_legacy_auth.id
}


# -----------------------------------------------------------------------------
# Section 2.2: Require MFA for All Users
# -----------------------------------------------------------------------------

output "require_mfa_policy_id" {
  description = "ID of the Conditional Access policy requiring MFA for all users"
  value       = azuread_conditional_access_policy.require_mfa_all_users.id
}


# -----------------------------------------------------------------------------
# Section 2.3: Require Compliant Devices for Admins (L2+)
# -----------------------------------------------------------------------------

output "compliant_device_policy_id" {
  description = "ID of the Conditional Access policy requiring compliant devices for admins (L2+ only)"
  value       = var.profile_level >= 2 ? azuread_conditional_access_policy.require_compliant_device_admins[0].id : null
}


# -----------------------------------------------------------------------------
# Section 2.4: Block High-Risk Sign-Ins (L2+)
# -----------------------------------------------------------------------------

output "block_high_risk_policy_id" {
  description = "ID of the Conditional Access policy blocking high-risk sign-ins (L2+ only)"
  value       = var.profile_level >= 2 ? azuread_conditional_access_policy.block_high_risk_signins[0].id : null
}

output "medium_risk_mfa_policy_id" {
  description = "ID of the Conditional Access policy requiring MFA for medium-risk sign-ins (L2+ only)"
  value       = var.profile_level >= 2 ? azuread_conditional_access_policy.remediate_medium_risk_signins[0].id : null
}


# -----------------------------------------------------------------------------
# Section 3.1: Just-In-Time Access (L2+)
# -----------------------------------------------------------------------------

output "pim_eligible_assignment_count" {
  description = "Number of PIM eligible assignments created (L2+ only)"
  value       = var.profile_level >= 2 ? length(var.pim_eligible_user_ids) : 0
}


# -----------------------------------------------------------------------------
# Section 3.2: Access Reviews (L2+)
# -----------------------------------------------------------------------------

output "access_review_config" {
  description = "Access review configuration status (L2+ only, requires manual setup)"
  value       = local.access_review_config
}


# -----------------------------------------------------------------------------
# Section 4.1: Restrict User Consent to Applications
# -----------------------------------------------------------------------------

output "authorization_policy_id" {
  description = "ID of the authorization policy with user consent disabled"
  value       = azuread_authorization_policy.consent_policy.id
}


# -----------------------------------------------------------------------------
# Section 4.2: Application Permission Audit (L2+)
# -----------------------------------------------------------------------------

output "app_permission_audit" {
  description = "Application permission audit summary (L2+ only)"
  value       = local.app_permission_audit
}


# -----------------------------------------------------------------------------
# Section 5.1: Sign-In and Audit Logging
# -----------------------------------------------------------------------------

output "logging_config" {
  description = "Logging configuration status and recommendations"
  value       = local.logging_config
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
    profile_level             = var.profile_level
    l1_controls_applied       = true
    l2_controls_applied       = var.profile_level >= 2
    l3_controls_applied       = var.profile_level >= 3
    phishing_resistant_mfa    = "configured"
    emergency_accounts        = var.emergency_account_count
    legacy_auth_blocked       = var.legacy_auth_policy_state
    mfa_required_all_users    = var.mfa_policy_state
    compliant_devices_admins  = var.profile_level >= 2
    high_risk_signins_blocked = var.profile_level >= 2
    pim_eligible_assignments  = var.profile_level >= 2 ? length(var.pim_eligible_user_ids) : 0
    access_reviews            = var.profile_level >= 2 ? var.access_review_frequency : "not_configured"
    user_consent_disabled     = true
    app_permission_audit      = var.profile_level >= 2
    logging                   = var.log_analytics_workspace_id != "" ? "configured" : "manual_required"
  }
}
