# =============================================================================
# HTH Snowflake Control 4.1: Implement Column-Level Security with Masking Policies
# Profile Level: L2 (Hardened)
# Frameworks: NIST AC-3, SC-28
# Source: https://howtoharden.com/guides/snowflake/#41-implement-column-level-security-with-masking-policies
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Dynamic data masking policy for email addresses
resource "snowflake_masking_policy" "mask_email" {
  count = var.profile_level >= 2 ? 1 : 0

  name     = "HTH_MASK_EMAIL"
  database = var.target_database
  schema   = var.target_schema
  comment  = "HTH: Mask email addresses for non-privileged roles (Control 4.1)"

  signature {
    column {
      name = "val"
      type = "VARCHAR"
    }
  }

  masking_expression = <<-EOT
    CASE
      WHEN CURRENT_ROLE() IN ('HTH_DATA_WRITER', 'SYSADMIN', 'ACCOUNTADMIN')
        THEN val
      WHEN CURRENT_ROLE() = 'HTH_DATA_ANALYST'
        THEN REGEXP_REPLACE(val, '.+@', '***@')
      ELSE '********'
    END
  EOT

  return_data_type = "VARCHAR"
}

# Dynamic data masking policy for SSN / national ID
resource "snowflake_masking_policy" "mask_ssn" {
  count = var.profile_level >= 2 ? 1 : 0

  name     = "HTH_MASK_SSN"
  database = var.target_database
  schema   = var.target_schema
  comment  = "HTH: Mask SSN/national ID for non-privileged roles (Control 4.1)"

  signature {
    column {
      name = "val"
      type = "VARCHAR"
    }
  }

  masking_expression = <<-EOT
    CASE
      WHEN CURRENT_ROLE() IN ('SYSADMIN', 'ACCOUNTADMIN')
        THEN val
      ELSE CONCAT('***-**-', RIGHT(val, 4))
    END
  EOT

  return_data_type = "VARCHAR"
}

# Row access policy for multi-tenant data isolation
resource "snowflake_row_access_policy" "tenant_isolation" {
  count = var.profile_level >= 2 ? 1 : 0

  name     = "HTH_TENANT_ISOLATION"
  database = var.target_database
  schema   = var.target_schema
  comment  = "HTH: Row-level security for multi-tenant data isolation (Control 4.2)"

  signature {
    column {
      name = "tenant_id"
      type = "VARCHAR"
    }
  }

  row_access_expression = <<-EOT
    CASE
      WHEN CURRENT_ROLE() IN ('SYSADMIN', 'ACCOUNTADMIN')
        THEN TRUE
      ELSE tenant_id = CURRENT_SESSION_CONTEXT('TENANT_ID')
    END
  EOT
}
# HTH Guide Excerpt: end terraform
