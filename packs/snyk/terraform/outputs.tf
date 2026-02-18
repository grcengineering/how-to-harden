# =============================================================================
# Snyk Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: SSO with MFA
# -----------------------------------------------------------------------------

output "sso_enforcement_org_id" {
  description = "ID of the Snyk organization with SSO enforcement configured"
  value       = snyk_organization.sso_enforcement.id
}


# -----------------------------------------------------------------------------
# Section 2.2: SCM Integration Security
# -----------------------------------------------------------------------------

output "scm_integration_id" {
  description = "ID of the configured SCM integration"
  value       = snyk_integration.scm.id
}

output "scm_integration_type" {
  description = "Type of SCM integration configured"
  value       = snyk_integration.scm.type
}

output "broker_integration_id" {
  description = "ID of the Snyk Broker integration (Enterprise only)"
  value       = var.broker_enabled ? snyk_integration.broker[0].id : null
}


# -----------------------------------------------------------------------------
# Section 3.2: Ignore Policy (L2+)
# -----------------------------------------------------------------------------

output "ignore_policy_org_id" {
  description = "ID of the organization with ignore policy enforced (L2+ only)"
  value       = var.profile_level >= 2 ? snyk_organization.ignore_policy[0].id : null
}


# -----------------------------------------------------------------------------
# Section 4.1: Audit Logs & Notification Settings
# -----------------------------------------------------------------------------

output "new_issues_notification_enabled" {
  description = "Whether new vulnerability issue notifications are enabled"
  value       = var.new_issues_notification
}

output "weekly_report_enabled" {
  description = "Whether the weekly vulnerability report is enabled"
  value       = var.weekly_report_enabled
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
    sso_enforcement        = var.sso_enabled ? "enforced" : "not_enforced"
    scm_integration        = var.scm_integration_type
    broker_enabled         = var.broker_enabled
    project_visibility     = var.default_project_visibility
    ignore_policy          = var.profile_level >= 2 ? "enforced" : "default"
    ignore_expiration_days = var.profile_level >= 2 ? var.ignore_expiration_days : null
    require_ignore_reason  = var.profile_level >= 2 ? var.require_ignore_reason : null
    new_issue_alerts       = var.new_issues_notification ? "ENABLED" : "DISABLED"
    weekly_report          = var.weekly_report_enabled ? "ENABLED" : "DISABLED"
    service_accounts       = length(var.service_accounts)
  }
}
