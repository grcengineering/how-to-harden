# =============================================================================
# Docker Hub Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: MFA and SSO
# -----------------------------------------------------------------------------

output "sso_enforcement_id" {
  description = "ID of the SSO enforcement setting (if enabled)"
  value       = var.enforce_sso ? docker_org_setting.enforce_sso[0].id : null
}


# -----------------------------------------------------------------------------
# Section 1.2: Access Tokens
# -----------------------------------------------------------------------------

output "ci_cd_token_id" {
  description = "ID of the CI/CD read-only access token"
  value       = docker_hub_access_token.ci_cd_readonly.id
}

output "build_token_id" {
  description = "ID of the build read/write access token"
  value       = docker_hub_access_token.build_readwrite.id
}


# -----------------------------------------------------------------------------
# Section 2.1: Docker Scout
# -----------------------------------------------------------------------------

output "scout_enabled_repositories" {
  description = "List of repositories with Docker Scout enabled"
  value       = [for repo, config in docker_hub_repository_scout.org_repos : repo]
}


# -----------------------------------------------------------------------------
# Section 3.1: Private Repository Configuration
# -----------------------------------------------------------------------------

output "managed_repository_ids" {
  description = "Map of managed repository names to their IDs"
  value       = { for repo, config in docker_hub_repository.managed : repo => config.id }
}

output "repository_visibility" {
  description = "Map of repository names to their visibility status"
  value       = { for repo, config in docker_hub_repository.managed : repo => config.private ? "private" : "public" }
}


# -----------------------------------------------------------------------------
# Section 4.1: Audit Logging
# -----------------------------------------------------------------------------

output "audit_log_export_enabled" {
  description = "Whether audit log export to SIEM is enabled"
  value       = var.audit_log_export_enabled
}

output "siem_webhook_id" {
  description = "ID of the SIEM audit log webhook (if configured)"
  value       = var.audit_log_export_enabled && var.siem_webhook_url != "" ? docker_hub_webhook.audit_siem_forwarder[0].id : null
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
    sso_enforced         = var.enforce_sso
    access_tokens        = "configured"
    scout_scanning       = length(var.repositories) > 0 ? "enabled" : "no_repositories"
    content_trust        = var.profile_level >= 2 ? "enabled" : "not_applied"
    cosign_signing       = var.profile_level >= 3 ? "enabled" : "not_applied"
    repositories_managed = length(var.repositories)
    audit_log_export     = var.audit_log_export_enabled
    enhanced_monitoring  = var.profile_level >= 2
  }
}
