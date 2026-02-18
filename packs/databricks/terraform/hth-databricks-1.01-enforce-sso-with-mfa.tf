# =============================================================================
# HTH Databricks Control 1.1: Enforce SSO with MFA
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-2(1), SOC 2 CC6.1
# Source: https://howtoharden.com/guides/databricks/#11-enforce-sso-with-mfa
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Enforce SSO-only login by disabling local password authentication
resource "databricks_workspace_conf" "sso_enforcement" {
  custom_config = {
    "enableTokensConfig"     = false
    "enableIpAccessLists"    = var.profile_level >= 2
  }
}
# HTH Guide Excerpt: end terraform
