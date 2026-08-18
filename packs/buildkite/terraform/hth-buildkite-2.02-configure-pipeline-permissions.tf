# =============================================================================
# HTH Buildkite Control 2.2: Configure Pipeline Permissions
# Profile Level: L2 (Walk)
# Frameworks: CIS 5.4 | NIST AC-6
# Source: https://howtoharden.com/guides/buildkite/#22-configure-pipeline-permissions
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create pipelines with hardened defaults (L2+)
resource "buildkite_pipeline" "pipelines" {
  for_each = var.profile_level >= 2 ? var.pipelines : {}

  name                       = each.key
  repository                 = each.value.repository
  description                = each.value.description
  default_branch             = each.value.default_branch
  branch_configuration       = each.value.branch_configuration
  skip_intermediate_builds   = each.value.skip_intermediate_builds
  cancel_intermediate_builds = each.value.cancel_intermediate_builds
  cluster_id                 = each.value.cluster_id
  default_timeout_in_minutes = each.value.default_timeout_in_minutes
  maximum_timeout_in_minutes = each.value.maximum_timeout_in_minutes
  allow_rebuilds             = each.value.allow_rebuilds

  # Guide Step 1 ("Configure Pipeline Visibility") implemented. PUBLIC exposes
  # build logs, job output, artifacts metadata and the pipeline definition to
  # anonymous internet users, so this defaults to PRIVATE in var.pipelines.
  #
  # WHY IT MUST BE DECLARED, NOT OMITTED: `visibility` is optional + COMPUTED in
  # buildkite/buildkite. An omitted computed attribute is not "the safe default" —
  # Terraform reads whatever the server currently holds into state and treats that
  # value as desired. A console flip to PUBLIC therefore produces an empty plan and
  # survives every subsequent apply, forever. Declaring it is what converts that
  # flip into drift the next `terraform plan` reverts.
  visibility = each.value.visibility

  # Restrict fork builds to prevent untrusted code execution.
  # provider_settings is an ATTRIBUTE in buildkite/buildkite ~> 1.0, not a block —
  # block syntax fails `terraform validate` with "Unsupported block type".
  provider_settings = {
    build_pull_request_forks              = false
    publish_commit_status                 = true
    publish_commit_status_per_step        = true
    skip_builds_for_existing_commits      = true
    cancel_deleted_branch_builds          = true
    prefix_pull_request_fork_branch_names = true
  }
}

# Assign team access to pipelines with explicit permission levels
resource "buildkite_pipeline_team" "access" {
  for_each = var.profile_level >= 2 ? var.pipeline_team_access : {}

  pipeline_id  = buildkite_pipeline.pipelines[each.value.pipeline_key].id
  team_id      = buildkite_team.teams[each.value.team_key].id
  access_level = each.value.access_level
}
# HTH Guide Excerpt: end terraform
