# =============================================================================
# HTH Datadog Control 3.1: Secure API Keys
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.11, NIST SC-12
# Source: https://howtoharden.com/guides/datadog/#31-secure-api-keys
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create purpose-specific API keys with descriptive names.
# Each key should map to a single use case (e.g., prod-agent, staging-agent).
resource "datadog_api_key" "managed" {
  for_each = toset(var.api_key_names)

  name = each.value
}

# Security monitoring rule: detect API key creation or deletion
resource "datadog_security_monitoring_rule" "api_key_lifecycle" {
  name    = "[HTH] API Key Created or Deleted"
  enabled = true
  type    = "log_detection"

  message = <<-EOT
    ## API Key Lifecycle Event

    An API key was created or deleted. All API key changes should be
    authorized and documented per key management policy.

    **Recommended Action:**
    - Verify the change was authorized
    - Confirm the key name follows naming conventions
    - Update key inventory documentation
    - Ensure unused keys are revoked

    **HTH Control:** 3.1 Secure API Keys
    **Profile Level:** L1 (Baseline)

    ${length(var.audit_alert_recipients) > 0 ? join(" ", var.audit_alert_recipients) : ""}
  EOT

  query {
    name            = "api_key_change"
    query           = "source:audit @evt.name:api_key @action:(created OR deleted)"
    aggregation     = "count"
    group_by_fields = ["@usr.email"]
  }

  case {
    name      = "API key lifecycle event"
    status    = "medium"
    condition = "api_key_change > 0"
  }

  options {
    detection_method       = "threshold"
    evaluation_window      = 300
    keep_alive             = 3600
    max_signal_duration    = 86400
    decrease_criticality_based_on_env = false
  }

  tags = ["source:hth", "control:3.1", "level:L1"]
}
# HTH Guide Excerpt: end terraform
