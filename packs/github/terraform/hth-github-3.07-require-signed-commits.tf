# =============================================================================
# HTH GitHub Control 3.07: Require Signed Commits
# Profile Level: L3 (Maximum Security)
# Frameworks: NIST AU-10, SC-13
# Source: https://howtoharden.com/guides/github/#37-require-signed-commits
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_branch_protection" "main_signed" {
  repository_id          = var.repository_id
  pattern                = "main"
  require_signed_commits = true
}
# HTH Guide Excerpt: end terraform
