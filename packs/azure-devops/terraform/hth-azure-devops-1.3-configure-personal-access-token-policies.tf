# =============================================================================
# HTH Azure DevOps Control 1.3: Configure Personal Access Token Policies
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5
# Source: https://howtoharden.com/guides/azure-devops/#13-configure-personal-access-token-policies
# =============================================================================

# HTH Guide Excerpt: begin terraform

# ---------------------------------------------------------------------------
# PAT policies are managed at the organization level via the Azure DevOps
# REST API or UI -- not through the Terraform provider. This resource
# configures project pipeline settings to restrict token scope at the
# project level, complementing organization-level PAT restrictions.
# ---------------------------------------------------------------------------

resource "azuredevops_project_pipeline_settings" "pat_restrictions" {
  project_id = data.azuredevops_project.target.id

  # Restrict pipeline job authorization scope to current project
  enforce_job_scope                    = true
  enforce_job_scope_for_release        = true
  enforce_referenced_repo_scoped_token = true

  # Restrict settable variables at queue time (L2+)
  enforce_settable_var = var.profile_level >= 2 ? true : false
}

# HTH Guide Excerpt: end terraform
