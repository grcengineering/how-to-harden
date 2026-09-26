# =============================================================================
# HTH GitHub Control 5.05: Protect Deployment Environments
# Profile Level: L2 (Walk)
# Frameworks: NIST CM-3, CM-5, SA-10
# Source: https://howtoharden.com/guides/github/#51-use-github-actions-secrets-with-environment-protection
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_repository_environment" "production" {
  environment         = "production"
  repository          = var.repository_name
  can_admins_bypass   = false
  prevent_self_review = true

  reviewers {
    teams = [var.security_team_id]
  }

  deployment_branch_policy {
    protected_branches     = true
    custom_branch_policies = false
  }

  lifecycle {
    precondition {
      condition     = var.security_team_id != null
      error_message = "Set security_team_id: an environment with no reviewer team has no approval gate."
    }
  }
}
# HTH Guide Excerpt: end terraform
