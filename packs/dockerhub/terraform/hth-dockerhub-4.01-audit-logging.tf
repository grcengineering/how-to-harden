# =============================================================================
# HTH Docker Hub Control 4.1: Audit Logging
# Profile Level: L1 (Baseline)
# Frameworks: NIST AU-2
# Source: https://howtoharden.com/guides/dockerhub/#41-audit-logging
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Docker Hub audit log configuration and SIEM integration.
# Audit logs track push/pull activity, permission changes, and access events.

# Enable audit log export to external SIEM via webhook (Business plan).
resource "docker_hub_org_setting" "audit_log_export" {
  count = var.audit_log_export_enabled ? 1 : 0

  org_name = var.dockerhub_organization
  setting  = "audit_log_export"
  value    = "enabled"
}

# Configure webhook for audit log forwarding to SIEM.
resource "docker_hub_webhook" "audit_siem_forwarder" {
  count = var.audit_log_export_enabled && var.siem_webhook_url != "" ? 1 : 0

  namespace    = var.dockerhub_organization
  name         = "hth-audit-siem-forwarder"
  webhook_url  = var.siem_webhook_url
  expect_final_callback = false

  webhook_events = [
    "push",
    "delete",
    "repo_create",
    "repo_delete",
    "team_member_add",
    "team_member_remove",
    "org_member_add",
    "org_member_remove",
  ]
}

# Audit log monitoring queries and detection rules.
resource "null_resource" "audit_detection_rules" {
  triggers = {
    organization = var.dockerhub_organization
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "=== Docker Hub Audit Log Detection Rules ==="
      echo ""
      echo "Detection 1: Unusual push activity (>10 pushes/hour)"
      echo "  SQL:"
      echo "  SELECT user, repository, COUNT(*) as push_count"
      echo "  FROM docker_audit_log"
      echo "  WHERE action = 'push'"
      echo "    AND timestamp > NOW() - INTERVAL '1 hour'"
      echo "  GROUP BY user, repository"
      echo "  HAVING COUNT(*) > 10;"
      echo ""
      echo "Detection 2: Push from unknown IP"
      echo "  Monitor for push events from IPs not in known CI/CD ranges"
      echo ""
      echo "Detection 3: Repository visibility changes"
      echo "  Alert on any private-to-public visibility change"
      echo ""
      echo "Detection 4: New organization member additions"
      echo "  Alert on org_member_add events for review"
      echo ""
      echo "API endpoint for audit logs (Business plan):"
      echo "  GET https://hub.docker.com/v2/auditlogs/${var.dockerhub_organization}/"
    EOT
  }
}

# L2+: Enhanced monitoring with anomaly detection thresholds.
resource "null_resource" "enhanced_monitoring" {
  count = var.profile_level >= 2 ? 1 : 0

  triggers = {
    organization = var.dockerhub_organization
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "=== Enhanced Docker Hub Monitoring (L2 Hardened) ==="
      echo ""
      echo "Additional detection rules for L2+:"
      echo ""
      echo "  1. Image pull anomaly: Alert when pull count exceeds 3x baseline"
      echo "  2. Off-hours push: Alert on pushes outside business hours"
      echo "  3. Token creation: Alert on new access token creation"
      echo "  4. Permission escalation: Alert on team permission changes"
      echo "  5. Failed authentication: Alert on >5 failed logins in 10 minutes"
      echo ""
      echo "Recommended SIEM correlation rules:"
      echo "  - Correlate Docker Hub events with CI/CD pipeline logs"
      echo "  - Cross-reference push source IPs with known infrastructure"
      echo "  - Alert on push events without corresponding CI/CD job"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
