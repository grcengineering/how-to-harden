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

# These read the RESOURCE map, not a profile-level expression. Packs 2.2 and 3.2
# no longer gate their for_each on profile_level (a gate there made a level
# downgrade a destroy), so an output that blanks itself below L2 would now be
# reporting {} for pipelines that exist.
output "pipeline_ids" {
  description = "Map of pipeline names to their Buildkite IDs. Empty unless var.pipelines is populated."
  value       = { for k, v in buildkite_pipeline.pipelines : k => v.id }
}

output "pipeline_slugs" {
  description = "Map of pipeline names to their generated slugs. Empty unless var.pipelines is populated."
  value       = { for k, v in buildkite_pipeline.pipelines : k => v.slug }
}

output "pipeline_webhook_urls" {
  description = "Map of pipeline names to their webhook URLs. Empty unless var.pipelines is populated. Destroying a pipeline destroys this URL permanently, which is why pack 2.2 sets prevent_destroy."
  value       = { for k, v in buildkite_pipeline.pipelines : k => v.webhook_url }
  sensitive   = true
}


# -----------------------------------------------------------------------------
# Section 3.1: Agent Tokens
# -----------------------------------------------------------------------------

output "agent_token_ids" {
  description = "Map of agent token labels to their cluster-scoped token IDs"
  value       = { for k, v in buildkite_cluster_agent_token.scoped_lifecycle : k => v.id }
}

output "agent_token_values" {
  description = "Map of agent token labels to their secret values. Returned by the create call only — pipe straight into a secret manager."
  value       = { for k, v in buildkite_cluster_agent_token.scoped_lifecycle : k => v.token }
  sensitive   = true
}

output "agent_token_cluster_uuids" {
  description = "Map of agent token labels to the UUID of the cluster they register into. This is the identifier the REST lifecycle pack needs — REST paths take the cluster UUID, GraphQL takes the base64 cluster ID, and they are not interchangeable."
  value       = { for k, v in buildkite_cluster_agent_token.scoped_lifecycle : k => v.cluster_uuid }
}


# -----------------------------------------------------------------------------
# Section 3.2: Agent Clusters (L2+)
# -----------------------------------------------------------------------------

output "cluster_ids" {
  description = "Map of cluster names to their Buildkite IDs. Empty unless var.clusters is populated."
  value       = { for k, v in buildkite_cluster.clusters : k => v.id }
}

output "cluster_uuids" {
  description = "Map of cluster names to their UUIDs. Empty unless var.clusters is populated."
  value       = { for k, v in buildkite_cluster.clusters : k => v.uuid }
}

output "cluster_queue_ids" {
  description = "Map of cluster queue keys to their IDs. Empty unless var.cluster_queues is populated."
  value       = { for k, v in buildkite_cluster_queue.queues : k => v.id }
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
    enforce_2fa          = var.enforce_2fa
    teams_created        = length(var.teams)
    agent_tokens_created = length(var.agent_tokens)
    clusters_created     = length(buildkite_cluster.clusters)
    pipelines_managed    = length(buildkite_pipeline.pipelines)
    api_ip_restrictions  = var.profile_level >= 3 && length(var.allowed_api_ip_addresses) > 0
    saml_sso             = "configure-via-ui"
    admin_access_review  = "manual-quarterly"
    agent_infrastructure = "configure-via-host-tooling"
    audit_logging        = "enabled-by-default"
  }
}
