# =============================================================================
# HTH Jamf Pro Control 1.2: Secure API Access
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.11, NIST SC-12
# Source: https://howtoharden.com/guides/jamf/#12-secure-api-access
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Dedicated API role with read-only privileges for security automation
resource "jamfpro_api_role" "security_automation" {
  display_name = "HTH Security Automation"
  privileges   = toset(var.api_integration_privileges)
}

# API integration with dedicated OAuth2 credentials and scoped privileges
resource "jamfpro_api_integration" "security_automation" {
  display_name         = var.api_integration_name
  enabled              = true
  authorization_scopes = toset(var.api_integration_privileges)
}

# L2: Restricted API integration with tighter token lifetime
resource "jamfpro_api_integration" "security_automation_hardened" {
  count = var.profile_level >= 2 ? 1 : 0

  display_name                   = "${var.api_integration_name} (Hardened)"
  enabled                        = true
  access_token_lifetime_seconds  = 1800
  authorization_scopes           = toset(var.api_integration_privileges)
}
# HTH Guide Excerpt: end terraform
