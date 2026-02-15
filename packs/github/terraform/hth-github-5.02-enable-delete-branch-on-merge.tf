# =============================================================================
# HTH GitHub Control 5.02: Enable Delete Branch on Merge
# Profile Level: L2 (Hardened)
# Frameworks: NIST CM-3
# Source: https://howtoharden.com/guides/github/#52-delete-branches-on-merge
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_repository" "how_to_harden" {
  name                   = var.repository_name
  delete_branch_on_merge = true
}
# HTH Guide Excerpt: end terraform
