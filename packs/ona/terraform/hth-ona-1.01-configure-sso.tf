# HTH Pack Contract: v1
#   control: ona-1.1
#   guide: https://howtoharden.com/guides/ona/#11-enforce-sso-with-domain-verification
#   profile: L1
#   mode: mutating
#   requires: ONA_TOKEN(read-write PAT); Terraform>=1.14, Linux; shared versions.tf
# Source: https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/sso_configuration.md
# Fetched 2026-11-05. Configure DNS domain verification separately before adoption.
# Copy versions.tf once. Import existing configurations and review the plan.
# client_secret is write-only; bump client_secret_version when rotating.
# email_domains cannot be cleared through the current API.
# No plan/apply or credential creation was performed during this refresh.

variable "sso_display_name" {
  description = "Display name shown for this SSO configuration. Maximum 128 characters."
  type        = string
  default     = "Corporate IdP"
}

variable "sso_issuer_url" {
  description = "OIDC issuer URL for the identity provider, e.g. https://acme.okta.com"
  type        = string
}

variable "sso_client_id" {
  description = "OIDC application client ID from the identity provider."
  type        = string
}

variable "sso_client_secret" {
  description = "OIDC application client secret. Write-only: sent to Ona, never stored in Terraform plan or state. Supply from a secrets manager, never a literal."
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "sso_client_secret_version" {
  description = "Rotation marker. Change this whenever sso_client_secret changes, or the remote secret may stay unchanged."
  type        = string
  default     = "v1"
}

variable "sso_email_domains" {
  description = "Email domains allowed to sign in through this SSO configuration. The Ona API cannot clear all domains via Terraform."
  type        = set(string)
  default     = ["example.com"]
}

variable "sso_additional_scopes" {
  description = "Additional OIDC scopes requested during sign-in. 'groups' is required if your CEL claims expression reads group claims."
  type        = set(string)
  default     = ["groups"]
}

variable "sso_claims_expression" {
  description = "CEL expression evaluated against OIDC token claims at login. Empty string clears it."
  type        = string
  default     = "claims.email_verified"
}

# HTH Guide Excerpt: begin terraform
resource "ona_sso_configuration" "corp" {
  display_name = var.sso_display_name
  issuer_url   = var.sso_issuer_url
  client_id    = var.sso_client_id

  # Write-only argument: sent to Ona, absent from plan and state. Rotation is
  # driven by client_secret_version, not by the value changing.
  client_secret         = var.sso_client_secret
  client_secret_version = var.sso_client_secret_version

  email_domains     = var.sso_email_domains
  additional_scopes = var.sso_additional_scopes

  # Conditional access evaluated at login. Example requires a verified email.
  claims_expression = var.sso_claims_expression

  # "active" is what makes the configuration usable; "inactive" leaves it defined
  # but unusable. provider_type is read-only and reads `custom` for anything
  # Terraform manages.
  state = "active"
}
# HTH Guide Excerpt: end terraform

output "ona_sso_configuration_id" {
  description = "SSO configuration ID. Feed this to hth-ona-1.02 as sso_configuration_id."
  value       = ona_sso_configuration.corp.id
}
