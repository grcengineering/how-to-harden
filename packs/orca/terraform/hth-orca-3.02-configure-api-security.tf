# =============================================================================
# HTH Orca Control 3.2: Configure API Security
# Profile Level: L2 (Hardened)
# Frameworks: CIS 3.11, NIST SC-12
# Source: https://howtoharden.com/guides/orca/#32-configure-api-security
#
# Creates monitoring alerts and automations for API key lifecycle management.
# Detects unused or stale API keys and notifies security teams.
# Only deployed at profile level 2+.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Custom alert to detect stale or unused API keys in connected cloud accounts
resource "orcasecurity_custom_sonar_alert" "stale_api_keys" {
  count = var.profile_level >= 2 ? 1 : 0

  name          = var.api_alert_name
  description   = "Detects API keys that have not been rotated or used recently, indicating stale credentials that should be revoked."
  rule          = "AccessKey with LastUsedDate before_days 90"
  orca_score    = var.api_alert_score
  category      = "IAM misconfigurations"
  context_score = true

  remediation_text = {
    enable = true
    text   = "Rotate or revoke API keys that have not been used in 90+ days. Store active keys in a secrets manager. Document the purpose of each key. See HTH Orca Guide section 3.2."
  }

  compliance_frameworks = [
    { name = "HTH Orca Hardening", section = "3.2 API Security", priority = "medium" }
  ]
}

# Automation to email security team when stale API keys are found (L2+)
resource "orcasecurity_automation" "api_key_alert" {
  count = var.profile_level >= 2 && var.enable_api_automation && length(var.api_alert_emails) > 0 ? 1 : 0

  name        = "HTH - API Key Security Notifications"
  description = "Sends email notifications when stale or unused API keys are detected. Per HTH Orca Guide section 3.2."
  enabled     = true

  query = {
    filter = [
      { field = "state.status", includes = ["open"] },
      { field = "state.risk_level", includes = ["high", "critical"] },
      { field = "category", includes = ["IAM misconfigurations"] }
    ]
  }

  email_template = {
    email        = var.api_alert_emails
    multi_alerts = true
  }
}

# Discovery view for API key inventory (L3) -- strict tracking of all API credentials
resource "orcasecurity_discovery_view" "api_key_inventory" {
  count = var.profile_level >= 3 ? 1 : 0

  name               = "HTH - API Key Inventory (All Cloud Accounts)"
  organization_level = true
  view_type          = "discovery"
  extra_params       = {}

  filter_data = {
    query = jsonencode({
      "models" : ["AccessKey"],
      "type" : "object_set"
    })
  }
}
# HTH Guide Excerpt: end terraform
