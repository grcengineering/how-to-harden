# =============================================================================
# HTH Snowflake Control 1.3: Implement RBAC with Custom Roles
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-3, AC-6
# Source: https://howtoharden.com/guides/snowflake/#13-implement-rbac-with-custom-roles
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Custom functional roles following least-privilege principle
resource "snowflake_role" "data_reader" {
  name    = "HTH_DATA_READER"
  comment = "HTH: Read-only access to production data (Control 1.3)"
}

resource "snowflake_role" "data_writer" {
  name    = "HTH_DATA_WRITER"
  comment = "HTH: Read-write access to production data (Control 1.3)"
}

resource "snowflake_role" "data_analyst" {
  name    = "HTH_DATA_ANALYST"
  comment = "HTH: Analyst role with warehouse and read access (Control 1.3)"
}

resource "snowflake_role" "security_admin" {
  name    = "HTH_SECURITY_ADMIN"
  comment = "HTH: Security administration without full ACCOUNTADMIN (Control 1.3)"
}

# Role hierarchy: SECURITY_ADMIN -> ACCOUNTADMIN, DATA_WRITER -> SYSADMIN
resource "snowflake_role_grants" "reader_to_writer" {
  role_name = snowflake_role.data_reader.name
  roles     = [snowflake_role.data_writer.name]
}

resource "snowflake_role_grants" "reader_to_analyst" {
  role_name = snowflake_role.data_reader.name
  roles     = [snowflake_role.data_analyst.name]
}

resource "snowflake_role_grants" "writer_to_sysadmin" {
  role_name = snowflake_role.data_writer.name
  roles     = ["SYSADMIN"]
}

resource "snowflake_role_grants" "security_to_accountadmin" {
  role_name = snowflake_role.security_admin.name
  roles     = ["ACCOUNTADMIN"]
}

# Grant read permissions on target database to DATA_READER
resource "snowflake_database_grant" "reader_usage" {
  count = var.target_database != "" ? 1 : 0

  database_name = var.target_database
  privilege     = "USAGE"
  roles         = [snowflake_role.data_reader.name]
}

resource "snowflake_schema_grant" "reader_usage" {
  count = var.target_database != "" ? 1 : 0

  database_name = var.target_database
  privilege     = "USAGE"
  on_all        = true
  roles         = [snowflake_role.data_reader.name]
}

resource "snowflake_table_grant" "reader_select" {
  count = var.target_database != "" ? 1 : 0

  database_name = var.target_database
  privilege     = "SELECT"
  on_all        = true
  roles         = [snowflake_role.data_reader.name]
}
# HTH Guide Excerpt: end terraform
