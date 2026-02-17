# =============================================================================
# HTH HashiCorp Vault Control 1.1: Implement Least-Privilege Auth Methods
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-2, IA-5, AC-2 | SOC 2 CC6.1, CC6.2 | ISO 27001 A.9.2.1
# Source: https://howtoharden.com/guides/hashicorp-vault/#11-implement-least-privilege-auth-methods
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }
}

# HTH Guide Excerpt: begin terraform
# --- OIDC Auth Method (preferred for human users) ---
resource "vault_jwt_auth_backend" "oidc" {
  description        = "OIDC authentication for human users"
  path               = "oidc"
  type               = "oidc"
  oidc_discovery_url = var.oidc_discovery_url
  oidc_client_id     = var.oidc_client_id
  oidc_client_secret = var.oidc_client_secret
  default_role       = "default"

  tune {
    default_lease_ttl  = "1h"
    max_lease_ttl      = "4h"
    token_type         = "default-service"
  }
}

resource "vault_jwt_auth_backend_role" "oidc_default" {
  backend        = vault_jwt_auth_backend.oidc.path
  role_name      = "default"
  role_type      = "oidc"
  token_policies = ["default"]
  user_claim     = "email"
  groups_claim   = "groups"

  allowed_redirect_uris = var.oidc_redirect_uris

  token_ttl     = 3600
  token_max_ttl = 14400
}

# --- AppRole Auth Method (for CI/CD and automation) ---
resource "vault_auth_backend" "approle" {
  type        = "approle"
  path        = "approle"
  description = "AppRole authentication for CI/CD pipelines and automation"

  tune {
    default_lease_ttl = "30m"
    max_lease_ttl     = "1h"
  }
}

resource "vault_approle_auth_backend_role" "ci_cd" {
  backend        = vault_auth_backend.approle.path
  role_name      = "ci-cd"
  token_policies = ["ci-cd-read"]

  token_ttl          = 1800
  token_max_ttl      = 3600
  secret_id_num_uses = 1
  secret_id_ttl      = 600
  token_num_uses     = 10
}

# --- Kubernetes Auth Method (for workloads running in K8s) ---
resource "vault_auth_backend" "kubernetes" {
  type        = "kubernetes"
  path        = "kubernetes"
  description = "Kubernetes authentication for in-cluster workloads"

  tune {
    default_lease_ttl = "15m"
    max_lease_ttl     = "1h"
  }
}

resource "vault_kubernetes_auth_backend_config" "k8s" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = var.kubernetes_host
  kubernetes_ca_cert = var.kubernetes_ca_cert
  issuer             = var.kubernetes_issuer
}
# HTH Guide Excerpt: end terraform

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------

variable "oidc_discovery_url" {
  description = "OIDC provider discovery URL (e.g., https://accounts.google.com)"
  type        = string
  default     = ""
}

variable "oidc_client_id" {
  description = "OIDC client ID"
  type        = string
  default     = ""
}

variable "oidc_client_secret" {
  description = "OIDC client secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "oidc_redirect_uris" {
  description = "Allowed OIDC redirect URIs"
  type        = list(string)
  default     = ["http://localhost:8250/oidc/callback", "https://vault.example.com:8200/ui/vault/auth/oidc/oidc/callback"]
}

variable "kubernetes_host" {
  description = "Kubernetes API server URL"
  type        = string
  default     = "https://kubernetes.default.svc"
}

variable "kubernetes_ca_cert" {
  description = "PEM-encoded Kubernetes CA certificate"
  type        = string
  default     = ""
}

variable "kubernetes_issuer" {
  description = "Kubernetes service account JWT issuer"
  type        = string
  default     = ""
}
