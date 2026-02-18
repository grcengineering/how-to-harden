# =============================================================================
# HTH Datadog Control 2.1: Configure Role-Based Access Control
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6
# Source: https://howtoharden.com/guides/datadog/#21-configure-role-based-access-control
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Look up the built-in Datadog Read Only role for reference
data "datadog_role" "read_only" {
  filter = "Datadog Read Only Role"
}

# Look up the built-in Datadog Standard role for reference
data "datadog_role" "standard" {
  filter = "Datadog Standard Role"
}

# Look up the built-in Datadog Admin role for reference
data "datadog_role" "admin" {
  filter = "Datadog Admin Role"
}

# Create custom least-privilege roles from variable definitions
resource "datadog_role" "custom" {
  for_each = var.custom_roles

  name = each.value.name

  dynamic "permission" {
    for_each = each.value.permissions
    content {
      id = permission.value
    }
  }
}

# Security monitoring rule: detect admin role assignments
resource "datadog_security_monitoring_rule" "admin_role_assignment" {
  name    = "[HTH] Admin Role Assigned to User"
  enabled = true
  type    = "log_detection"

  message = <<-EOT
    ## Admin Role Assignment Detected

    A user has been assigned the Datadog Admin role. Admin access should
    be limited to 2-3 users per the principle of least privilege.

    **Recommended Action:**
    - Verify the assignment was authorized
    - Confirm the user requires full admin access
    - Consider using a custom role with fewer permissions

    **HTH Control:** 2.1 Configure Role-Based Access Control / 2.2 Limit Admin Access
    **Profile Level:** L1 (Baseline)

    ${length(var.audit_alert_recipients) > 0 ? join(" ", var.audit_alert_recipients) : ""}
  EOT

  query {
    name            = "admin_assignment"
    query           = "source:audit @evt.name:role @action:modified @role.name:\"Datadog Admin Role\""
    aggregation     = "count"
    group_by_fields = ["@usr.email"]
  }

  case {
    name      = "Admin role assigned"
    status    = "high"
    condition = "admin_assignment > 0"
  }

  options {
    detection_method       = "threshold"
    evaluation_window      = 300
    keep_alive             = 3600
    max_signal_duration    = 86400
    decrease_criticality_based_on_env = false
  }

  tags = ["source:hth", "control:2.1", "control:2.2", "level:L1"]
}
# HTH Guide Excerpt: end terraform
