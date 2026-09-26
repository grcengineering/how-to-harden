# =============================================================================
# HTH GitHub Control 2.02: Enable Dependabot Alerts and Security Updates
# Profile Level: L1 (Crawl)
# Frameworks: NIST RA-5, SI-2
# Source: https://howtoharden.com/guides/github/#22-enable-security-features-dependabot-code-scanning-secret-scanning
#
# Uses the dedicated per-setting resources, so the pack never creates,
# replaces, or deletes the repository itself.
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_repository_vulnerability_alerts" "how_to_harden" {
  repository = var.repository_name
  enabled    = true
}

resource "github_repository_dependabot_security_updates" "how_to_harden" {
  repository = var.repository_name
  enabled    = true

  depends_on = [github_repository_vulnerability_alerts.how_to_harden]
}
# HTH Guide Excerpt: end terraform
