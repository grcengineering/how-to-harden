# HTH HashiCorp Vault Control 6.1: Configure Auto-Unseal
# Profile: L2 | NIST: SC-12
# https://howtoharden.com/guides/hashicorp-vault/#61-configure-auto-unseal
#
# Deploy: Add ONE of these seal stanzas to your vault.hcl configuration

# HTH Guide Excerpt: begin cli-auto-unseal
# AWS KMS auto-unseal
seal "awskms" {
  region     = "us-east-1"
  kms_key_id = "alias/vault-unseal-key"
}

# Azure Key Vault auto-unseal
seal "azurekeyvault" {
  tenant_id      = "your-tenant-id"
  client_id      = "your-client-id"
  client_secret  = "your-client-secret"
  vault_name     = "vault-unseal"
  key_name       = "vault-key"
}

# GCP Cloud KMS auto-unseal
seal "gcpckms" {
  project     = "your-project"
  region      = "us-east1"
  key_ring    = "vault"
  crypto_key  = "unseal"
}
# HTH Guide Excerpt: end cli-auto-unseal
