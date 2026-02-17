# =============================================================================
# Snowflake Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Snowflake Terraform provider for account management.
# See: https://registry.terraform.io/providers/Snowflake-Labs/snowflake/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.90"
    }
  }
}

provider "snowflake" {
  account  = var.snowflake_account
  username = var.snowflake_user
  role     = "ACCOUNTADMIN"

  # Authentication: private key preferred, password fallback
  # Set via environment: SNOWFLAKE_PRIVATE_KEY_PATH or SNOWFLAKE_PASSWORD
}
