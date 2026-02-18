# =============================================================================
# HTH Jamf Pro Control 4.1: Enable Audit Logging
# Profile Level: L1 (Baseline)
# Frameworks: CIS 8.2, NIST AU-2
# Source: https://howtoharden.com/guides/jamf/#41-enable-audit-logging
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Webhook for admin login events to SIEM
resource "jamfpro_webhook" "admin_login" {
  count = var.siem_webhook_url != "" ? 1 : 0

  name                = "HTH Audit - Admin Login"
  enabled             = true
  url                 = var.siem_webhook_url
  content_type        = "application/json"
  event               = "JSSLoginSuccess"
  connection_timeout  = 5
  read_timeout        = 10
  authentication_type = var.siem_webhook_auth_type
  username            = var.siem_webhook_username
  password            = var.siem_webhook_password
}

# Webhook for computer policy changes
resource "jamfpro_webhook" "policy_change" {
  count = var.siem_webhook_url != "" ? 1 : 0

  name                = "HTH Audit - Policy Change"
  enabled             = true
  url                 = var.siem_webhook_url
  content_type        = "application/json"
  event               = "PolicyFinished"
  connection_timeout  = 5
  read_timeout        = 10
  authentication_type = var.siem_webhook_auth_type
  username            = var.siem_webhook_username
  password            = var.siem_webhook_password
}

# Webhook for computer enrollment events
resource "jamfpro_webhook" "computer_enrollment" {
  count = var.siem_webhook_url != "" ? 1 : 0

  name                = "HTH Audit - Computer Enrollment"
  enabled             = true
  url                 = var.siem_webhook_url
  content_type        = "application/json"
  event               = "ComputerAdded"
  connection_timeout  = 5
  read_timeout        = 10
  authentication_type = var.siem_webhook_auth_type
  username            = var.siem_webhook_username
  password            = var.siem_webhook_password
}

# Webhook for computer check-in events (L2+)
resource "jamfpro_webhook" "computer_checkin" {
  count = var.siem_webhook_url != "" && var.profile_level >= 2 ? 1 : 0

  name                = "HTH Audit - Computer Check-In"
  enabled             = true
  url                 = var.siem_webhook_url
  content_type        = "application/json"
  event               = "ComputerCheckIn"
  connection_timeout  = 5
  read_timeout        = 10
  authentication_type = var.siem_webhook_auth_type
  username            = var.siem_webhook_username
  password            = var.siem_webhook_password
}

# Webhook for push command sent events (L2+)
resource "jamfpro_webhook" "push_sent" {
  count = var.siem_webhook_url != "" && var.profile_level >= 2 ? 1 : 0

  name                = "HTH Audit - Push Sent"
  enabled             = true
  url                 = var.siem_webhook_url
  content_type        = "application/json"
  event               = "PushSent"
  connection_timeout  = 5
  read_timeout        = 10
  authentication_type = var.siem_webhook_auth_type
  username            = var.siem_webhook_username
  password            = var.siem_webhook_password
}

# Webhook for mobile device enrollment events (L2+)
resource "jamfpro_webhook" "mobile_enrollment" {
  count = var.siem_webhook_url != "" && var.profile_level >= 2 ? 1 : 0

  name                = "HTH Audit - Mobile Device Enrollment"
  enabled             = true
  url                 = var.siem_webhook_url
  content_type        = "application/json"
  event               = "MobileDeviceEnrolled"
  connection_timeout  = 5
  read_timeout        = 10
  authentication_type = var.siem_webhook_auth_type
  username            = var.siem_webhook_username
  password            = var.siem_webhook_password
}
# HTH Guide Excerpt: end terraform
