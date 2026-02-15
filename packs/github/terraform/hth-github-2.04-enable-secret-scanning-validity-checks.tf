# =============================================================================
# HTH GitHub Control 2.04: Enable Secret Scanning Validity Checks
# Profile Level: L3 (Maximum Security)
# Frameworks: NIST IA-5, SI-4
# Source: https://howtoharden.com/guides/github/#24-secret-scanning-validity-checks
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_repository" "how_to_harden_validity" {
  name = var.repository_name

  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_validity_checks {
      status = "enabled"
    }
  }
}
# HTH Guide Excerpt: end terraform
