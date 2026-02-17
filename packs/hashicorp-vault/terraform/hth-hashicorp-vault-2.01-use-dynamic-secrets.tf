# =============================================================================
# HTH HashiCorp Vault Control 2.1: Use Dynamic Secrets
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5, SC-12 | SOC 2 CC6.1 | ISO 27001 A.9.2.4
# Source: https://howtoharden.com/guides/hashicorp-vault/#21-use-dynamic-secrets
# =============================================================================

# HTH Guide Excerpt: begin terraform
# --- Database secrets engine mount ---
resource "vault_mount" "database" {
  path        = "database"
  type        = "database"
  description = "Dynamic database credential generation"

  default_lease_ttl_seconds = 1800
  max_lease_ttl_seconds     = 3600
}

# --- PostgreSQL connection configuration ---
resource "vault_database_secret_backend_connection" "postgres" {
  backend       = vault_mount.database.path
  name          = "postgres-app"
  allowed_roles = ["app-readonly", "app-readwrite"]

  postgresql {
    connection_url = var.postgres_connection_url
    username       = var.postgres_admin_username
    password       = var.postgres_admin_password
  }

  verify_connection = true
}

# --- Read-only dynamic role ---
resource "vault_database_secret_backend_role" "app_readonly" {
  backend     = vault_mount.database.path
  name        = "app-readonly"
  db_name     = vault_database_secret_backend_connection.postgres.name

  default_ttl = 1800
  max_ttl     = 3600

  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";",
  ]

  revocation_statements = [
    "REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM \"{{name}}\";",
    "DROP ROLE IF EXISTS \"{{name}}\";",
  ]
}

# --- Read-write dynamic role ---
resource "vault_database_secret_backend_role" "app_readwrite" {
  backend     = vault_mount.database.path
  name        = "app-readwrite"
  db_name     = vault_database_secret_backend_connection.postgres.name

  default_ttl = 900
  max_ttl     = 1800

  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";",
  ]

  revocation_statements = [
    "REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM \"{{name}}\";",
    "DROP ROLE IF EXISTS \"{{name}}\";",
  ]
}
# HTH Guide Excerpt: end terraform

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------

variable "postgres_connection_url" {
  description = "PostgreSQL connection URL (e.g., postgresql://{{username}}:{{password}}@db.example.com:5432/mydb)"
  type        = string
  default     = ""
}

variable "postgres_admin_username" {
  description = "PostgreSQL admin username for Vault to manage dynamic credentials"
  type        = string
  default     = ""
}

variable "postgres_admin_password" {
  description = "PostgreSQL admin password for Vault to manage dynamic credentials"
  type        = string
  default     = ""
  sensitive   = true
}
