# =============================================================================
# HTH SendGrid Control 2.4: Configure API Key Alerts
# Profile Level: L2 (Hardened)
# Frameworks: CIS 8.2, NIST SI-4
# Source: https://howtoharden.com/guides/sendgrid/#24-configure-api-key-alerts
# =============================================================================
#
# NOTE: SendGrid does not expose API key alerting through the Terraform provider.
# Monitoring for API key anomalies requires external tooling:
#   - Event webhooks (see Control 4.2) for send-volume anomaly detection
#   - SendGrid Activity Feed for manual review
#   - SIEM integration for automated alerting
#
# Compromise response automation is outside Terraform scope but can be
# triggered by destroying and recreating API key resources.

# HTH Guide Excerpt: begin terraform
# API key alerting is not natively supported by the Terraform provider.
# Implement monitoring through:
#   1. Event webhooks (see hth-sendgrid-4.02) for delivery anomalies
#   2. External SIEM integration for usage pattern analysis
#   3. SendGrid UI: Activity > Feed for manual review
#
# Compromise response via Terraform:
#   terraform taint 'sendgrid_api_key.managed["compromised_key"]'
#   terraform apply
# HTH Guide Excerpt: end terraform
