# =============================================================================
# HTH Databricks Control 3.1: Cluster Policies
# Profile Level: L1 (Baseline)
# Frameworks: NIST CM-7, SOC 2 CC6.1
# Source: https://howtoharden.com/guides/databricks/#31-configure-cluster-policies
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Hardened cluster policy enforcing approved runtimes, node types,
# auto-termination, and init script restrictions
resource "databricks_cluster_policy" "hardened" {
  name = "HTH - Hardened Cluster Policy"

  definition = jsonencode({
    "spark_version" = {
      "type"   = "allowlist"
      "values" = var.allowed_spark_versions
    }
    "node_type_id" = {
      "type"   = "allowlist"
      "values" = var.allowed_node_types
    }
    "autotermination_minutes" = {
      "type"         = "range"
      "minValue"     = 10
      "maxValue"     = var.autotermination_minutes_max
      "defaultValue" = var.autotermination_minutes_default
    }
    "custom_tags.Environment" = {
      "type"  = "fixed"
      "value" = "production"
    }
    "custom_tags.ManagedBy" = {
      "type"  = "fixed"
      "value" = "howtoharden"
    }
    "init_scripts" = {
      "type"  = "fixed"
      "value" = []
    }
    "enable_elastic_disk" = {
      "type"         = "fixed"
      "value"        = true
      "hidden"       = true
    }
  })
}

# Grant CAN_USE on the hardened policy to all users
resource "databricks_permissions" "cluster_policy_usage" {
  cluster_policy_id = databricks_cluster_policy.hardened.id

  access_control {
    group_name       = "users"
    permission_level = "CAN_USE"
  }
}
# HTH Guide Excerpt: end terraform
