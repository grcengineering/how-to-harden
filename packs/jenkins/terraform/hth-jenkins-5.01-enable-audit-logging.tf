# =============================================================================
# HTH Jenkins Control 5.1: Enable Audit Logging
# Profile Level: L1 (Baseline)
# Frameworks: CIS 8.2, NIST AU-2
# Source: https://howtoharden.com/guides/jenkins/#51-enable-audit-logging
#
# Configures the Audit Trail Plugin via JCasC to log security-relevant events
# to a file and optionally to a syslog server for SIEM integration. Also
# creates a Jenkins view for security monitoring visibility.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# JCasC configuration for audit trail logging
resource "local_file" "audit_logging" {
  filename = "${path.module}/generated/casc-audit-logging.yaml"
  content  = yamlencode({
    unclassified = {
      audit-trail = {
        logBuildCause = true
        pattern       = ".*/(?:configSubmit|doDelete|postBuildResult|enable|disable|cancelQueue|stop|toggleLogKeep|doWipeOutWorkspace|createItem|createView|toggleOffline|cancelQuietDown|quietDown|restart|exit|safeExit).*"
        loggers = concat(
          [
            {
              file = {
                log     = var.audit_log_path
                limit   = var.audit_log_size_mb
                count   = var.audit_log_rotate_count
              }
            }
          ],
          var.syslog_server != "" ? [
            {
              syslog = {
                syslogServerHostname = var.syslog_server
                syslogServerPort     = var.syslog_port
                facility             = "LOCAL0"
                messageHostname      = "jenkins"
              }
            }
          ] : []
        )
      }
    }
  })

  file_permission = "0644"
}

# Security monitoring view for audit visibility
resource "jenkins_view" "security_monitoring" {
  count = var.create_security_views ? 1 : 0

  name              = "Security-Monitoring"
  assigned_projects = var.monitored_projects
}
# HTH Guide Excerpt: end terraform
