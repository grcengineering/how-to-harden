# =============================================================================
# HTH GitHub Control 3.05: Enable Code Scanning (Default Setup)
# Profile Level: L2 (Hardened)
# Frameworks: NIST SA-11, SI-7
# Source: https://howtoharden.com/guides/github/#35-enable-code-scanning
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_repository" "how_to_harden_code_scanning" {
  name = var.repository_name

  security_and_analysis {
    advanced_security {
      status = "enabled"
    }
  }
}
# HTH Guide Excerpt: end terraform
