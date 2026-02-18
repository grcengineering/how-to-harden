# =============================================================================
# HTH Zscaler Control 3.1: Configure Application Segments
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-4, SC-7 | CIS 6.4
# Source: https://howtoharden.com/guides/zscaler/#31-configure-application-segments
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Segment group to organize applications by security classification
resource "zpa_segment_group" "hardened" {
  name            = var.segment_group_name
  description     = "HTH-managed segment group for hardened application access"
  enabled         = true
  policy_migrated = true
}

# Application segments -- define what internal apps are accessible via ZPA
resource "zpa_application_segment" "apps" {
  for_each = { for idx, app in var.application_segments : app.name => app }

  name             = each.value.name
  description      = each.value.description
  enabled          = true
  health_reporting = "ON_ACCESS"
  bypass_type      = "NEVER"
  is_cname_enabled = true

  segment_group_id = zpa_segment_group.hardened.id

  domain_names = each.value.domain_names

  dynamic "tcp_port_range" {
    for_each = each.value.tcp_port_range
    content {
      from = tcp_port_range.value.from
      to   = tcp_port_range.value.to
    }
  }

  server_groups {
    id = [zpa_server_group.hardened.id]
  }
}

# Server group for App Connector assignment
resource "zpa_server_group" "hardened" {
  name              = var.server_group_name
  description       = "HTH-managed server group for hardened application access"
  enabled           = true
  dynamic_discovery = true

  app_connector_groups {
    id = [var.app_connector_group_name]
  }
}

# HTH Guide Excerpt: end terraform
