# =============================================================================
# Buildkite Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.2: Two-Factor Authentication
# -----------------------------------------------------------------------------

output "enforce_2fa_enabled" {
  description = "Whether 2FA enforcement is enabled for the organization"
  value       = buildkite_organization.hardened.enforce_2fa
}


# -----------------------------------------------------------------------------
# Section 2.1: Team Permissions
# -----------------------------------------------------------------------------

output "team_ids" {
  description = "Map of team names to their Buildkite IDs"
  value       = { for k, v in buildkite_team.teams : k => v.id }
}

output "team_slugs" {
  description = "Map of team names to their generated slugs"
  value       = { for k, v in buildkite_team.teams : k => v.slug }
}

output "team_uuids" {
  description = "Map of team names to their UUIDs"
  value       = { for k, v in buildkite_team.teams : k => v.uuid }
}


# -----------------------------------------------------------------------------
# Section 2.2: Pipeline Permissions (L2+)
# -----------------------------------------------------------------------------

output "pipeline_ids" {
  description = "Map of pipeline names to their Buildkite IDs (L2+ only)"
  value       = var.profile_level >= 2 ? { for k, v in buildkite_pipeline.pipelines : k => v.id } : {}
}

output "pipeline_slugs" {
  description = "Map of pipeline names to their generated slugs (L2+ only)"
  value       = var.profile_level >= 2 ? { for k, v in buildkite_pipeline.pipelines : k => v.slug } : {}
}

output "pipeline_webhook_urls" {
  description = "Map of pipeline names to their webhook URLs (L2+ only)"
  value       = var.profile_level >= 2 ? { for k, v in buildkite_pipeline.pipelines : k => v.webhook_url } : {}
  sensitive   = true
}


# -----------------------------------------------------------------------------
# Section 3.1: Agent Tokens
# -----------------------------------------------------------------------------

output "agent_token_ids" {
  description = "Map of agent token names to their IDs"
  value       = { for k, v in buildkite_agent_token.tokens : k => v.id }
}

output "agent_token_values" {
  description = "Map of agent token names to their token values (sensitive)"
  value       = { for k, v in buildkite_agent_token.tokens : k => v.token }
  sensitive   = true
}


# -----------------------------------------------------------------------------
# Section 3.2: Agent Clusters (L2+)
# -----------------------------------------------------------------------------

output "cluster_ids" {
  description = "Map of cluster names to their Buildkite IDs (L2+ only)"
  value       = var.profile_level >= 2 ? { for k, v in buildkite_cluster.clusters : k => v.id } : {}
}

output "cluster_uuids" {
  description = "Map of cluster names to their UUIDs (L2+ only)"
  value       = var.profile_level >= 2 ? { for k, v in buildkite_cluster.clusters : k => v.uuid } : {}
}

output "cluster_queue_ids" {
  description = "Map of cluster queue keys to their IDs (L2+ only)"
  value       = var.profile_level >= 2 ? { for k, v in buildkite_cluster_queue.queues : k => v.id } : {}
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
    enforce_2fa            = var.enforce_2fa
    teams_created          = length(var.teams)
    agent_tokens_created   = length(var.agent_tokens)
    clusters_created       = var.profile_level >= 2 ? length(var.clusters) : 0
    pipelines_managed      = var.profile_level >= 2 ? length(var.pipelines) : 0
    api_ip_restrictions    = var.profile_level >= 3 && length(var.allowed_api_ip_addresses) > 0
    saml_sso               = "configure-via-ui"
    admin_access_review    = "manual-quarterly"
    agent_infrastructure   = "configure-via-host-tooling"
    audit_logging          = "enabled-by-default"
  }
}
