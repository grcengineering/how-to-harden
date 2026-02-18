# =============================================================================
# HTH Snyk Control 1.1: Enforce SSO with MFA
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-2(1), SOC 2 CC6.1, ISO 27001 A.9.2, PCI DSS 8.3
# Source: https://howtoharden.com/guides/snyk/#11-enforce-sso-with-mfa
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure organization SSO enforcement
# Note: SAML SSO configuration requires Business/Enterprise plan and
# must be initially configured via the Snyk web console. This resource
# enforces the SSO requirement after initial IdP setup.
resource "snyk_organization" "sso_enforcement" {
  id   = var.snyk_org_id
  name = data.snyk_organization.current.name

  # Enforce SSO for all organization members
  request_access = {
    enabled = var.sso_enabled
  }

  lifecycle {
    ignore_changes = [name]
  }
}

# Data source to read current org settings without overwriting
data "snyk_organization" "current" {
  id = var.snyk_org_id
}
# HTH Guide Excerpt: end terraform
