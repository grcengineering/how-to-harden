# =============================================================================
# HTH GitHub Control 5.05: Protect Deployment Environments
# Profile Level: L2 (Hardened)
# Frameworks: NIST CM-3, CM-5, SA-10
# Source: https://howtoharden.com/guides/github/#55-protect-deployment-environments
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_repository_environment" "production" {
  environment = "production"
  repository  = var.repository_name

  reviewers {
    teams = [var.security_team_id]
  }

  deployment_branch_policy {
    protected_branches     = true
    custom_branch_policies = false
  }
}
# HTH Guide Excerpt: end terraform
