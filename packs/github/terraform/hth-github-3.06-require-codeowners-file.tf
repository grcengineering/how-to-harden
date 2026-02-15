# =============================================================================
# HTH GitHub Control 3.06: Require CODEOWNERS Review
# Profile Level: L2 (Hardened)
# Frameworks: NIST CM-3, CM-5
# Source: https://howtoharden.com/guides/github/#36-require-codeowners
# =============================================================================

# HTH Guide Excerpt: begin terraform
# NOTE: The CODEOWNERS file itself must be committed to the repository
# (e.g., .github/CODEOWNERS). This Terraform resource enforces that
# pull requests require approval from designated code owners before merge.
resource "github_branch_protection" "main_codeowners" {
  repository_id = var.repository_id
  pattern       = "main"

  required_pull_request_reviews {
    require_code_owner_reviews = true
  }
}
# HTH Guide Excerpt: end terraform
