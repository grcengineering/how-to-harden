# =============================================================================
# HTH Terraform Cloud Control 4.02: Vault Integration
# Profile Level: L2 (Hardened)
# Source: https://howtoharden.com/guides/terraform-cloud/#42-vault-integration
# =============================================================================

# HTH Guide Excerpt: begin vault-provider
# Use Vault provider for secrets
provider "vault" {
  address = "https://vault.company.com"
}

data "vault_generic_secret" "db" {
  path = "secret/production/database"
}

resource "aws_db_instance" "main" {
  password = data.vault_generic_secret.db.data["password"]
}
# HTH Guide Excerpt: end vault-provider
