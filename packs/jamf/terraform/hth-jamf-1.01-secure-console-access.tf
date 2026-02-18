# =============================================================================
# HTH Jamf Pro Control 1.1: Secure Jamf Pro Console Access
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6(1)
# Source: https://howtoharden.com/guides/jamf/#11-secure-jamf-pro-console-access
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create granular API roles for least-privilege access

# Help Desk role: device lookup and basic read-only actions
resource "jamfpro_api_role" "helpdesk" {
  display_name = "HTH Help Desk"
  privileges   = toset(var.helpdesk_privileges)
}

# Deployment role: profile and app management
resource "jamfpro_api_role" "deployment" {
  display_name = "HTH Deployment"
  privileges   = toset(var.deployment_privileges)
}

# Security role: full security policy access
resource "jamfpro_api_role" "security" {
  display_name = "HTH Security"
  privileges   = toset(var.security_privileges)
}

# Dedicated Help Desk account with minimum privileges
resource "jamfpro_account" "helpdesk" {
  name          = "hth-helpdesk"
  enabled       = "Enabled"
  access_level  = "Full Access"
  privilege_set = "Custom"

  jss_objects_privileges = toset(var.helpdesk_privileges)
}

# Dedicated Deployment account
resource "jamfpro_account" "deployment" {
  name          = "hth-deployment"
  enabled       = "Enabled"
  access_level  = "Full Access"
  privilege_set = "Custom"

  jss_objects_privileges = toset(var.deployment_privileges)
}
# HTH Guide Excerpt: end terraform
