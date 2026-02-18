# =============================================================================
# Splunk Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: SAML SSO
# -----------------------------------------------------------------------------

output "saml_configured" {
  description = "Whether SAML SSO was configured"
  value       = var.saml_idp_url != "" ? true : false
}


# -----------------------------------------------------------------------------
# Section 1.2: Local Admin Fallback
# -----------------------------------------------------------------------------

output "emergency_admin_created" {
  description = "Whether the emergency local admin account was created"
  value       = var.local_admin_password != "" ? true : false
}

output "emergency_admin_username" {
  description = "Username of the emergency admin account"
  value       = var.local_admin_password != "" ? var.local_admin_username : null
}


# -----------------------------------------------------------------------------
# Section 2.1: RBAC
# -----------------------------------------------------------------------------

output "security_analyst_role_name" {
  description = "Name of the custom security analyst role"
  value       = splunk_authorization_roles.security_analyst.name
}

output "restricted_power_role_name" {
  description = "Name of the restricted power user role (L2+ only)"
  value       = var.profile_level >= 2 ? splunk_authorization_roles.restricted_power[0].name : null
}

output "auditor_role_name" {
  description = "Name of the auditor role (L2+ only)"
  value       = var.profile_level >= 2 ? splunk_authorization_roles.auditor[0].name : null
}


# -----------------------------------------------------------------------------
# Section 2.2: Index Access
# -----------------------------------------------------------------------------

output "security_index_name" {
  description = "Name of the dedicated security log index"
  value       = splunk_indexes.security.name
}

output "audit_trail_index_name" {
  description = "Name of the audit trail index"
  value       = splunk_indexes.audit_trail.name
}

output "threat_intel_index_name" {
  description = "Name of the threat intelligence index (L2+ only)"
  value       = var.profile_level >= 2 ? splunk_indexes.threat_intel[0].name : null
}


# -----------------------------------------------------------------------------
# Section 3.2: Encryption / HEC
# -----------------------------------------------------------------------------

output "hec_ssl_enabled" {
  description = "Whether SSL is enabled on the HTTP Event Collector"
  value       = var.hec_enable_ssl
}


# -----------------------------------------------------------------------------
# Section 4.1: Audit Logging
# -----------------------------------------------------------------------------

output "audit_alert_role_changes" {
  description = "Name of the role change alert saved search"
  value       = splunk_saved_searches.alert_role_changes.name
}

output "audit_alert_failed_auth" {
  description = "Name of the failed authentication alert saved search"
  value       = splunk_saved_searches.alert_failed_auth.name
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
    saml_sso               = var.saml_idp_url != "" ? "configured" : "skipped (no IdP URL)"
    emergency_admin        = var.local_admin_password != "" ? "created" : "skipped (no password)"
    rbac_analyst_role      = "created"
    rbac_auditor_role      = var.profile_level >= 2 ? "created" : "skipped (L2+)"
    security_index         = "created"
    audit_trail_index      = "created"
    threat_intel_index     = var.profile_level >= 2 ? "created" : "skipped (L2+)"
    search_hardening       = var.profile_level >= 2 ? "hardened" : "baseline"
    hec_ssl                = var.hec_enable_ssl ? "enabled" : "disabled"
    ssl_hardening          = var.profile_level >= 2 ? "TLS 1.2+" : "default"
    tls13_enforcement      = var.profile_level >= 3 ? "TLS 1.3 only" : "not enforced"
    audit_alerts           = var.profile_level >= 2 ? "role_changes, failed_auth, config_changes, sensitive_search" : "role_changes, failed_auth"
  }
}
