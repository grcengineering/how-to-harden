# =============================================================================
# HTH Azure DevOps Control 3.1: Implement YAML Pipeline Security
# Profile Level: L1 (Baseline)
# Frameworks: NIST CM-7
# Source: https://howtoharden.com/guides/azure-devops/#31-implement-yaml-pipeline-security
# =============================================================================

# HTH Guide Excerpt: begin terraform

# ---------------------------------------------------------------------------
# Pipeline settings for this control are consolidated in the
# azuredevops_project_pipeline_settings resource defined in Control 1.3
# (hth-azure-devops-1.3-configure-personal-access-token-policies.tf).
#
# The Terraform provider allows only one pipeline_settings resource per
# project. The following settings from Control 1.3 implement this control:
#
#   enforce_job_scope                    = true   (L1)
#   enforce_job_scope_for_release        = true   (L1)
#   enforce_referenced_repo_scoped_token = true   (L1)
#   enforce_settable_var                 = true   (L2+)
#
# Classic pipeline creation is disabled at the organization level via
# the Azure DevOps UI:
#   Organization Settings > Pipelines > Settings
#     - Disable creation of classic build pipelines: Enable
#     - Disable creation of classic release pipelines: Enable
# ---------------------------------------------------------------------------

# No additional resources -- see Control 1.3 for pipeline settings.

# HTH Guide Excerpt: end terraform
