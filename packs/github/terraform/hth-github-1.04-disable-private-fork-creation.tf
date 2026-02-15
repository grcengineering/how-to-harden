# =============================================================================
# HTH GitHub Control 1.04: Disable Private Repository Forking
# Profile Level: L2 (Hardened)
# Frameworks: NIST AC-4, AC-6
# Source: https://howtoharden.com/guides/github/#14-disable-private-repository-forking
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_organization_settings" "forking" {
  billing_email                           = var.github_organization
  members_can_fork_private_repositories   = false
}
# HTH Guide Excerpt: end terraform
