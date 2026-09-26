# =============================================================================
# HTH Pack Contract: v1
#   control: langchain-1.2
#   guide:   https://howtoharden.com/guides/langchain/#12-use-workspace-scoped-service-keys-not-personal-access-tokens
#   profile: L1
#   mode:    mutating
#   requires: LANGSMITH_API_KEY(organization-scoped service key with Organization Admin; read by the provider from the environment), LANGSMITH_ENDPOINT(optional, regional or self-hosted API URL), LANGSMITH_WORKSPACE_ID(optional)
#
# HTH LangChain Control 1.2: Use Workspace-Scoped Service Keys, Not Personal Access Tokens
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 5.6 | NIST 800-53 IA-5, AC-2(7)
#
# THE PROVIDER BLOCK FOR packs/langchain/terraform/ LIVES IN THIS FILE.
#
# Official provider: registry.terraform.io/providers/langchain-ai/langsmith (0.0.16,
# published 2026-09-19; source github.com/langchain-ai/terraform-provider-langsmith),
# documented at https://docs.langchain.com/langsmith/manage-with-terraform.
# Schema checked with `terraform providers schema` against 0.0.16 on 2026-09-24:
#   langsmith_service_key: description (required), workspaces, expires_at, role_id,
#   org_role_id; computed key (sensitive), short_key, access_scope, workspace_names
#
# TRAPS
#  1. The minted secret (`key`) is stored in Terraform state. Use an encrypted remote
#     backend with tight access, and read the key out of state into your secrets manager.
#  2. Omitting `workspaces` makes an organization-scoped key. Name exactly one workspace.
#  3. The provider is not the community `bogware/langsmith` provider; the resource
#     names differ.
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    langsmith = {
      source  = "langchain-ai/langsmith"
      version = "~> 0.0.16"
    }
  }
}

# Credentials resolve from LANGSMITH_API_KEY / LANGSMITH_ENDPOINT (never hardcoded).
provider "langsmith" {}

# HTH Guide Excerpt: begin terraform-workspace-service-key
variable "ci_workspace_id" {
  description = "The one workspace the CI service key may use"
  type        = string
}

variable "ci_service_key_expires_at" {
  description = "RFC 3339 expiry for the CI service key (90 days or less; rotate before it lapses)"
  type        = string
}

# Workspace-scoped, expiring service key for an unattended workload (never a PAT)
resource "langsmith_service_key" "ci_pipeline_prod" {
  description = "ci-pipeline-prod"
  workspaces  = [var.ci_workspace_id]
  expires_at  = var.ci_service_key_expires_at

  lifecycle {
    postcondition {
      condition     = self.access_scope == "workspace"
      error_message = "The CI service key must be workspace-scoped, not organization-scoped."
    }
  }
}

output "ci_service_key_short" {
  description = "Non-secret identifier of the key; the secret itself is only in state"
  value       = langsmith_service_key.ci_pipeline_prod.short_key
}
# HTH Guide Excerpt: end terraform-workspace-service-key
