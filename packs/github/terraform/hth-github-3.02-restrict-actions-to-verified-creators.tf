# =============================================================================
# HTH GitHub Control 3.02: Restrict Actions to Verified Creators
# Profile Level: L2 (Hardened)
# Frameworks: NIST CM-7, SA-12
# Source: https://howtoharden.com/guides/github/#32-restrict-github-actions
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_actions_repository_permissions" "how_to_harden_actions" {
  repository      = var.repository_name
  enabled         = true
  allowed_actions = "selected"

  allowed_actions_config {
    github_owned_allowed = true
    verified_allowed     = true
  }
}
# HTH Guide Excerpt: end terraform
