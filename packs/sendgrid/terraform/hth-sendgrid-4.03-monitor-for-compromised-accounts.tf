# =============================================================================
# HTH SendGrid Control 4.3: Monitor for Compromised Accounts
# Profile Level: L1 (Baseline)
# Frameworks: CIS 8.11, NIST SI-4
# Source: https://howtoharden.com/guides/sendgrid/#43-monitor-for-compromised-accounts
# =============================================================================
#
# NOTE: Account compromise monitoring is a continuous operational practice that
# combines event webhook data (Control 4.2), activity feed review, and external
# tooling. The Terraform provider does not expose monitoring configuration.
#
# Indicators of compromise:
#   - Unusual send volumes (>2x baseline)
#   - Spike in bounces or spam complaints
#   - Unknown API keys appearing in Settings > API Keys
#   - Unauthorized teammate additions
#
# Response automation via Terraform:
#   1. Rotate all API keys: terraform taint all sendgrid_api_key resources
#   2. Review teammates: terraform plan to detect drift
#   3. Check SSO configuration: terraform plan to detect unauthorized changes

# HTH Guide Excerpt: begin terraform
# Account compromise detection is an operational practice.
# Terraform supports the response workflow:
#
# Detection (external tooling):
#   - Event webhooks (hth-sendgrid-4.02) stream to SIEM
#   - Alert on: volume spikes, bounce spikes, spam complaints
#   - Regular terraform plan to detect configuration drift
#
# Response via Terraform:
#   1. Rotate API keys:
#      terraform taint 'sendgrid_api_key.managed["key_name"]'
#      terraform apply
#   2. Audit teammates:
#      terraform plan  # detects unauthorized additions
#   3. Verify SSO config:
#      terraform plan  # detects SSO tampering
# HTH Guide Excerpt: end terraform
