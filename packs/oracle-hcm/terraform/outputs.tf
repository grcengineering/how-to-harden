# =============================================================================
# Oracle HCM Cloud Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: SSO with MFA Enforcement
# -----------------------------------------------------------------------------

output "mfa_enforcement_id" {
  description = "ID of the MFA authentication factor settings"
  value       = oci_identity_domains_authentication_factor_setting.mfa_enforcement.id
}

output "hcm_sso_mfa_policy_id" {
  description = "ID of the SSO MFA sign-on policy"
  value       = oci_identity_domains_policy.hcm_sso_mfa_policy.id
}

output "fido2_only_policy_id" {
  description = "ID of the FIDO2-only sign-on policy (L3 only)"
  value       = var.profile_level >= 3 ? oci_identity_domains_policy.fido2_only_policy[0].id : null
}


# -----------------------------------------------------------------------------
# Section 1.2: Security Roles
# -----------------------------------------------------------------------------

output "it_security_managers_group_id" {
  description = "ID of the IT Security Managers IDCS group"
  value       = oci_identity_domains_group.it_security_managers.id
}

output "hcm_admins_group_id" {
  description = "ID of the HCM Application Administrators IDCS group"
  value       = oci_identity_domains_group.hcm_admins.id
}

output "hr_analysts_group_id" {
  description = "ID of the HR Analysts IDCS group"
  value       = oci_identity_domains_group.hr_analysts.id
}

output "hcm_service_instances_dynamic_group_id" {
  description = "ID of the HCM Service Instances dynamic resource group"
  value       = oci_identity_domains_dynamic_resource_group.hcm_service_instances.id
}


# -----------------------------------------------------------------------------
# Section 1.3: Security Profiles
# -----------------------------------------------------------------------------

output "hcm_security_profile_policy_id" {
  description = "ID of the HCM security profile IAM policy"
  value       = oci_identity_policy.hcm_security_profile_policy.id
}

output "hcm_password_policy_id" {
  description = "ID of the hardened password policy"
  value       = oci_identity_domains_password_policy.hcm_password_policy.id
}


# -----------------------------------------------------------------------------
# Section 2.1: REST API Security
# -----------------------------------------------------------------------------

output "hcm_api_client_id" {
  description = "ID of the HCM REST API OAuth client application"
  value       = oci_identity_domains_app.hcm_api_client.id
}

output "api_signon_policy_id" {
  description = "ID of the API sign-on policy"
  value       = oci_identity_domains_policy.api_signon_policy.id
}

output "api_network_perimeter_id" {
  description = "ID of the API network perimeter (L2+ only)"
  value       = var.profile_level >= 2 ? oci_identity_domains_network_perimeter.api_network_perimeter[0].id : null
}

output "api_service_account_id" {
  description = "ID of the dedicated API service account (L3 only)"
  value       = var.profile_level >= 3 ? oci_identity_domains_user.api_service_account[0].id : null
}


# -----------------------------------------------------------------------------
# Section 2.2: HDL Security (L2+)
# -----------------------------------------------------------------------------

output "hdl_authorized_users_group_id" {
  description = "ID of the HDL authorized users group (L2+ only)"
  value       = var.profile_level >= 2 ? oci_identity_domains_group.hdl_authorized_users[0].id : null
}

output "hdl_access_policy_id" {
  description = "ID of the HDL access restriction IAM policy (L2+ only)"
  value       = var.profile_level >= 2 ? oci_identity_policy.hdl_access_policy[0].id : null
}


# -----------------------------------------------------------------------------
# Section 3.1: Data Encryption
# -----------------------------------------------------------------------------

output "hcm_vault_id" {
  description = "ID of the HCM security vault (L2+ only, when auto-created)"
  value       = var.oci_vault_id == "" && var.profile_level >= 2 ? oci_kms_vault.hcm_vault[0].id : var.oci_vault_id
}

output "hcm_master_key_id" {
  description = "ID of the HCM master encryption key (L2+ only, when auto-created)"
  value       = var.oci_key_id == "" && var.profile_level >= 2 ? oci_kms_key.hcm_master_key[0].id : var.oci_key_id
}

output "hcm_secure_exports_bucket" {
  description = "Name of the encrypted Object Storage bucket for HCM exports"
  value       = oci_objectstorage_bucket.hcm_secure_exports.name
}


# -----------------------------------------------------------------------------
# Section 3.2: Data Retention and Purge
# -----------------------------------------------------------------------------

output "hcm_audit_log_group_id" {
  description = "ID of the Logging Analytics log group for HCM audit logs"
  value       = oci_log_analytics_log_group.hcm_audit_logs.id
}

output "dsar_exports_bucket" {
  description = "Name of the DSAR export bucket (L2+ only)"
  value       = var.profile_level >= 2 ? oci_objectstorage_bucket.hcm_dsar_exports[0].name : null
}


# -----------------------------------------------------------------------------
# Section 4.1: Audit Policies
# -----------------------------------------------------------------------------

output "hcm_audit_retention_days" {
  description = "Configured audit retention period in days"
  value       = var.audit_retention_days
}

output "hcm_security_alerts_topic_id" {
  description = "ID of the security alerts notification topic"
  value       = var.alarm_notification_topic_id != "" ? var.alarm_notification_topic_id : oci_ons_notification_topic.hcm_security_alerts[0].id
}

output "auth_failure_alarm_id" {
  description = "ID of the authentication failure monitoring alarm"
  value       = oci_monitoring_alarm.hcm_auth_failures.id
}

output "config_change_alarm_id" {
  description = "ID of the security configuration change alarm"
  value       = oci_monitoring_alarm.hcm_config_changes.id
}

output "data_access_anomaly_alarm_id" {
  description = "ID of the data access anomaly alarm"
  value       = oci_monitoring_alarm.hcm_data_access_anomaly.id
}


# -----------------------------------------------------------------------------
# Section 4.2: Monitor Integration Activity (L2+)
# -----------------------------------------------------------------------------

output "api_rate_alarm_id" {
  description = "ID of the API rate alarm (L2+ only)"
  value       = var.profile_level >= 2 ? oci_monitoring_alarm.api_rate_alarm[0].id : null
}

output "off_hours_activity_alarm_id" {
  description = "ID of the off-hours activity alarm (L2+ only)"
  value       = var.profile_level >= 2 ? oci_monitoring_alarm.off_hours_activity[0].id : null
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
    profile_level               = var.profile_level
    l1_controls_applied         = true
    l2_controls_applied         = var.profile_level >= 2
    l3_controls_applied         = var.profile_level >= 3
    sso_mfa_enforced            = true
    fido2_enabled               = contains(var.mfa_enabled_factors, "FIDO2")
    fido2_only                  = var.profile_level >= 3
    security_roles_created      = true
    password_policy             = "configured"
    password_min_length         = var.profile_level >= 2 ? 15 : 12
    oauth_client_configured     = true
    hdl_restricted              = var.profile_level >= 2
    customer_managed_encryption = var.profile_level >= 2
    hsm_protection              = var.profile_level >= 3
    audit_retention_days        = var.audit_retention_days
    api_rate_monitoring         = var.profile_level >= 2
    off_hours_monitoring        = var.profile_level >= 2
    dsar_bucket_created         = var.profile_level >= 2
  }
}
