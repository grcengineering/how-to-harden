# =============================================================================
# HTH Orca Control 3.1: Configure Cloud Account Security
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.11, NIST SC-12
# Source: https://howtoharden.com/guides/orca/#31-configure-cloud-account-security
#
# Registers trusted cloud accounts and creates monitoring alerts for
# cloud integration security. Uses read-only IAM policies per Orca
# recommended best practices.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Register trusted cloud accounts used by Orca integrations
resource "orcasecurity_trusted_cloud_account" "trusted" {
  for_each = { for idx, acct in var.trusted_cloud_accounts : acct.cloud_provider_id => acct }

  account_name      = each.value.account_name
  description       = each.value.description
  cloud_provider    = each.value.cloud_provider
  cloud_provider_id = each.value.cloud_provider_id
}

# Alert for cloud accounts with overly permissive IAM roles
resource "orcasecurity_custom_sonar_alert" "overprivileged_integration" {
  name          = "Cloud Integration with Excessive Permissions"
  description   = "Detects cloud accounts connected to Orca with permissions exceeding read-only access, violating least privilege for security tooling."
  rule          = "CloudAccount with PermissionLevel != 'ReadOnly'"
  orca_score    = 8.0
  category      = "IAM misconfigurations"
  context_score = true

  remediation_text = {
    enable = true
    text   = "Review cloud account IAM roles and reduce to read-only where possible. Follow Orca's recommended IAM policies for each cloud provider. See HTH Orca Guide section 3.1."
  }

  compliance_frameworks = [
    { name = "HTH Orca Hardening", section = "3.1 Cloud Account Security", priority = "high" }
  ]
}

# Discovery view to inventory all connected cloud accounts
resource "orcasecurity_discovery_view" "cloud_accounts_inventory" {
  name               = "HTH - Connected Cloud Accounts Inventory"
  organization_level = true
  view_type          = "discovery"
  extra_params       = {}

  filter_data = {
    query = jsonencode({
      "models" : ["CloudAccount"],
      "type" : "object_set"
    })
  }
}
# HTH Guide Excerpt: end terraform
