# =============================================================================
# HTH GitHub Control 3.01: Enable Branch Protection on Default Branch
# Profile Level: L1 (Baseline)
# Frameworks: NIST CM-3, CM-5
# Source: https://howtoharden.com/guides/github/#31-enable-branch-protection
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_branch_protection" "main" {
  repository_id = var.repository_id
  pattern       = "main"
  enforce_admins = true

  required_pull_request_reviews {
    required_approving_review_count = 1
    dismiss_stale_reviews           = true
  }
}
# HTH Guide Excerpt: end terraform
