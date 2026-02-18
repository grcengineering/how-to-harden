# =============================================================================
# Ping Identity Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: Phishing-Resistant MFA
# -----------------------------------------------------------------------------

output "mfa_device_policy_id" {
  description = "ID of the phishing-resistant MFA device policy"
  value       = pingone_mfa_device_policy.phishing_resistant.id
}

output "fido2_policy_id" {
  description = "ID of the FIDO2 WebAuthn policy"
  value       = pingone_mfa_fido2_policy.webauthn.id
}

output "admin_sign_on_policy_id" {
  description = "ID of the phishing-resistant admin sign-on policy"
  value       = pingone_sign_on_policy.phishing_resistant_admin.id
}


# -----------------------------------------------------------------------------
# Section 1.2: Least-Privilege Admin Roles
# -----------------------------------------------------------------------------

output "identity_admins_group_id" {
  description = "ID of the Identity Administrators group"
  value       = pingone_group.identity_admins.id
}

output "app_admins_group_id" {
  description = "ID of the Application Administrators group"
  value       = pingone_group.app_admins.id
}

output "security_admins_group_id" {
  description = "ID of the Security Administrators group"
  value       = pingone_group.security_admins.id
}

output "auditors_group_id" {
  description = "ID of the Read-Only Auditors group"
  value       = pingone_group.auditors.id
}


# -----------------------------------------------------------------------------
# Section 1.3: IP-Based Access Restrictions (L2+)
# -----------------------------------------------------------------------------

output "ip_restricted_policy_id" {
  description = "ID of the IP-restricted sign-on policy (L2+ only)"
  value       = var.profile_level >= 2 ? pingone_sign_on_policy.ip_restricted[0].id : null
}


# -----------------------------------------------------------------------------
# Section 2.1: SAML Federation Trust
# -----------------------------------------------------------------------------

output "saml_signing_key_id" {
  description = "ID of the SAML signing key"
  value       = pingone_key.saml_signing.id
}

output "hardened_saml_app_id" {
  description = "ID of the hardened SAML SP application"
  value       = pingone_application.hardened_saml_sp.id
}

output "saml_encryption_key_id" {
  description = "ID of the SAML encryption key (L2+ only)"
  value       = var.profile_level >= 2 ? pingone_key.saml_encryption[0].id : null
}


# -----------------------------------------------------------------------------
# Section 2.3: Certificate Lifecycle Management
# -----------------------------------------------------------------------------

output "rotation_signing_key_id" {
  description = "ID of the rotation signing key"
  value       = pingone_key.saml_signing_rotation.id
}


# -----------------------------------------------------------------------------
# Section 3.1: Secure OAuth Settings
# -----------------------------------------------------------------------------

output "hardened_api_resource_id" {
  description = "ID of the hardened API resource"
  value       = pingone_resource.hardened_api.id
}

output "hardened_oidc_app_id" {
  description = "ID of the hardened OIDC application"
  value       = pingone_application.hardened_oidc.id
}


# -----------------------------------------------------------------------------
# Section 3.2: Token Revocation
# -----------------------------------------------------------------------------

output "risk_revocation_policy_id" {
  description = "ID of the risk-based token revocation sign-on policy"
  value       = pingone_sign_on_policy.risk_based_revocation.id
}

output "risk_policy_id" {
  description = "ID of the high-risk revocation risk policy"
  value       = pingone_risk_policy.token_revocation.id
}


# -----------------------------------------------------------------------------
# Section 4.1: DaVinci Orchestration Security (L2+)
# -----------------------------------------------------------------------------

output "davinci_restricted_app_id" {
  description = "ID of the DaVinci restricted application (L2+ only)"
  value       = var.profile_level >= 2 ? pingone_application.davinci_restricted[0].id : null
}

output "davinci_elevated_policy_id" {
  description = "ID of the DaVinci elevated authentication policy (L2+ only)"
  value       = var.profile_level >= 2 ? pingone_sign_on_policy.davinci_elevated[0].id : null
}


# -----------------------------------------------------------------------------
# Section 4.2: Version Control for Flows (L2+)
# -----------------------------------------------------------------------------

output "davinci_export_worker_id" {
  description = "ID of the DaVinci flow export worker application (L2+ only)"
  value       = var.profile_level >= 2 ? pingone_application.davinci_export_worker[0].id : null
}

output "davinci_staging_env_id" {
  description = "ID of the DaVinci staging environment (L3 only)"
  value       = var.profile_level >= 3 ? pingone_environment.davinci_staging[0].id : null
}


# -----------------------------------------------------------------------------
# Section 5.1: Comprehensive Audit Logging
# -----------------------------------------------------------------------------

output "siem_webhook_id" {
  description = "ID of the SIEM integration webhook"
  value       = var.siem_webhook_url != "" ? pingone_webhook.siem_integration[0].id : null
}


# -----------------------------------------------------------------------------
# Section 6.1: SP Connection Hardening
# -----------------------------------------------------------------------------

output "hardened_sp_connection_id" {
  description = "ID of the hardened SP connection"
  value       = pingone_application.hardened_sp_connection.id
}

output "encrypted_sp_connection_id" {
  description = "ID of the encrypted SP connection (L2+ only)"
  value       = var.profile_level >= 2 ? pingone_application.encrypted_sp_connection[0].id : null
}


# -----------------------------------------------------------------------------
# Section 6.2: API Client Management
# -----------------------------------------------------------------------------

output "scim_provisioner_id" {
  description = "ID of the SCIM provisioner application"
  value       = pingone_application.scim_provisioner.id
}

output "admin_api_client_id" {
  description = "ID of the admin API client application"
  value       = pingone_application.admin_api_client.id
}

output "reporting_client_id" {
  description = "ID of the reporting client application"
  value       = pingone_application.reporting_client.id
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
    phishing_resistant_mfa     = true
    least_privilege_roles      = true
    ip_restrictions            = var.profile_level >= 2
    saml_federation_hardened   = true
    saml_encryption            = var.profile_level >= 2
    oauth_hardened             = true
    risk_based_revocation      = true
    oauth_consent_management   = var.profile_level >= 2
    davinci_secured            = var.profile_level >= 2
    davinci_version_control    = var.profile_level >= 2
    davinci_staging_env        = var.profile_level >= 3
    siem_integration           = var.siem_webhook_url != ""
    sp_connections_hardened    = true
    sp_connections_encrypted   = var.profile_level >= 2
    api_clients_managed        = true
  }
}
