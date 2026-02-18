# =============================================================================
# HTH SendGrid Control 4.1: Monitor Email Activity
# Profile Level: L1 (Baseline)
# Frameworks: CIS 8.2, NIST AU-2
# Source: https://howtoharden.com/guides/sendgrid/#41-monitor-email-activity
# =============================================================================
#
# NOTE: Email activity monitoring is a continuous operational practice that
# uses the SendGrid Activity Feed and Stats dashboards. The Terraform provider
# does not expose activity monitoring configuration as a resource.
#
# Automation options:
#   - Event webhooks (Control 4.2) for real-time streaming to your SIEM
#   - SendGrid Stats API for periodic metric collection:
#     GET https://api.sendgrid.com/v3/stats?start_date=2024-01-01
#   - Activity Feed API for event-level detail:
#     GET https://api.sendgrid.com/v3/messages

# HTH Guide Excerpt: begin terraform
# Email activity monitoring is an operational practice.
# Automate through:
#   1. Event webhooks (see hth-sendgrid-4.02) for SIEM integration
#   2. SendGrid Stats API for delivery/bounce/spam metrics
#   3. Activity Feed API for per-message event tracking
#
# Key metrics to monitor:
#   - Delivery rate (target: >95%)
#   - Bounce rate (alert if >5%)
#   - Spam complaint rate (alert if >0.1%)
#   - Unexpected volume spikes (>2x baseline)
# HTH Guide Excerpt: end terraform
