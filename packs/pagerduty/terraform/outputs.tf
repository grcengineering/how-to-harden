# =============================================================================
# PagerDuty Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 3.1: Role-Based Access - Teams
# -----------------------------------------------------------------------------

output "team_ids" {
  description = "Map of team names to their PagerDuty IDs"
  value       = { for name, team in pagerduty_team.teams : name => team.id }
}

output "team_count" {
  description = "Number of RBAC teams created"
  value       = length(pagerduty_team.teams)
}


# -----------------------------------------------------------------------------
# Section 4.1: Audit Logging
# -----------------------------------------------------------------------------

output "audit_service_id" {
  description = "ID of the audit log collector service (if webhook configured)"
  value       = var.audit_log_webhook_url != "" ? pagerduty_service.audit_logging[0].id : null
}

output "audit_webhook_id" {
  description = "ID of the audit log webhook extension (if configured)"
  value       = var.audit_log_webhook_url != "" ? pagerduty_extension.audit_webhook[0].id : null
}

output "audit_escalation_policy_id" {
  description = "ID of the audit log escalation policy (if webhook configured)"
  value       = var.audit_log_webhook_url != "" ? pagerduty_escalation_policy.audit_logging[0].id : null
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
    profile_level        = var.profile_level
    l1_controls_applied  = true
    l2_controls_applied  = var.profile_level >= 2
    l3_controls_applied  = var.profile_level >= 3
    saml_sso             = var.sso_login_url != "" ? "configured" : "manual_required"
    user_provisioning    = "saml_on_demand"
    scim_provisioning    = var.profile_level >= 2 ? "enabled" : "not_required"
    rbac_teams           = length(pagerduty_team.teams)
    admin_limit          = var.max_admin_count
    audit_logging        = "enabled"
    audit_siem_webhook   = var.audit_log_webhook_url != "" ? "configured" : "manual_required"
    observer_roles       = var.profile_level >= 2 ? length(var.observer_user_ids) : 0
  }
}
