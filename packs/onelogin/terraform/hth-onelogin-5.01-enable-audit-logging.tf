# =============================================================================
# HTH OneLogin Control 5.1: Enable Audit Logging
# Profile Level: L1 (Baseline)
# Frameworks: CIS 8.2, NIST AU-2
# Source: https://howtoharden.com/guides/onelogin/#51-enable-audit-logging
#
# NOTE: OneLogin audit logs are enabled by default. This control configures
# SIEM integration for log export and centralized monitoring.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Event webhook for SIEM integration -- exports security events
resource "onelogin_event_webhook" "siem_export" {
  count = var.siem_webhook_url != "" ? 1 : 0

  name    = "HTH SIEM Log Export"
  url     = var.siem_webhook_url
  enabled = true

  # Key security events to forward
  event_type_ids = [
    1,   # User login
    2,   # User login failed
    5,   # User password changed
    6,   # User password reset
    7,   # User locked out
    8,   # User unlocked
    10,  # User created
    11,  # User deleted
    12,  # User updated
    14,  # User MFA enrolled
    15,  # User MFA removed
    20,  # Admin login
    21,  # Admin login failed
    30,  # Policy created
    31,  # Policy updated
    32,  # Policy deleted
    40,  # App created
    41,  # App updated
    42,  # App deleted
    50,  # Role created
    51,  # Role updated
    52,  # Role deleted
    60,  # Privilege granted
    61,  # Privilege revoked
  ]
}

# L2+ additional webhook for high-severity events (separate alerting channel)
resource "onelogin_event_webhook" "critical_alerts" {
  count = var.profile_level >= 2 && var.siem_webhook_url != "" ? 1 : 0

  name    = "HTH Critical Security Alerts"
  url     = var.siem_webhook_url
  enabled = true

  # Only high-severity events for immediate alerting
  event_type_ids = [
    2,   # User login failed
    7,   # User locked out
    21,  # Admin login failed
    31,  # Policy updated
    32,  # Policy deleted
    61,  # Privilege revoked
  ]
}
# HTH Guide Excerpt: end terraform
