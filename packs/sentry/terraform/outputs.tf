# =============================================================================
# Sentry Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: SAML SSO (Audit Reference)
# -----------------------------------------------------------------------------

output "organization_id" {
  description = "Internal ID of the Sentry organization (for audit reference)"
  value       = data.sentry_organization.main.id
}

output "organization_slug" {
  description = "Slug of the Sentry organization"
  value       = data.sentry_organization.main.slug
}


# -----------------------------------------------------------------------------
# Section 2.1: Team Access
# -----------------------------------------------------------------------------

output "team_ids" {
  description = "Map of team slugs to their internal IDs"
  value       = { for k, v in sentry_team.teams : k => v.internal_id }
}


# -----------------------------------------------------------------------------
# Section 2.2: Project Access (L2+)
# -----------------------------------------------------------------------------

output "project_ids" {
  description = "Map of project slugs to their internal IDs (L2+ only)"
  value       = { for k, v in sentry_project.projects : k => v.internal_id }
}


# -----------------------------------------------------------------------------
# Section 2.3: Limit Admin Access
# -----------------------------------------------------------------------------

output "admin_member_ids" {
  description = "Map of admin email addresses to their member IDs"
  value       = { for k, v in sentry_organization_member.admins : k => v.internal_id }
}


# -----------------------------------------------------------------------------
# Section 3.2: DSN Security (L2+)
# -----------------------------------------------------------------------------

output "rate_limited_key_ids" {
  description = "Map of project slugs to their rate-limited DSN key IDs (L2+ only)"
  value       = { for k, v in sentry_key.rate_limited : k => v.id }
}

output "rate_limited_dsn_public" {
  description = "Map of project slugs to their rate-limited public DSN values (L2+ only)"
  value       = { for k, v in sentry_key.rate_limited : k => v.dsn["public"] }
  sensitive   = true
}


# -----------------------------------------------------------------------------
# Section 4.1: Audit Logs - Security Monitoring Alert
# -----------------------------------------------------------------------------

output "security_alert_id" {
  description = "ID of the security monitoring issue alert (if configured)"
  value       = length(sentry_issue_alert.security_monitoring) > 0 ? sentry_issue_alert.security_monitoring[0].id : null
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
    teams_created        = length(var.teams)
    projects_managed     = var.profile_level >= 2 ? length(var.projects) : 0
    admin_members        = length(var.admin_members)
    dsn_rate_limiting    = var.profile_level >= 2 ? "enabled" : "not_applied"
    inbound_data_filters = var.profile_level >= 2 ? "enabled" : "not_applied"
    legacy_browser_block = var.profile_level >= 2 ? "enabled" : "not_applied"
    security_alert       = var.security_alert_project != "" ? "enabled" : "not_configured"
    sso_enforcement      = "manual_verification_required"
    two_factor_auth      = "manual_verification_required"
    data_scrubbing       = "manual_verification_required"
  }
}
