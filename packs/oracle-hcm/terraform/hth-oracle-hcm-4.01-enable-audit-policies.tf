# =============================================================================
# HTH Oracle HCM Control 4.1: Enable Audit Policies
# Profile Level: L1 (Baseline)
# Frameworks: NIST AU-2, AU-3
# Source: https://howtoharden.com/guides/oracle-hcm/#41-enable-audit-policies
# =============================================================================

# HTH Guide Excerpt: begin terraform
# OCI Audit configuration — ensure audit is enabled for the compartment
resource "oci_audit_configuration" "hcm_audit" {
  compartment_id        = var.oci_tenancy_ocid
  retention_period_days = var.audit_retention_days
}

# Service Connector Hub for streaming audit events to a target
resource "oci_sch_service_connector" "hcm_audit_connector" {
  compartment_id = var.idcs_compartment_id
  display_name   = "HTH-HCM-Audit-Connector"
  description    = "Stream Oracle HCM Cloud audit events to logging and notifications"

  source {
    kind = "logging"
    log_sources {
      compartment_id = var.idcs_compartment_id
      log_group_id   = oci_log_analytics_log_group.hcm_audit_logs.id
    }
  }

  target {
    kind      = "notifications"
    topic_id  = var.alarm_notification_topic_id != "" ? var.alarm_notification_topic_id : oci_ons_notification_topic.hcm_security_alerts[0].id
  }
}

# Notification topic for HCM security alerts (created when no existing topic provided)
resource "oci_ons_notification_topic" "hcm_security_alerts" {
  count = var.alarm_notification_topic_id == "" ? 1 : 0

  compartment_id = var.idcs_compartment_id
  name           = "HTH-HCM-Security-Alerts"
  description    = "Notification topic for Oracle HCM Cloud security alerts"
}

# Email subscription for the notification topic
resource "oci_ons_subscription" "hcm_alert_email" {
  count = var.alarm_notification_topic_id == "" && var.alarm_notification_email != "" ? 1 : 0

  compartment_id = var.idcs_compartment_id
  topic_id       = oci_ons_notification_topic.hcm_security_alerts[0].id
  protocol       = "EMAIL"
  endpoint       = var.alarm_notification_email
}

# OCI Monitoring alarm for authentication failures
resource "oci_monitoring_alarm" "hcm_auth_failures" {
  compartment_id        = var.idcs_compartment_id
  display_name          = "HTH-HCM-Auth-Failure-Alarm"
  is_enabled            = var.enable_auth_event_auditing
  severity              = "CRITICAL"
  namespace             = "oci_identity"
  query                 = "AuthFailureCount[5m].sum() > 10"
  pending_duration      = "PT5M"
  metric_compartment_id = var.idcs_compartment_id
  body                  = "Multiple authentication failures detected for Oracle HCM Cloud. Review IDCS sign-on audit logs."

  destinations = [
    var.alarm_notification_topic_id != "" ? var.alarm_notification_topic_id : oci_ons_notification_topic.hcm_security_alerts[0].id
  ]
}

# OCI Monitoring alarm for security configuration changes
resource "oci_monitoring_alarm" "hcm_config_changes" {
  compartment_id        = var.idcs_compartment_id
  display_name          = "HTH-HCM-Config-Change-Alarm"
  is_enabled            = var.enable_config_change_auditing
  severity              = "WARNING"
  namespace             = "oci_identity"
  query                 = "SecurityConfigChangeCount[5m].sum() > 0"
  pending_duration      = "PT1M"
  metric_compartment_id = var.idcs_compartment_id
  body                  = "Security configuration change detected in Oracle HCM Cloud. Verify the change was authorized."

  destinations = [
    var.alarm_notification_topic_id != "" ? var.alarm_notification_topic_id : oci_ons_notification_topic.hcm_security_alerts[0].id
  ]
}

# OCI Monitoring alarm for data access anomalies
resource "oci_monitoring_alarm" "hcm_data_access_anomaly" {
  compartment_id        = var.idcs_compartment_id
  display_name          = "HTH-HCM-Data-Access-Anomaly"
  is_enabled            = var.enable_data_access_auditing
  severity              = "WARNING"
  namespace             = "oci_identity"
  query                 = "DataAccessCount[1h].sum() > 1000"
  pending_duration      = "PT5M"
  metric_compartment_id = var.idcs_compartment_id
  body                  = "Unusual data access volume detected in Oracle HCM Cloud. Possible bulk extraction attempt."

  destinations = [
    var.alarm_notification_topic_id != "" ? var.alarm_notification_topic_id : oci_ons_notification_topic.hcm_security_alerts[0].id
  ]
}
# HTH Guide Excerpt: end terraform
