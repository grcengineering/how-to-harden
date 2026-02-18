# =============================================================================
# HTH Datadog Control 4.1: Configure Audit Logs
# Profile Level: L1 (Baseline)
# Frameworks: CIS 8.2, NIST AU-2
# Source: https://howtoharden.com/guides/datadog/#41-configure-audit-logs
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Monitor for organization settings changes (security-critical events)
resource "datadog_security_monitoring_rule" "org_settings_changed" {
  name    = "[HTH] Organization Settings Modified"
  enabled = true
  type    = "log_detection"

  message = <<-EOT
    ## Organization Settings Modified

    A change was detected to Datadog organization settings. This includes
    changes to authentication methods, security settings, and access controls.

    **Recommended Action:**
    - Review the specific setting that was changed
    - Verify the change was authorized via change management
    - Check if the change impacts security posture
    - Document in change log

    **HTH Control:** 4.1 Configure Audit Logs
    **Profile Level:** L1 (Baseline)

    ${length(var.audit_alert_recipients) > 0 ? join(" ", var.audit_alert_recipients) : ""}
  EOT

  query {
    name            = "org_change"
    query           = "source:audit @evt.name:org_settings @action:modified"
    aggregation     = "count"
    group_by_fields = ["@usr.email"]
  }

  case {
    name      = "Organization settings modified"
    status    = "high"
    condition = "org_change > 0"
  }

  options {
    detection_method       = "threshold"
    evaluation_window      = 300
    keep_alive             = 3600
    max_signal_duration    = 86400
    decrease_criticality_based_on_env = false
  }

  tags = ["source:hth", "control:4.1", "level:L1"]
}

# Monitor for user access changes (invitation, role change, removal)
resource "datadog_security_monitoring_rule" "user_access_changed" {
  name    = "[HTH] User Access Modified"
  enabled = true
  type    = "log_detection"

  message = <<-EOT
    ## User Access Modified

    A user was invited, had their role changed, or was removed from the
    Datadog organization. User access changes should follow the principle
    of least privilege.

    **Recommended Action:**
    - Verify the user access change was authorized
    - Confirm the assigned role follows least privilege
    - Update user access inventory
    - Review if the user needs a custom role instead

    **HTH Control:** 4.1 Configure Audit Logs
    **Profile Level:** L1 (Baseline)

    ${length(var.audit_alert_recipients) > 0 ? join(" ", var.audit_alert_recipients) : ""}
  EOT

  query {
    name            = "user_change"
    query           = "source:audit @evt.name:user @action:(created OR modified OR deleted)"
    aggregation     = "count"
    group_by_fields = ["@usr.email"]
  }

  case {
    name      = "User access modified"
    status    = "medium"
    condition = "user_change > 0"
  }

  options {
    detection_method       = "threshold"
    evaluation_window      = 300
    keep_alive             = 3600
    max_signal_duration    = 86400
    decrease_criticality_based_on_env = false
  }

  tags = ["source:hth", "control:4.1", "level:L1"]
}

# L2: Monitor for SAML configuration changes
resource "datadog_security_monitoring_rule" "saml_config_changed" {
  count   = var.profile_level >= 2 ? 1 : 0
  name    = "[HTH] SAML Configuration Modified"
  enabled = true
  type    = "log_detection"

  message = <<-EOT
    ## SAML Configuration Modified

    A change was detected to the SAML/SSO configuration. Unauthorized
    changes to SAML settings can enable authentication bypass attacks.

    **Recommended Action:**
    - Immediately verify the change was authorized
    - Check if SAML strict mode is still enabled
    - Verify IdP metadata has not been tampered with
    - Review login methods for unauthorized additions

    **HTH Control:** 4.1 Configure Audit Logs (SAML monitoring)
    **Profile Level:** L2 (Hardened)

    ${length(var.audit_alert_recipients) > 0 ? join(" ", var.audit_alert_recipients) : ""}
  EOT

  query {
    name            = "saml_change"
    query           = "source:audit @evt.name:saml @action:modified"
    aggregation     = "count"
    group_by_fields = ["@usr.email"]
  }

  case {
    name      = "SAML configuration modified"
    status    = "critical"
    condition = "saml_change > 0"
  }

  options {
    detection_method       = "threshold"
    evaluation_window      = 300
    keep_alive             = 3600
    max_signal_duration    = 86400
    decrease_criticality_based_on_env = false
  }

  tags = ["source:hth", "control:4.1", "level:L2"]
}
# HTH Guide Excerpt: end terraform
