# =============================================================================
# HTH Okta Control 1.11: Enable End-User Security Notifications
# Profile Level: L1 (Crawl)
# Frameworks: NIST SI-4, IR-6
# Source: https://howtoharden.com/guides/okta/#111-enable-end-user-security-notifications
#
# okta_security_notification_emails (okta/okta provider) manages the four
# notification emails and "Report suspicious activity via email" shown under
# Security > General > Security notification emails. Okta's public Management
# API documents no endpoint for these settings; the provider documents that
# this resource calls an internal Okta endpoint and works only with an SSWS
# API token in the provider configuration, not OAuth 2.0.
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "okta_security_notification_emails" "end_user_notifications" {
  send_email_for_new_device_enabled        = true
  send_email_for_password_changed_enabled  = true
  send_email_for_factor_enrollment_enabled = true
  send_email_for_factor_reset_enabled      = true
  report_suspicious_activity_enabled       = true
}
# HTH Guide Excerpt: end terraform
