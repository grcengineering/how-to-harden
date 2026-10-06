# =============================================================================
# HTH GitHub Control 3.31: Restrict Default GITHUB_TOKEN Permissions
# Profile Level: L1 (Crawl)
# Frameworks: NIST AC-6, CM-7
# Source: https://howtoharden.com/guides/github/#32-use-least-privilege-workflow-permissions
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_actions_organization_workflow_permissions" "hardened" {
  organization_slug                = var.github_organization
  default_workflow_permissions     = "read"
  can_approve_pull_request_reviews = false
}
# HTH Guide Excerpt: end terraform
