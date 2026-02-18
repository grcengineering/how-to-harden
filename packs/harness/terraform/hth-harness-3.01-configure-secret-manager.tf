# =============================================================================
# HTH Harness Control 3.1: Configure Secret Manager
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.11, NIST SC-12
# Source: https://howtoharden.com/guides/harness/#31-configure-secret-manager
# =============================================================================

# HTH Guide Excerpt: begin terraform
# HashiCorp Vault connector for external secret management
resource "harness_platform_connector_vault" "vault" {
  count = var.secret_manager_type == "vault" ? 1 : 0

  identifier  = "hth_vault_connector"
  name        = "HashiCorp Vault"
  description = "External secret manager -- HashiCorp Vault (HTH Control 3.1)"

  url                    = var.vault_url
  access_type            = "TOKEN"
  default                = true
  read_only              = false
  renewal_interval_minutes = var.vault_renew_interval_minutes
  secret_engine_name     = var.vault_secret_engine
  secret_engine_version  = 2
  use_vault_agent        = false
  use_aws_iam            = false
  use_k8s_auth           = false

  auth_token = var.vault_token
}

# AWS Secrets Manager connector
resource "harness_platform_connector_aws_secret_manager" "aws" {
  count = var.secret_manager_type == "aws" ? 1 : 0

  identifier  = "hth_aws_secrets_connector"
  name        = "AWS Secrets Manager"
  description = "External secret manager -- AWS Secrets Manager (HTH Control 3.1)"

  default        = true
  secret_name_prefix = "harness/"
  region         = "us-east-1"

  credentials {
    inherit_from_delegate = true
  }
}

# GCP Secret Manager connector
resource "harness_platform_connector_gcp_secret_manager" "gcp" {
  count = var.secret_manager_type == "gcp" ? 1 : 0

  identifier  = "hth_gcp_secrets_connector"
  name        = "GCP Secret Manager"
  description = "External secret manager -- GCP Secret Manager (HTH Control 3.1)"

  default    = true
  is_default = true

  credentials {
    inherit_from_delegate = true
  }
}
# HTH Guide Excerpt: end terraform
