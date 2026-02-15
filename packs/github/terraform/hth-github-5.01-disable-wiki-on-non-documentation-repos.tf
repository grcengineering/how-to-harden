# =============================================================================
# HTH GitHub Control 5.01: Disable Wiki on Non-Documentation Repos
# Profile Level: L2 (Hardened)
# Frameworks: NIST CM-7
# Source: https://howtoharden.com/guides/github/#51-disable-unused-wikis
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_repository" "how_to_harden_wiki" {
  name     = var.repository_name
  has_wiki = false
}
# HTH Guide Excerpt: end terraform
