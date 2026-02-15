# =============================================================================
# HTH GitHub Control 1.02: Restrict Default Repository Permissions
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-6, AC-6(1)
# Source: https://howtoharden.com/guides/github/#12-restrict-default-repository-permissions
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_organization_settings" "permissions" {
  billing_email                      = var.github_organization
  default_repository_permission      = "read"
}
# HTH Guide Excerpt: end terraform
