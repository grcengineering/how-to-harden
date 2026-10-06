# =============================================================================
# HTH GitHub Control 1.01: Enforce Two-Factor Authentication (audit)
# Profile Level: L1 (Crawl)
# Frameworks: NIST IA-2(1), IA-2(2)
# Source: https://howtoharden.com/guides/github/#11-enforce-multi-factor-authentication-mfa-for-all-organization-members
#
# The integrations/github provider has no argument that turns ON the
# organization 2FA requirement (github_organization_settings exposes none),
# and the REST "Update an organization" endpoint accepts no such field.
# Enabling it is ClickOps only; this pack AUDITS it and fails the plan when
# the requirement is off.
# =============================================================================

# HTH Guide Excerpt: begin terraform
data "github_organization" "hth_2fa" {
  name         = var.github_organization
  summary_only = true
}

check "hth_2fa_required" {
  assert {
    condition     = data.github_organization.hth_2fa.two_factor_requirement_enabled
    error_message = "Organization ${var.github_organization} does not require two-factor authentication. Enable it under Settings -> Authentication security."
  }
}
# HTH Guide Excerpt: end terraform
