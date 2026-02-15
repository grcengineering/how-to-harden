# =============================================================================
# HTH GitHub Control 3.04: Restrict GitHub Actions at Organization Level
# Profile Level: L2 (Hardened)
# Frameworks: NIST CM-7, SA-12
# Source: https://howtoharden.com/guides/github/#34-restrict-actions-org-level
# =============================================================================

# HTH Guide Excerpt: begin terraform
# NOTE: The github_actions_organization_permissions resource controls which
# Actions are allowed to run across the entire organization. This restricts
# all repositories to only GitHub-owned and Marketplace-verified actions.
resource "github_actions_organization_permissions" "hardened" {
  allowed_actions = "selected"
  enabled_repositories = "all"

  allowed_actions_config {
    github_owned_allowed = true
    verified_allowed     = true
  }
}
# HTH Guide Excerpt: end terraform
