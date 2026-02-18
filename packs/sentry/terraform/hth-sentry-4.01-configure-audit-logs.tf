# =============================================================================
# HTH Sentry Control 4.1: Configure Audit Logs
# Profile Level: L1 (Baseline)
# Frameworks: CIS 8.2, NIST AU-2
# Source: https://howtoharden.com/guides/sentry/#41-configure-audit-logs
#
# NOTE: Sentry audit logs are automatically enabled on Business and
# Enterprise plans. This control creates an issue alert to monitor
# high-volume error spikes that may indicate security incidents.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create a security monitoring alert for error volume spikes.
# High-frequency errors can indicate application attacks, credential
# stuffing, or integration abuse.
resource "sentry_issue_alert" "security_monitoring" {
  count = var.security_alert_project != "" ? 1 : 0

  organization = var.sentry_organization
  project      = var.security_alert_project
  name         = "HTH: Security Event Monitoring"

  action_match = "any"
  filter_match = "any"
  frequency    = 30

  conditions = jsonencode([
    {
      id       = "sentry.rules.conditions.first_seen_event.FirstSeenEventCondition"
      name     = "A new issue is created"
    },
    {
      id       = "sentry.rules.conditions.event_frequency.EventFrequencyCondition"
      name     = "The issue is seen more than 100 times in 1 hour"
      value    = 100
      interval = "1h"
    }
  ])

  filters = jsonencode([
    {
      id    = "sentry.rules.filters.level.LevelFilter"
      match = "gte"
      level = "error"
      name  = "The event's level is equal to or greater than error"
    }
  ])

  actions = jsonencode([
    {
      id               = "sentry.mail.actions.NotifyEmailAction"
      name             = "Send a notification to the security team"
      targetType       = "IssueOwners"
      targetIdentifier = ""
    }
  ])

  depends_on = [sentry_project.projects]
}

# ---------------------------------------------------------------------------
# Audit log review must be performed via Sentry UI or API:
#
#   UI: Settings > Audit Log
#
#   API: GET /api/0/organizations/{org_slug}/audit-logs/
#
# Key events to monitor:
#   - org.edit (organization settings changes)
#   - member.join / member.leave (membership changes)
#   - member.role-change (privilege escalation)
#   - project.create / project.remove (project lifecycle)
#   - sso.enable / sso.disable (SSO changes)
#   - api-key.create / api-key.remove (key management)
#
# For L3, integrate audit logs with a SIEM via the Sentry API
# or webhook integrations.
# ---------------------------------------------------------------------------
# HTH Guide Excerpt: end terraform
