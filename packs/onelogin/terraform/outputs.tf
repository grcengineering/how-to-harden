# =============================================================================
# OneLogin Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: Password Policy
# -----------------------------------------------------------------------------

output "password_policy_id" {
  description = "ID of the baseline password policy"
  value       = onelogin_user_security_policy.password_policy.id
}

output "password_policy_hardened_id" {
  description = "ID of the hardened password policy (L2+ only)"
  value       = var.profile_level >= 2 ? onelogin_user_security_policy.password_policy_hardened[0].id : null
}


# -----------------------------------------------------------------------------
# Section 1.2: Session Controls
# -----------------------------------------------------------------------------

output "session_controls_id" {
  description = "ID of the session controls policy"
  value       = onelogin_user_security_policy.session_controls.id
}

output "session_controls_hardened_id" {
  description = "ID of the hardened session controls policy (L2+ only)"
  value       = var.profile_level >= 2 ? onelogin_user_security_policy.session_controls_hardened[0].id : null
}


# -----------------------------------------------------------------------------
# Section 1.3: Self-Service Password Reset
# -----------------------------------------------------------------------------

output "self_service_reset_id" {
  description = "ID of the self-service password reset policy"
  value       = onelogin_user_security_policy.self_service_reset.id
}


# -----------------------------------------------------------------------------
# Section 2.1: MFA Enforcement
# -----------------------------------------------------------------------------

output "mfa_required_policy_id" {
  description = "ID of the MFA enforcement policy"
  value       = onelogin_user_security_policy.mfa_required.id
}

output "onelogin_protect_factor_id" {
  description = "ID of the OneLogin Protect auth factor"
  value       = onelogin_auth_factor.onelogin_protect.id
}

output "webauthn_factor_id" {
  description = "ID of the WebAuthn auth factor"
  value       = onelogin_auth_factor.webauthn.id
}


# -----------------------------------------------------------------------------
# Section 2.2: SmartFactor Authentication (L2+)
# -----------------------------------------------------------------------------

output "smartfactor_policy_id" {
  description = "ID of the SmartFactor adaptive MFA policy (L2+ only)"
  value       = var.profile_level >= 2 ? onelogin_user_security_policy.smartfactor[0].id : null
}


# -----------------------------------------------------------------------------
# Section 2.3: Admin Phishing-Resistant MFA (L2+)
# -----------------------------------------------------------------------------

output "admin_webauthn_policy_id" {
  description = "ID of the admin WebAuthn-only policy (L2+ only)"
  value       = var.profile_level >= 2 ? onelogin_user_security_policy.admin_webauthn[0].id : null
}


# -----------------------------------------------------------------------------
# Section 3.1: Delegated Administration
# -----------------------------------------------------------------------------

output "tier1_helpdesk_role_id" {
  description = "ID of the Tier 1 Help Desk custom role"
  value       = var.create_custom_roles ? onelogin_role.tier1_helpdesk[0].id : null
}

output "app_admin_role_id" {
  description = "ID of the Application Administrator custom role"
  value       = var.create_custom_roles ? onelogin_role.app_admin[0].id : null
}

output "security_auditor_role_id" {
  description = "ID of the Security Auditor custom role"
  value       = var.create_custom_roles ? onelogin_role.security_auditor[0].id : null
}


# -----------------------------------------------------------------------------
# Section 3.2: IP Address Allowlisting (L2+)
# -----------------------------------------------------------------------------

output "ip_allowlist_policy_id" {
  description = "ID of the IP allowlist policy (L2+ only)"
  value       = var.profile_level >= 2 && var.allowed_ip_addresses != "" ? onelogin_user_security_policy.ip_allowlist[0].id : null
}


# -----------------------------------------------------------------------------
# Section 3.3: Privileged Account Protection
# -----------------------------------------------------------------------------

output "admin_protection_policy_id" {
  description = "ID of the admin account protection policy"
  value       = onelogin_user_security_policy.admin_protection.id
}


# -----------------------------------------------------------------------------
# Section 4.2: Brute Force Protection
# -----------------------------------------------------------------------------

output "brute_force_policy_id" {
  description = "ID of the brute force protection policy"
  value       = onelogin_user_security_policy.brute_force_protection.id
}


# -----------------------------------------------------------------------------
# Section 4.3: Device Trust (L2+)
# -----------------------------------------------------------------------------

output "device_trust_policy_id" {
  description = "ID of the device trust policy (L2+ only)"
  value       = var.profile_level >= 2 ? onelogin_user_security_policy.device_trust[0].id : null
}


# -----------------------------------------------------------------------------
# Section 5.1: Audit Logging
# -----------------------------------------------------------------------------

output "siem_webhook_id" {
  description = "ID of the SIEM log export webhook"
  value       = var.siem_webhook_url != "" ? onelogin_event_webhook.siem_export[0].id : null
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
    password_policy            = "configured"
    session_controls           = "configured"
    self_service_reset         = "configured"
    mfa_enforcement            = "enabled"
    smartfactor_authentication = var.profile_level >= 2
    admin_webauthn_only        = var.profile_level >= 2
    delegated_admin_roles      = var.create_custom_roles
    ip_allowlisting            = var.profile_level >= 2 && var.allowed_ip_addresses != ""
    admin_protection           = "configured"
    brute_force_protection     = "configured"
    device_trust               = var.profile_level >= 2
    siem_integration           = var.siem_webhook_url != ""
  }
}
