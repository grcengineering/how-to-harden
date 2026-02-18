# =============================================================================
# HTH CyberArk Control 6.1: Enable Comprehensive Audit Logging
# Profile Level: L1 (Baseline)
# Frameworks: NIST AU-2, AU-3
# Source: https://howtoharden.com/guides/cyberark/#61-enable-comprehensive-audit-logging
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure comprehensive audit logging
resource "null_resource" "audit_logging_config" {
  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/AuditSettings" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "settings": {
            "auditEnabled": true,
            "logLogonEvents": true,
            "logRetrieveEvents": true,
            "logPasswordChangeEvents": true,
            "logSafeModificationEvents": true,
            "logPolicyChanges": true,
            "retentionDays": ${var.audit_retention_days}
          }
        }'
    EOT
  }

  triggers = {
    retention_days = var.audit_retention_days
  }
}

# Configure SIEM log forwarding
resource "null_resource" "siem_log_forwarding" {
  count = var.siem_server != "" ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/SyslogSettings" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "settings": {
            "syslogEnabled": true,
            "syslogServer": "${var.siem_server}",
            "syslogPort": ${var.siem_port},
            "syslogProtocol": "TCP",
            "syslogFormat": "CEF",
            "sendRealtimeEvents": true
          }
        }'
    EOT
  }

  triggers = {
    siem_server = var.siem_server
    siem_port   = var.siem_port
  }
}

# L2+: Enable enhanced detection use cases
resource "null_resource" "enhanced_detection" {
  count = var.profile_level >= 2 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/AuditSettings" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "settings": {
            "detectMassRetrieval": true,
            "massRetrievalThreshold": 20,
            "massRetrievalWindowMinutes": 60,
            "detectAfterHoursAccess": true,
            "businessHoursStart": 6,
            "businessHoursEnd": 20,
            "detectFailedAuthSpike": true,
            "failedAuthThreshold": 5,
            "failedAuthWindowMinutes": 15,
            "alertOnDetection": true
          }
        }'
    EOT
  }

  depends_on = [null_resource.audit_logging_config]

  triggers = {
    profile_level = var.profile_level
  }
}

# L3: Enable full forensic logging with immutable audit trail
resource "null_resource" "forensic_logging" {
  count = var.profile_level >= 3 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/AuditSettings" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "settings": {
            "immutableAuditTrail": true,
            "logAllAPIRequests": true,
            "logSessionKeystrokes": true,
            "logClipboardEvents": true,
            "retentionDays": 730,
            "tamperDetection": true,
            "hashVerification": true
          }
        }'
    EOT
  }

  depends_on = [null_resource.enhanced_detection]

  triggers = {
    profile_level = var.profile_level
  }
}
# HTH Guide Excerpt: end terraform
