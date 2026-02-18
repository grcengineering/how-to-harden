# =============================================================================
# HTH Databricks Control 4.1: Secret Scopes
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-28, SOC 2 CC6.7
# Source: https://howtoharden.com/guides/databricks/#41-use-databricks-secret-scopes
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create Databricks-backed secret scopes for credential storage
resource "databricks_secret_scope" "managed" {
  for_each = var.secret_scopes

  name                     = each.key
  initial_manage_principal = each.value.initial_manage_principal
}

# Grant READ access to the data_engineers group on each secret scope
resource "databricks_secret_acl" "data_engineers_read" {
  for_each = var.secret_scopes

  scope      = databricks_secret_scope.managed[each.key].name
  principal  = "data_engineers"
  permission = "READ"
}
# HTH Guide Excerpt: end terraform
