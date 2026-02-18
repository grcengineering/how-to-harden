# =============================================================================
# HTH Datadog Control 3.2: Secure Application Keys
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.11, NIST SC-12
# Source: https://howtoharden.com/guides/datadog/#32-secure-application-keys
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create purpose-specific application keys with descriptive names.
# Application keys inherit the permissions of the user who creates them.
# Use service accounts with limited roles for automation keys.
resource "datadog_application_key" "managed" {
  for_each = toset(var.app_key_names)

  name = each.value
}

# Security monitoring rule: detect application key creation or deletion
resource "datadog_security_monitoring_rule" "app_key_lifecycle" {
  name    = "[HTH] Application Key Created or Deleted"
  enabled = true
  type    = "log_detection"

  message = <<-EOT
    ## Application Key Lifecycle Event

    An application key was created or deleted. Application keys inherit
    the permissions of the creating user, so changes must be carefully
    controlled. Keys should be rotated every 90 days.

    **Recommended Action:**
    - Verify the change was authorized
    - Confirm the key is tied to an appropriate service account
    - Check that the owning user has minimal required permissions
    - Update key rotation schedule

    **HTH Control:** 3.2 Secure Application Keys
    **Profile Level:** L1 (Baseline)

    ${length(var.audit_alert_recipients) > 0 ? join(" ", var.audit_alert_recipients) : ""}
  EOT

  query {
    name            = "app_key_change"
    query           = "source:audit @evt.name:application_key @action:(created OR deleted)"
    aggregation     = "count"
    group_by_fields = ["@usr.email"]
  }

  case {
    name      = "Application key lifecycle event"
    status    = "medium"
    condition = "app_key_change > 0"
  }

  options {
    detection_method       = "threshold"
    evaluation_window      = 300
    keep_alive             = 3600
    max_signal_duration    = 86400
    decrease_criticality_based_on_env = false
  }

  tags = ["source:hth", "control:3.2", "level:L1"]
}
# HTH Guide Excerpt: end terraform
