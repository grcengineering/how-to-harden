# =============================================================================
# HTH HashiCorp Vault Control 1.2: Implement Granular Policies
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-3, AC-6 | SOC 2 CC6.1, CC6.3 | ISO 27001 A.9.4.1
# Source: https://howtoharden.com/guides/hashicorp-vault/#12-implement-granular-policies
# =============================================================================

# HTH Guide Excerpt: begin terraform
# --- Base read-only policy for all authenticated users ---
resource "vault_policy" "base_read" {
  name   = "base-read"
  policy = <<-EOT
    # Allow lookup of own token capabilities
    path "sys/capabilities-self" {
      capabilities = ["update"]
    }

    # Allow reading own identity
    path "auth/token/lookup-self" {
      capabilities = ["read"]
    }

    # Allow renewing own token
    path "auth/token/renew-self" {
      capabilities = ["update"]
    }

    # Deny access to root-level system paths
    path "sys/raw/*" {
      capabilities = ["deny"]
    }

    path "sys/seal" {
      capabilities = ["deny"]
    }
  EOT
}

# --- Team-scoped policy (per-team secret paths) ---
resource "vault_policy" "team_secrets" {
  for_each = var.team_names

  name   = "team-${each.value}-secrets"
  policy = <<-EOT
    # Read and write secrets under team namespace
    path "secret/data/teams/${each.value}/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }

    path "secret/metadata/teams/${each.value}/*" {
      capabilities = ["list", "read", "delete"]
    }

    # Deny cross-team access
    path "secret/data/teams/*" {
      capabilities = ["deny"]
    }
  EOT
}

# --- CI/CD read-only policy (AppRole consumers) ---
resource "vault_policy" "ci_cd_read" {
  name   = "ci-cd-read"
  policy = <<-EOT
    # Read-only access to application secrets
    path "secret/data/apps/+/config" {
      capabilities = ["read"]
    }

    # Read dynamic database credentials
    path "database/creds/*" {
      capabilities = ["read"]
    }

    # Read PKI certificates
    path "pki/issue/*" {
      capabilities = ["read", "update"]
    }

    # Deny all write operations on secret engines
    path "secret/data/*" {
      capabilities = ["deny"]
    }
  EOT
}

# --- Admin policy (Vault operators) ---
resource "vault_policy" "admin" {
  name   = "vault-admin"
  policy = <<-EOT
    # Manage auth methods
    path "sys/auth/*" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    # Manage policies
    path "sys/policies/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }

    # Manage secret engines
    path "sys/mounts/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }

    # Read audit configuration
    path "sys/audit*" {
      capabilities = ["read", "list", "sudo"]
    }

    # Manage identity entities and groups
    path "identity/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }

    # Deny seal/unseal (requires root or auto-unseal)
    path "sys/seal" {
      capabilities = ["deny"]
    }

    path "sys/raw/*" {
      capabilities = ["deny"]
    }
  EOT
}
# HTH Guide Excerpt: end terraform

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------

variable "team_names" {
  description = "Set of team names to create scoped policies for"
  type        = set(string)
  default     = ["platform", "backend", "frontend"]
}
