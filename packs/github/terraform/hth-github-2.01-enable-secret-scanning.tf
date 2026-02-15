# =============================================================================
# HTH GitHub Control 2.01: Enable Secret Scanning
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5(7), SC-28
# Source: https://howtoharden.com/guides/github/#21-enable-secret-scanning
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_repository" "how_to_harden_secrets" {
  name = var.repository_name

  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"
    }
  }
}
# HTH Guide Excerpt: end terraform
