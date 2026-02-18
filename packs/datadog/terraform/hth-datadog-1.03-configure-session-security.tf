# =============================================================================
# HTH Datadog Control 1.3: Configure Session Security
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.2, NIST AC-12
# Source: https://howtoharden.com/guides/datadog/#13-configure-session-security
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure session security via security monitoring rule that detects
# sessions exceeding the configured idle timeout.
#
# NOTE: Datadog does not expose session timeout as a direct Terraform resource.
# Session duration is configured via Organization Settings in the UI.
# This rule monitors for sessions that exceed the idle timeout threshold
# and alerts the security team for investigation.
resource "datadog_security_monitoring_rule" "session_idle_timeout_violation" {
  name    = "[HTH] Session Idle Timeout Violation Detected"
  enabled = true
  type    = "log_detection"

  message = <<-EOT
    ## Session Idle Timeout Violation

    A user session has been active beyond the configured idle timeout
    of ${var.session_idle_timeout_minutes} minutes.

    **Recommended Action:**
    - Review session in Organization Settings > Security
    - Verify idle timeout is set to ${var.session_idle_timeout_minutes} minutes
    - Investigate if the session was legitimately active

    **HTH Control:** 1.3 Configure Session Security
    **Profile Level:** L1 (Baseline)

    ${length(var.audit_alert_recipients) > 0 ? join(" ", var.audit_alert_recipients) : ""}
  EOT

  query {
    name            = "session_violation"
    query           = "source:audit @evt.name:session @duration:>${var.session_idle_timeout_minutes}m"
    aggregation     = "count"
    group_by_fields = ["@usr.email"]
  }

  case {
    name      = "Session idle timeout exceeded"
    status    = "medium"
    condition = "session_violation > 0"
  }

  options {
    detection_method       = "threshold"
    evaluation_window      = 900
    keep_alive             = 3600
    max_signal_duration    = 86400
    decrease_criticality_based_on_env = false
  }

  tags = ["source:hth", "control:1.3", "level:L1"]
}
# HTH Guide Excerpt: end terraform
