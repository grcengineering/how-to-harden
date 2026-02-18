# =============================================================================
# HTH Snyk Control 2.2: SCM Integration Security
# Profile Level: L1 (Baseline)
# Frameworks: NIST CM-7, SOC 2 CC6.6, CC8.1, ISO 27001 A.9.4, PCI DSS 8.3
# Source: https://howtoharden.com/guides/snyk/#22-scm-integration-security
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure SCM integration with least-privilege repository access.
# Limit Snyk's access to only the repositories that require scanning.
# For Enterprise customers, use Snyk Broker to keep code on-premises.

resource "snyk_integration" "scm" {
  organization_id = var.snyk_org_id
  type            = var.scm_integration_type
}

# Broker configuration for private repository scanning (Enterprise).
# Snyk Broker acts as a proxy between Snyk and your SCM, ensuring
# source code never leaves your network perimeter.
resource "snyk_integration" "broker" {
  count = var.broker_enabled ? 1 : 0

  organization_id = var.snyk_org_id
  type            = "${var.scm_integration_type}-broker"

  # Broker token must be provisioned via Snyk web console first.
  # The accept.json filter file controls which API endpoints the
  # Broker client will proxy -- restrict to minimum required:
  #   - Repository file access (for scanning)
  #   - Webhook management (for auto-scanning on push)
  #   - Pull request status (for PR checks)
}
# HTH Guide Excerpt: end terraform
