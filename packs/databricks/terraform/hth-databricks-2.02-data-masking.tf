# =============================================================================
# HTH Databricks Control 2.2: Dynamic Data Masking
# Profile Level: L2 (Hardened)
# Frameworks: NIST SC-28, SOC 2 CC6.7
# Source: https://howtoharden.com/guides/databricks/#22-configure-data-masking
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Note: Dynamic data masking in Unity Catalog is configured via SQL statements
# (CREATE FUNCTION + ALTER TABLE ... SET MASK). This control enforces the
# workspace-level configuration that enables column masking support.
#
# The SQL masking functions below should be applied via databricks_sql_query
# or a separate SQL migration pipeline:
#
#   CREATE FUNCTION production.masks.mask_ssn(ssn STRING)
#   RETURNS STRING
#   RETURN CASE
#       WHEN is_account_group_member('pii_admin') THEN ssn
#       ELSE CONCAT('XXX-XX-', RIGHT(ssn, 4))
#   END;
#
#   ALTER TABLE production.customer_data.customers
#   ALTER COLUMN ssn SET MASK production.masks.mask_ssn;

# Enable table access control to support column-level masking (L2+)
resource "databricks_workspace_conf" "data_masking" {
  count = var.profile_level >= 2 ? 1 : 0

  custom_config = {
    "enableTableAccessControl" = true
  }
}
# HTH Guide Excerpt: end terraform
