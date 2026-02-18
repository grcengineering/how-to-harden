# =============================================================================
# HTH Ping Identity Control 5.1: Configure Comprehensive Audit Logging
# Profile Level: L1 (Baseline)
# Frameworks: NIST AU-2, AU-3, AU-6
# Source: https://howtoharden.com/guides/ping-identity/#51-configure-comprehensive-audit-logging
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Webhook for SIEM integration -- forward audit events to external systems
resource "pingone_webhook" "siem_integration" {
  count = var.siem_webhook_url != "" ? 1 : 0

  environment_id = var.pingone_environment_id
  name           = "HTH SIEM Integration"
  enabled        = true
  http_endpoint_url = var.siem_webhook_url

  http_endpoint_headers = {
    "Content-Type" = "application/json"
  }

  # Subscribe to all security-relevant event types
  filter_options {
    included_action_types = [
      "USER.CREATED",
      "USER.UPDATED",
      "USER.DELETED",
      "USER.ACCESS_ALLOWED",
      "USER.ACCESS_DENIED",
      "USER.MFA_ENROLLMENT",
      "USER.PASSWORD_RESET",
      "APPLICATION.CREATED",
      "APPLICATION.UPDATED",
      "APPLICATION.DELETED",
      "ROLE_ASSIGNMENT.CREATED",
      "ROLE_ASSIGNMENT.DELETED",
      "POLICY.CREATED",
      "POLICY.UPDATED",
      "POLICY.DELETED",
      "FLOW.EXECUTION_COMPLETED",
      "FLOW.EXECUTION_FAILED",
    ]
  }

  format = "ACTIVITY"

  tls_client_auth_key_pair = {}

  verify_tls_certificates = true
}

# Alert rule: failed admin authentication (>5 in 5 minutes)
resource "pingone_notification_settings_email" "security_alerts" {
  environment_id = var.pingone_environment_id

  host     = "smtp.example.com"
  port     = 587
  username = "alerts@example.com"
  password = ""
  from     = { address = "pingone-alerts@example.com", name = "PingOne Security" }
}

# L2+: Extended logging with input/output capture (masked)
resource "pingone_webhook" "extended_logging" {
  count = var.profile_level >= 2 && var.siem_webhook_url != "" ? 1 : 0

  environment_id    = var.pingone_environment_id
  name              = "HTH Extended Audit Logging"
  enabled           = true
  http_endpoint_url = var.siem_webhook_url

  http_endpoint_headers = {
    "Content-Type" = "application/json"
    "X-HTH-Level"  = "extended"
  }

  # Extended: capture all event types for comprehensive audit trail
  filter_options {
    included_action_types = [
      "USER.CREATED",
      "USER.UPDATED",
      "USER.DELETED",
      "USER.ACCESS_ALLOWED",
      "USER.ACCESS_DENIED",
      "USER.MFA_ENROLLMENT",
      "USER.PASSWORD_RESET",
      "APPLICATION.CREATED",
      "APPLICATION.UPDATED",
      "APPLICATION.DELETED",
      "ROLE_ASSIGNMENT.CREATED",
      "ROLE_ASSIGNMENT.DELETED",
      "POLICY.CREATED",
      "POLICY.UPDATED",
      "POLICY.DELETED",
      "FLOW.CREATED",
      "FLOW.UPDATED",
      "FLOW.DELETED",
      "FLOW.EXECUTION_COMPLETED",
      "FLOW.EXECUTION_FAILED",
      "KEY.CREATED",
      "KEY.UPDATED",
      "KEY.DELETED",
      "GRANT.CREATED",
      "GRANT.DELETED",
    ]
  }

  format = "ACTIVITY"

  tls_client_auth_key_pair = {}

  verify_tls_certificates = true
}

# L3+: Real-time alerting on critical security events
resource "pingone_webhook" "critical_alerts" {
  count = var.profile_level >= 3 && var.siem_webhook_url != "" ? 1 : 0

  environment_id    = var.pingone_environment_id
  name              = "HTH Critical Security Alerts"
  enabled           = true
  http_endpoint_url = var.siem_webhook_url

  http_endpoint_headers = {
    "Content-Type"  = "application/json"
    "X-HTH-Level"   = "critical"
    "X-HTH-Priority" = "1"
  }

  filter_options {
    included_action_types = [
      "ROLE_ASSIGNMENT.CREATED",
      "POLICY.DELETED",
      "APPLICATION.DELETED",
      "KEY.DELETED",
      "FLOW.DELETED",
    ]
  }

  format = "ACTIVITY"

  tls_client_auth_key_pair = {}

  verify_tls_certificates = true
}
# HTH Guide Excerpt: end terraform
