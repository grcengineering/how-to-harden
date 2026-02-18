# =============================================================================
# HTH Databricks Control 2.1: Unity Catalog Data Governance
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-3, SOC 2 CC6.2
# Source: https://howtoharden.com/guides/databricks/#21-implement-data-governance
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Unity Catalog grants are managed via SQL statements.
# This resource configures workspace-level Unity Catalog settings.
resource "databricks_workspace_conf" "unity_catalog_governance" {
  custom_config = {
    "enableUnityCatalog" = true
  }
}

# Restrict catalog creation to admins only via SQL global config
resource "databricks_sql_global_config" "governance" {
  security_policy = "DATA_ACCESS_CONTROL"

  data_access_config = {
    "spark.databricks.unityCatalog.enabled" = "true"
  }
}
# HTH Guide Excerpt: end terraform
