# =============================================================================
# HTH GitHub Control 2.03: Enable Secret Scanning Non-Provider Patterns
# Profile Level: L3 (Maximum Security)
# Frameworks: NIST IA-5, SC-28
# Source: https://howtoharden.com/guides/github/#23-secret-scanning-non-provider-patterns
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_repository" "how_to_harden_non_provider" {
  name = var.repository_name

  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_non_provider_patterns {
      status = "enabled"
    }
  }
}
# HTH Guide Excerpt: end terraform
