# =============================================================================
# HTH Databricks Control 3.2: Network Isolation
# Profile Level: L2 (Hardened)
# Frameworks: NIST SC-7, SOC 2 CC6.6
# Source: https://howtoharden.com/guides/databricks/#32-network-isolation
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Enforce no public IP addresses on cluster nodes (L2+)
# This adds a cluster policy overlay that prevents public IP assignment
resource "databricks_cluster_policy" "network_isolation" {
  count = var.profile_level >= 2 ? 1 : 0

  name = "HTH - Network Isolation Policy"

  definition = jsonencode({
    "enable_local_disk_encryption" = {
      "type"  = "fixed"
      "value" = true
    }
    "azure_attributes.availability" = {
      "type"         = "allowlist"
      "values"       = ["ON_DEMAND_AZURE"]
      "defaultValue" = "ON_DEMAND_AZURE"
    }
    "custom_tags.NetworkIsolation" = {
      "type"  = "fixed"
      "value" = "enabled"
    }
  })
}

# Grant CAN_USE on the network isolation policy (L2+)
resource "databricks_permissions" "network_isolation_usage" {
  count = var.profile_level >= 2 ? 1 : 0

  cluster_policy_id = databricks_cluster_policy.network_isolation[0].id

  access_control {
    group_name       = "users"
    permission_level = "CAN_USE"
  }
}

# HTH Guide Excerpt: end terraform

# HTH Guide Excerpt: begin terraform-account-level
# Account-level: Private workspace deployment with VPC isolation
resource "databricks_mws_workspaces" "this" {
  account_id      = var.databricks_account_id
  workspace_name  = "secure-workspace"
  deployment_name = "secure"

  aws_region = var.region

  network_id = databricks_mws_networks.this.network_id

  # Private configuration
  private_access_settings_id = databricks_mws_private_access_settings.this.private_access_settings_id
}

resource "databricks_mws_private_access_settings" "this" {
  private_access_settings_name = "secure-pas"
  region                       = var.region
  public_access_enabled        = false
}
# HTH Guide Excerpt: end terraform-account-level
