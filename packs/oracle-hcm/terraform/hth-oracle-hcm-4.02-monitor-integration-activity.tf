# =============================================================================
# HTH Oracle HCM Control 4.2: Monitor Integration Activity
# Profile Level: L2 (Hardened)
# Frameworks: NIST AU-2, AU-6, SI-4
# Source: https://howtoharden.com/guides/oracle-hcm/#42-monitor-integration-activity
# =============================================================================

# HTH Guide Excerpt: begin terraform
# L2: Alarm for unusual API call volume (potential bulk extraction)
resource "oci_monitoring_alarm" "api_rate_alarm" {
  count = var.profile_level >= 2 ? 1 : 0

  compartment_id        = var.idcs_compartment_id
  display_name          = "HTH-HCM-API-Rate-Alarm"
  is_enabled            = true
  severity              = "CRITICAL"
  namespace             = "oci_identity"
  query                 = "ApiCallCount[1h].sum() > ${var.api_rate_limit_threshold}"
  pending_duration      = "PT5M"
  metric_compartment_id = var.idcs_compartment_id
  body                  = "API call rate exceeded ${var.api_rate_limit_threshold} requests/hour for Oracle HCM Cloud. Investigate for potential data exfiltration."

  destinations = [
    var.alarm_notification_topic_id != "" ? var.alarm_notification_topic_id : oci_ons_notification_topic.hcm_security_alerts[0].id
  ]
}

# L2: Alarm for off-hours HCM activity (HDL and API)
resource "oci_monitoring_alarm" "off_hours_activity" {
  count = var.profile_level >= 2 ? 1 : 0

  compartment_id        = var.idcs_compartment_id
  display_name          = "HTH-HCM-Off-Hours-Activity"
  is_enabled            = true
  severity              = "WARNING"
  namespace             = "oci_identity"
  query                 = "OffHoursAccessCount[1h].sum() > 0"
  pending_duration      = "PT5M"
  metric_compartment_id = var.idcs_compartment_id
  body                  = "Off-hours access detected for Oracle HCM Cloud. Verify the activity is authorized."

  destinations = [
    var.alarm_notification_topic_id != "" ? var.alarm_notification_topic_id : oci_ons_notification_topic.hcm_security_alerts[0].id
  ]
}

# L2: Event rule to capture all HCM REST API activity
resource "oci_events_rule" "hcm_api_activity" {
  count = var.profile_level >= 2 ? 1 : 0

  compartment_id = var.oci_tenancy_ocid
  display_name   = "HTH-HCM-API-Activity-Monitor"
  description    = "Capture Oracle HCM REST API activity for security monitoring (L2)"
  is_enabled     = true

  condition = jsonencode({
    eventType = [
      "com.oraclecloud.fusionapps.hcm.rest.read",
      "com.oraclecloud.fusionapps.hcm.rest.create",
      "com.oraclecloud.fusionapps.hcm.rest.update",
      "com.oraclecloud.fusionapps.hcm.rest.delete",
    ]
  })

  actions {
    actions {
      action_type = "ONS"
      is_enabled  = true
      topic_id    = var.alarm_notification_topic_id != "" ? var.alarm_notification_topic_id : oci_ons_notification_topic.hcm_security_alerts[0].id
    }
  }
}

# L3: Event rule for HDL bulk operations requiring approval
resource "oci_events_rule" "hdl_bulk_operations" {
  count = var.profile_level >= 3 ? 1 : 0

  compartment_id = var.oci_tenancy_ocid
  display_name   = "HTH-HCM-HDL-Bulk-Operation-Alert"
  description    = "Alert on all HCM Data Loader bulk operations for approval workflow (L3)"
  is_enabled     = true

  condition = jsonencode({
    eventType = [
      "com.oraclecloud.fusionapps.hcm.hdl.fileupload",
      "com.oraclecloud.fusionapps.hcm.hdl.import",
      "com.oraclecloud.fusionapps.hcm.hdl.export",
    ]
  })

  actions {
    actions {
      action_type = "ONS"
      is_enabled  = true
      topic_id    = var.alarm_notification_topic_id != "" ? var.alarm_notification_topic_id : oci_ons_notification_topic.hcm_security_alerts[0].id
    }
  }
}
# HTH Guide Excerpt: end terraform
