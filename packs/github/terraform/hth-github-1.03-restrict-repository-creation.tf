# =============================================================================
# HTH GitHub Control 1.03: Restrict Public Repository Creation
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-4, AC-22
# Source: https://howtoharden.com/guides/github/#13-restrict-public-repository-creation
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_organization_settings" "repo_creation" {
  billing_email                           = var.github_organization
  members_can_create_public_repositories  = false
}
# HTH Guide Excerpt: end terraform
