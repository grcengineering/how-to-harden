# =============================================================================
# HTH Snowflake Control 1.1: Enforce MFA for All Users
# Profile Level: L1 (Baseline) | CRITICAL
# Frameworks: NIST IA-2(1)
# Source: https://howtoharden.com/guides/snowflake/#11-enforce-mfa-for-all-users
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Authentication policy requiring MFA for all human users
resource "snowflake_authentication_policy" "require_mfa" {
  name     = "HTH_REQUIRE_MFA"
  database = "SNOWFLAKE"
  schema   = "PUBLIC"
  comment  = "HTH: Enforce MFA for all human users (Control 1.1)"

  mfa_authentication_methods = ["TOTP"]
  client_types               = ["SNOWFLAKE_UI", "SNOWSQL", "DRIVERS"]
}

# Attach authentication policy at account level
resource "snowflake_account_parameter" "require_mfa" {
  key   = "AUTHENTICATION_POLICY"
  value = snowflake_authentication_policy.require_mfa.name
}

# Ensure service accounts use key-pair auth (excluded from MFA)
# Service accounts should be created with TYPE = SERVICE and key-pair auth
resource "snowflake_user" "service_account_example" {
  count = var.create_example_service_account ? 1 : 0

  name          = "HTH_SVC_EXAMPLE"
  login_name    = "hth_svc_example"
  comment       = "HTH: Example service account with key-pair auth (Control 1.1/1.2)"
  disabled      = false
  default_role  = "HTH_DATA_READER"
  rsa_public_key = var.service_account_rsa_public_key
}
# HTH Guide Excerpt: end terraform
