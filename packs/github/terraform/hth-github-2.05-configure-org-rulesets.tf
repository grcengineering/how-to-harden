# =============================================================================
# HTH GitHub Control 2.05: Configure Organization Rulesets
# Profile Level: L2 (Hardened)
# Frameworks: NIST CM-3
# Source: https://howtoharden.com/guides/github/#23-configure-repository-rulesets
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_organization_ruleset" "production_branch_protection" {
  name        = "Production Branch Protection"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH", "refs/heads/release/*"]
      exclude = []
    }
  }

  rules {
    deletion                = true
    non_fast_forward        = true
    required_signatures     = true

    pull_request {
      required_approving_review_count   = 2
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = true
      require_last_push_approval        = true
    }
  }
}
# HTH Guide Excerpt: end terraform
