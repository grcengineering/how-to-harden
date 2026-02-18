# =============================================================================
# HTH Azure DevOps Control 4.1: Configure Branch Policies
# Profile Level: L1 (Baseline)
# Frameworks: NIST CM-3, SOC 2 CC8.1
# Source: https://howtoharden.com/guides/azure-devops/#41-configure-branch-policies
# =============================================================================

# HTH Guide Excerpt: begin terraform

# ---------------------------------------------------------------------------
# Implement branch policies on the default branch to enforce code review,
# prevent direct pushes, and require build validation. Minimum reviewer
# count scales with profile level (L1: 1, L2: 2, L3: 3).
# ---------------------------------------------------------------------------

# Require minimum number of reviewers for pull requests
resource "azuredevops_branch_policy_min_reviewers" "main" {
  count = var.repository_id != "" ? 1 : 0

  project_id = data.azuredevops_project.target.id
  enabled    = true
  blocking   = true

  settings {
    reviewer_count                         = var.min_reviewer_count
    submitter_can_vote                     = false
    last_pusher_cannot_approve             = true
    allow_completion_with_rejects_or_waits = false
    on_push_reset_approved_votes           = true

    scope {
      repository_id  = var.repository_id
      repository_ref = var.default_branch
      match_type     = "Exact"
    }
  }
}

# Require comment resolution before merge
resource "azuredevops_branch_policy_comment_resolution" "main" {
  count = var.repository_id != "" ? 1 : 0

  project_id = data.azuredevops_project.target.id
  enabled    = true
  blocking   = true

  settings {
    scope {
      repository_id  = var.repository_id
      repository_ref = var.default_branch
      match_type     = "Exact"
    }
  }
}

# Require linked work items
resource "azuredevops_branch_policy_work_item_linking" "main" {
  count = var.repository_id != "" ? 1 : 0

  project_id = data.azuredevops_project.target.id
  enabled    = true
  blocking   = true

  settings {
    scope {
      repository_id  = var.repository_id
      repository_ref = var.default_branch
      match_type     = "Exact"
    }
  }
}

# Restrict merge types -- allow squash and rebase only (L2+)
resource "azuredevops_branch_policy_merge_types" "main" {
  count = var.profile_level >= 2 && var.repository_id != "" ? 1 : 0

  project_id = data.azuredevops_project.target.id
  enabled    = true
  blocking   = true

  settings {
    allow_squash                  = true
    allow_rebase_and_fast_forward = true
    allow_basic_no_fast_forward   = false
    allow_rebase_with_merge       = false

    scope {
      repository_id  = var.repository_id
      repository_ref = var.default_branch
      match_type     = "Exact"
    }
  }
}

# Build validation -- require CI pipeline to pass before merge
resource "azuredevops_branch_policy_build_validation" "main" {
  count = var.build_validation_definition_id > 0 && var.repository_id != "" ? 1 : 0

  project_id = data.azuredevops_project.target.id
  enabled    = true
  blocking   = true

  settings {
    display_name        = "CI Build Validation"
    build_definition_id = var.build_validation_definition_id
    valid_duration      = 720
    filename_patterns   = []

    scope {
      repository_id  = var.repository_id
      repository_ref = var.default_branch
      match_type     = "Exact"
    }
  }
}

# Auto-reviewers for pipeline YAML changes (L2+)
resource "azuredevops_branch_policy_auto_reviewers" "pipeline_yaml" {
  count = var.profile_level >= 2 && var.repository_id != "" && length(var.pipeline_yaml_reviewers) > 0 ? 1 : 0

  project_id = data.azuredevops_project.target.id
  enabled    = true
  blocking   = true

  settings {
    auto_reviewer_ids  = var.pipeline_yaml_reviewers
    submitter_can_vote = false
    message            = "Pipeline YAML changes require security team review"
    path_filters       = ["azure-pipelines.yml", "azure-pipelines/*.yml", ".azuredevops/*.yml"]

    scope {
      repository_id  = var.repository_id
      repository_ref = var.default_branch
      match_type     = "Exact"
    }
  }
}

# Auto-reviewers for Terraform changes (L2+)
resource "azuredevops_branch_policy_auto_reviewers" "terraform" {
  count = var.profile_level >= 2 && var.repository_id != "" && length(var.pipeline_yaml_reviewers) > 0 ? 1 : 0

  project_id = data.azuredevops_project.target.id
  enabled    = true
  blocking   = true

  settings {
    auto_reviewer_ids  = var.pipeline_yaml_reviewers
    submitter_can_vote = false
    message            = "Terraform changes require platform team review"
    path_filters       = ["terraform/*", "*.tf"]

    scope {
      repository_id  = var.repository_id
      repository_ref = var.default_branch
      match_type     = "Exact"
    }
  }
}

# HTH Guide Excerpt: end terraform
