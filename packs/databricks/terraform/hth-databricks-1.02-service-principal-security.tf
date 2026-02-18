# =============================================================================
# HTH Databricks Control 1.2: Service Principal Security
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5, SOC 2 CC6.1
# Source: https://howtoharden.com/guides/databricks/#12-implement-service-principal-security
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create purpose-specific service principals for automation
resource "databricks_service_principal" "automation" {
  for_each = var.service_principals

  display_name = each.value.display_name
  active       = true
}

# Grant workspace-level permissions to service principals
# Each service principal gets CAN_ATTACH_TO on designated clusters only
resource "databricks_permissions" "service_principal_cluster_usage" {
  for_each = var.service_principals

  cluster_policy_id = databricks_cluster_policy.hardened.id

  access_control {
    service_principal_name = databricks_service_principal.automation[each.key].application_id
    permission_level       = "CAN_USE"
  }
}
# HTH Guide Excerpt: end terraform
