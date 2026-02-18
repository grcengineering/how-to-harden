# =============================================================================
# New Relic Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: SSO Bypass Detection
# -----------------------------------------------------------------------------

output "sso_bypass_policy_id" {
  description = "ID of the SSO bypass detection alert policy"
  value       = newrelic_alert_policy.sso_bypass_detection.id
}

output "non_sso_login_condition_id" {
  description = "ID of the non-SSO login detection alert condition"
  value       = newrelic_nrql_alert_condition.non_sso_login.id
}


# -----------------------------------------------------------------------------
# Section 1.2: Access Control Monitoring
# -----------------------------------------------------------------------------

output "access_control_policy_id" {
  description = "ID of the access control monitoring alert policy"
  value       = newrelic_alert_policy.access_control_monitoring.id
}

output "role_changes_condition_id" {
  description = "ID of the role/group change detection alert condition"
  value       = newrelic_nrql_alert_condition.role_changes.id
}


# -----------------------------------------------------------------------------
# Section 2.1: API Key Management
# -----------------------------------------------------------------------------

output "managed_ingest_key_id" {
  description = "ID of the managed ingest key (empty if api_key_user_id not set)"
  value       = var.api_key_user_id > 0 ? newrelic_api_access_key.managed_ingest_key[0].id : null
}

output "api_key_monitoring_policy_id" {
  description = "ID of the API key lifecycle monitoring alert policy"
  value       = newrelic_alert_policy.api_key_monitoring.id
}


# -----------------------------------------------------------------------------
# Section 2.2: License Key Anomaly Detection
# -----------------------------------------------------------------------------

output "license_key_monitoring_policy_id" {
  description = "ID of the license key anomaly detection alert policy"
  value       = newrelic_alert_policy.license_key_monitoring.id
}


# -----------------------------------------------------------------------------
# Section 3.1: Data Obfuscation
# -----------------------------------------------------------------------------

output "obfuscation_expression_ids" {
  description = "Map of obfuscation expression names to IDs"
  value       = { for k, v in newrelic_obfuscation_expression.sensitive_patterns : k => v.id }
}

output "obfuscation_rule_ids" {
  description = "Map of obfuscation rule names to IDs"
  value       = { for k, v in newrelic_obfuscation_rule.sensitive_data_masking : k => v.id }
}

output "data_obfuscation_policy_id" {
  description = "ID of the data obfuscation monitoring alert policy"
  value       = newrelic_alert_policy.data_obfuscation_monitoring.id
}


# -----------------------------------------------------------------------------
# Section 3.2: Data Retention
# -----------------------------------------------------------------------------

output "data_retention_policy_id" {
  description = "ID of the data retention compliance alert policy"
  value       = newrelic_alert_policy.data_retention_monitoring.id
}


# -----------------------------------------------------------------------------
# Section 4.1: NrAuditEvent Monitoring
# -----------------------------------------------------------------------------

output "audit_event_policy_id" {
  description = "ID of the NrAuditEvent security monitoring alert policy"
  value       = newrelic_alert_policy.audit_event_monitoring.id
}

output "config_changes_condition_id" {
  description = "ID of the configuration change detection condition"
  value       = newrelic_nrql_alert_condition.config_changes.id
}

output "api_key_creation_condition_id" {
  description = "ID of the API key creation detection condition"
  value       = newrelic_nrql_alert_condition.api_key_creation.id
}

output "user_changes_condition_id" {
  description = "ID of the user change detection condition"
  value       = newrelic_nrql_alert_condition.user_changes.id
}

output "deletion_events_condition_id" {
  description = "ID of the deletion event detection condition"
  value       = newrelic_nrql_alert_condition.deletion_events.id
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
    sso_bypass_detection      = "enabled"
    access_control_monitoring = "enabled"
    api_key_management        = var.api_key_user_id > 0
    api_key_monitoring        = "enabled"
    license_key_monitoring    = "enabled"
    data_obfuscation          = length(var.obfuscation_patterns) > 0 ? "enabled" : "disabled"
    obfuscation_patterns      = length(var.obfuscation_patterns)
    data_retention_monitoring = "enabled"
    audit_event_monitoring    = "enabled"
  }
}
