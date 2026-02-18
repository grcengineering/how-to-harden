# =============================================================================
# HTH SAP SuccessFactors Control 4.1: Audit Logging
# Profile Level: L1 (Baseline)
# Frameworks: NIST AU-2, AU-3
# Source: https://howtoharden.com/guides/sap-successfactors/#41-audit-logging
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Enable the SAP Audit Log service for SuccessFactors
resource "btp_subaccount_entitlement" "audit_log" {
  subaccount_id = var.btp_subaccount_id
  service_name  = "auditlog-management"
  plan_name     = "default"
}

resource "btp_subaccount_service_instance" "audit_log" {
  subaccount_id  = var.btp_subaccount_id
  name           = "hth-sf-audit-log"
  serviceplan_id = data.btp_subaccount_service_plan.audit_log_default.id
  parameters = jsonencode({
    retentionPeriod = var.audit_retention_days
  })

  depends_on = [btp_subaccount_entitlement.audit_log]
}

data "btp_subaccount_service_plan" "audit_log_default" {
  subaccount_id = var.btp_subaccount_id
  name          = "default"
  offering_name = "auditlog-management"
}

# Create a service binding for audit log API access
resource "btp_subaccount_service_binding" "audit_log_binding" {
  subaccount_id       = var.btp_subaccount_id
  name                = "hth-sf-audit-log-binding"
  service_instance_id = btp_subaccount_service_instance.audit_log.id
}

# Role collection for audit log viewers
resource "btp_subaccount_role_collection" "audit_viewer" {
  subaccount_id = var.btp_subaccount_id
  name          = "HTH SF Audit Viewer"
  description   = "HTH: Read-only access to SuccessFactors audit logs"

  roles {
    name                 = "Subaccount Viewer"
    role_template_app_id = "cis-local!b2"
    role_template_name   = "Subaccount_Viewer"
  }
}

# L2+: Enable SIEM integration via webhook for real-time audit event forwarding
resource "btp_subaccount_service_instance" "audit_siem_webhook" {
  count = var.profile_level >= 2 && var.siem_webhook_url != "" ? 1 : 0

  subaccount_id  = var.btp_subaccount_id
  name           = "hth-sf-audit-siem-webhook"
  serviceplan_id = data.btp_subaccount_service_plan.audit_log_default.id
  parameters = jsonencode({
    retentionPeriod = var.audit_retention_days
    webhook = {
      url     = var.siem_webhook_url
      enabled = true
      events  = ["security", "data-access", "configuration-change"]
    }
  })

  depends_on = [btp_subaccount_entitlement.audit_log]
}

# L2+: Extended audit retention (730 days)
resource "btp_subaccount_service_instance" "audit_log_extended" {
  count = var.profile_level >= 2 ? 1 : 0

  subaccount_id  = var.btp_subaccount_id
  name           = "hth-sf-audit-log-extended"
  serviceplan_id = data.btp_subaccount_service_plan.audit_log_default.id
  parameters = jsonencode({
    retentionPeriod = var.profile_level >= 3 ? 1095 : 730
  })

  depends_on = [btp_subaccount_entitlement.audit_log]
}

# L3: Enable the Alert Notification service for real-time security alerts
resource "btp_subaccount_entitlement" "alert_notification" {
  count = var.profile_level >= 3 ? 1 : 0

  subaccount_id = var.btp_subaccount_id
  service_name  = "alert-notification"
  plan_name     = "standard"
}

resource "btp_subaccount_service_instance" "alert_notification" {
  count = var.profile_level >= 3 ? 1 : 0

  subaccount_id  = var.btp_subaccount_id
  name           = "hth-sf-alert-notification"
  serviceplan_id = data.btp_subaccount_service_plan.alert_standard[0].id
  parameters = jsonencode({
    configuration = {
      actions = [
        {
          name = "bulk-data-access-alert"
          type = "EMAIL"
          properties = {
            destination = "security-team@company.com"
          }
        }
      ]
      conditions = [
        {
          name         = "bulk-employee-data-access"
          description  = "HTH: Detect bulk employee data access via API"
          propertyKey  = "eventType"
          predicate    = "EQUALS"
          propertyValue = "data-access"
        }
      ]
    }
  })

  depends_on = [btp_subaccount_entitlement.alert_notification]
}

data "btp_subaccount_service_plan" "alert_standard" {
  count = var.profile_level >= 3 ? 1 : 0

  subaccount_id = var.btp_subaccount_id
  name          = "standard"
  offering_name = "alert-notification"
}
# HTH Guide Excerpt: end terraform
