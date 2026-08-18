# =============================================================================
# HTH Buildkite Control 2.2: Configure Pipeline Permissions
# Profile Level: L2 (Walk)
# Frameworks: CIS 5.4 | NIST AC-6
# Source: https://howtoharden.com/guides/buildkite/#22-configure-pipeline-permissions
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create pipelines with hardened defaults. Control 2.2 is an L2 control.
#
# NO PROFILE-LEVEL GATE ON for_each, DELIBERATELY. This line used to read
# `var.profile_level >= 2 ? var.pipelines : {}`. var.profile_level defaults to 1,
# so a single `terraform apply` that omitted `-var="profile_level=2"` emptied the
# map and Terraform DESTROYED every pipeline it had created, taking that
# pipeline's build history and its webhook URL with it. Profile level selects
# WHAT you declare; it must never decide whether declared resources survive.
# var.pipelines defaults to `{}`, so declaring nothing is already the "off"
# state. Pack 3.10 carries the same fix on buildkite_pipeline.templated.
resource "buildkite_pipeline" "pipelines" {
  for_each = var.pipelines

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

  lifecycle {
    # A Buildkite pipeline carries its build history and its webhook URL; both
    # are destroyed with it and neither comes back. Dropping a key from
    # var.pipelines must be a deliberate act, not the side effect of a forgotten
    # -var or an edited tfvars file, so Terraform refuses the destroy at PLAN
    # time. Same guard as pack 3.11 puts on buildkite_registry and pack 3.10 on
    # buildkite_pipeline.templated. To retire a pipeline on purpose: delete this
    # line, apply, restore it.
    #
    # DELIBERATELY A LITERAL. OpenTofu 1.12 does accept an expression here
    # (measured, not assumed), which is precisely why this must not become
    # `var.profile_level >= 2`: the one forgotten -var would then empty the
    # for_each AND disarm the guard in the same plan, rebuilding the original
    # bug with an extra step.
    prevent_destroy = true
  }
}

# Assign team access to pipelines with explicit permission levels.
# No profile gate, same reasoning: an empty var.pipeline_team_access (the
# default) is the off state. A destroyed buildkite_pipeline_team revokes that
# team's access to the pipeline, which is recoverable by re-declaring it — but it
# should still not happen because someone forgot a -var.
resource "buildkite_pipeline_team" "access" {
  for_each = var.pipeline_team_access

  pipeline_id  = buildkite_pipeline.pipelines[each.value.pipeline_key].id
  team_id      = buildkite_team.teams[each.value.team_key].id
  access_level = each.value.access_level
}
# HTH Guide Excerpt: end terraform
