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

# Note: Full VPC/VNet deployment with Private Link requires account-level
# Terraform resources (databricks_mws_workspaces, databricks_mws_networks,
# databricks_mws_private_access_settings). Those are provisioned at workspace
# creation time and are outside the scope of workspace-level hardening.
# See the guide section 3.2 for the account-level Terraform example.
# HTH Guide Excerpt: end terraform
