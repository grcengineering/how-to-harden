# =============================================================================
# HTH GitHub Control 1.05: Require Web Commit Sign-Off
# Profile Level: L2 (Hardened)
# Frameworks: NIST AU-10, CM-5
# Source: https://howtoharden.com/guides/github/#15-require-commit-sign-off
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_organization_settings" "commit_signoff" {
  billing_email                      = var.github_organization
  web_commit_signoff_required        = true
}
# HTH Guide Excerpt: end terraform
