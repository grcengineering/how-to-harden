# =============================================================================
# HTH OneLogin Control 5.2: Configure Security Alerts
# Profile Level: L1 (Baseline)
# Frameworks: CIS 8.11, NIST SI-4
# Source: https://howtoharden.com/guides/onelogin/#52-configure-security-alerts
#
# NOTE: OneLogin alert configuration is primarily done through the admin
# console (Settings > Alerts). This control provisions event webhook
# rules for automated alerting on security-relevant events.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Alert webhook for multiple failed login attempts
resource "onelogin_event_webhook" "failed_login_alerts" {
  count = var.siem_webhook_url != "" ? 1 : 0

  name    = "HTH Failed Login Alerts"
  url     = var.siem_webhook_url
  enabled = true

  event_type_ids = [
    2,   # User login failed
    7,   # User locked out
    21,  # Admin login failed
  ]
}

# Alert webhook for admin privilege changes
resource "onelogin_event_webhook" "privilege_change_alerts" {
  count = var.siem_webhook_url != "" ? 1 : 0

  name    = "HTH Privilege Change Alerts"
  url     = var.siem_webhook_url
  enabled = true

  event_type_ids = [
    60,  # Privilege granted
    61,  # Privilege revoked
    50,  # Role created
    51,  # Role updated
    52,  # Role deleted
    30,  # Policy created
    31,  # Policy updated
    32,  # Policy deleted
  ]
}

# L2+ alert for unusual login patterns
resource "onelogin_event_webhook" "anomaly_alerts" {
  count = var.profile_level >= 2 && var.siem_webhook_url != "" ? 1 : 0

  name    = "HTH Login Anomaly Alerts"
  url     = var.siem_webhook_url
  enabled = true

  event_type_ids = [
    2,   # User login failed
    7,   # User locked out
    14,  # User MFA enrolled
    15,  # User MFA removed
    21,  # Admin login failed
  ]
}
# HTH Guide Excerpt: end terraform
