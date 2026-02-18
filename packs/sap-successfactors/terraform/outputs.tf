# =============================================================================
# SAP SuccessFactors Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: SSO with MFA
# -----------------------------------------------------------------------------

output "corporate_idp_id" {
  description = "ID of the corporate IdP trust configuration"
  value       = btp_subaccount_trust_configuration.corporate_idp.id
}

output "identity_authentication_subscription_id" {
  description = "ID of the IAS subscription (L2+ only)"
  value       = var.profile_level >= 2 ? btp_subaccount_subscription.identity_authentication[0].id : null
}

output "x509_auth_instance_id" {
  description = "ID of the X.509 auth service instance (L3 only)"
  value       = var.profile_level >= 3 ? btp_subaccount_service_instance.x509_auth[0].id : null
}


# -----------------------------------------------------------------------------
# Section 1.2: Role-Based Permissions (RBP)
# -----------------------------------------------------------------------------

output "system_admin_role_collection" {
  description = "Name of the system admin role collection"
  value       = btp_subaccount_role_collection.sf_system_admin.name
}

output "hr_admin_role_collection" {
  description = "Name of the HR admin role collection"
  value       = btp_subaccount_role_collection.sf_hr_admin.name
}

output "auditor_role_collection" {
  description = "Name of the auditor role collection (L2+ only)"
  value       = var.profile_level >= 2 ? btp_subaccount_role_collection.sf_auditor[0].name : null
}


# -----------------------------------------------------------------------------
# Section 2.1: OData API Security
# -----------------------------------------------------------------------------

output "odata_oauth_instance_id" {
  description = "ID of the XSUAA service instance for OData API access"
  value       = btp_subaccount_service_instance.sf_odata_oauth.id
}

output "odata_binding_id" {
  description = "ID of the OData API service binding"
  value       = btp_subaccount_service_binding.sf_odata_binding.id
}

output "api_destination_id" {
  description = "ID of the IP-restricted API destination (L2+ only)"
  value       = var.profile_level >= 2 && length(var.api_allowed_ip_cidrs) > 0 ? btp_subaccount_service_instance.sf_destination[0].id : null
}

output "mtls_instance_id" {
  description = "ID of the mTLS service instance (L3 only)"
  value       = var.profile_level >= 3 ? btp_subaccount_service_instance.sf_odata_mtls[0].id : null
}


# -----------------------------------------------------------------------------
# Section 2.2: OAuth Token Management
# -----------------------------------------------------------------------------

output "token_governance_instance_id" {
  description = "ID of the token governance service instance"
  value       = btp_subaccount_service_instance.sf_token_governance.id
}


# -----------------------------------------------------------------------------
# Section 3.1: Data Privacy
# -----------------------------------------------------------------------------

output "data_privacy_instance_id" {
  description = "ID of the data privacy integration service instance"
  value       = btp_subaccount_service_instance.data_privacy.id
}

output "personal_data_manager_id" {
  description = "ID of the personal data manager instance (L2+ only)"
  value       = var.profile_level >= 2 ? btp_subaccount_service_instance.personal_data_manager[0].id : null
}

output "data_privacy_officer_role" {
  description = "Name of the data privacy officer role collection"
  value       = btp_subaccount_role_collection.data_privacy_officer.name
}


# -----------------------------------------------------------------------------
# Section 4.1: Audit Logging
# -----------------------------------------------------------------------------

output "audit_log_instance_id" {
  description = "ID of the audit log service instance"
  value       = btp_subaccount_service_instance.audit_log.id
}

output "audit_log_binding_id" {
  description = "ID of the audit log service binding"
  value       = btp_subaccount_service_binding.audit_log_binding.id
}

output "audit_viewer_role" {
  description = "Name of the audit viewer role collection"
  value       = btp_subaccount_role_collection.audit_viewer.name
}

output "alert_notification_id" {
  description = "ID of the alert notification service instance (L3 only)"
  value       = var.profile_level >= 3 ? btp_subaccount_service_instance.alert_notification[0].id : null
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
    profile_level          = var.profile_level
    l1_controls_applied    = true
    l2_controls_applied    = var.profile_level >= 2
    l3_controls_applied    = var.profile_level >= 3
    sso_enforced           = var.enforce_sso
    rbp_configured         = true
    auditor_role           = var.profile_level >= 2
    odata_oauth            = "configured"
    api_ip_restriction     = var.profile_level >= 2 && length(var.api_allowed_ip_cidrs) > 0
    mtls_enforced          = var.profile_level >= 3
    token_governance       = "configured"
    data_privacy           = "configured"
    field_masking          = var.profile_level >= 2 ? "enabled" : "default"
    data_residency         = var.profile_level >= 3
    audit_logging          = "configured"
    audit_retention_days   = var.audit_retention_days
    siem_integration       = var.profile_level >= 2 && var.siem_webhook_url != ""
    alert_notification     = var.profile_level >= 3
  }
}
