# =============================================================================
# HTH Okta Control 1.11: Enable End-User Security Notifications
# Profile Level: L1 (Baseline)
# Frameworks: NIST SI-4, IR-6
# Source: https://howtoharden.com/guides/okta/#111-enable-end-user-security-notifications
# =============================================================================

# Org-level configuration for end-user support
resource "okta_org_configuration" "notifications" {
  end_user_support_help_url = var.support_url

  # End-user notification settings are managed via the org settings API.
  # Use the provisioners below for full control.
}

# Enable Suspicious Activity Reporting via API call
# (Not all org-level settings are natively supported in Terraform)
resource "null_resource" "enable_suspicious_activity_reporting" {
  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X POST "https://${var.okta_domain}/api/v1/org/privacy/suspicious-activity-reporting" \
        -H "Authorization: SSWS ${var.okta_api_token}" \
        -H "Content-Type: application/json" \
        -d '{"enabled": true}'
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}

# Enable all end-user notification types via API call
resource "null_resource" "enable_end_user_notifications" {
  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X PUT "https://${var.okta_domain}/api/v1/org/settings" \
        -H "Authorization: SSWS ${var.okta_api_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "endUserNotifications": {
            "newSignOnNotification": {"enabled": true},
            "authenticatorEnrolledNotification": {"enabled": true},
            "authenticatorResetNotification": {"enabled": true},
            "passwordChangedNotification": {"enabled": true},
            "factorResetNotification": {"enabled": true}
          }
        }'
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}
