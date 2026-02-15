# =============================================================================
# HTH GitHub Control 2.02: Enable Dependabot Security Updates
# Profile Level: L1 (Baseline)
# Frameworks: NIST RA-5, SI-2
# Source: https://howtoharden.com/guides/github/#22-enable-dependabot-security-updates
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_repository" "how_to_harden_dependabot" {
  name               = var.repository_name
  vulnerability_alerts = true
}
# HTH Guide Excerpt: end terraform
