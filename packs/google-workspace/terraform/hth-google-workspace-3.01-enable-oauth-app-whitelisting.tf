# =============================================================================
# HTH Google Workspace Control 3.1: Enable OAuth App Whitelisting
# Profile Level: L1 (Baseline)
# Frameworks: CIS 2.5, NIST AC-3/CM-7, CIS Google Workspace 2.1
# Source: https://howtoharden.com/guides/google-workspace/#31-enable-oauth-app-whitelisting
# =============================================================================

# HTH Guide Excerpt: begin terraform
# The googleworkspace provider does not directly manage the OAuth app
# allowlist/blocklist setting.  These resources create the organizational
# infrastructure for OAuth governance:
#
# 1. A group to track approved apps and their owners
# 2. An OU for users with restricted OAuth access
# 3. Documentation of the manual Admin Console steps required
#
# Full API-level control requires GAM or the Admin SDK.

# Group for OAuth app governance -- members are app owners/reviewers
resource "googleworkspace_group" "oauth_reviewers" {
  email       = "oauth-app-reviewers@${var.primary_domain}"
  name        = "OAuth App Reviewers"
  description = "HTH 3.1 -- Members review and approve third-party OAuth app requests"
}

# Group to receive notifications about blocked OAuth app access attempts
resource "googleworkspace_group" "oauth_blocked_alerts" {
  email       = "oauth-blocked-alerts@${var.primary_domain}"
  name        = "OAuth Blocked App Alerts"
  description = "HTH 3.1 -- Receives alerts when users attempt to authorize blocked OAuth apps"
}

# OU for users with strictly no third-party OAuth access (high-security users)
resource "googleworkspace_org_unit" "oauth_restricted" {
  count = var.profile_level >= 2 ? 1 : 0

  name                 = "OAuth Restricted Users"
  description          = "HTH 3.1 L2 -- Users in this OU cannot authorize any third-party OAuth apps"
  parent_org_unit_path = var.target_org_unit_path
}

# Retrieve the domain to verify it exists before creating domain-level resources
data "googleworkspace_domain" "primary" {
  domain_name = var.primary_domain
}
# HTH Guide Excerpt: end terraform
