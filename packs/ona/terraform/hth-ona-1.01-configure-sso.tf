# =============================================================================
# HTH Pack Contract: v1
#   control: ona-1.1
#   guide:   https://howtoharden.com/guides/ona/#11-enforce-sso-with-domain-verification
#   profile: L1
#   mode:    mutating
#   requires: ONA_TOKEN(read-write PAT)
#
# HTH Ona Control 1.1: Enforce SSO with Domain Verification
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 6.7, 12.5 | NIST 800-53 IA-2, IA-8 | SOC 2 CC6.1
# Source: https://howtoharden.com/guides/ona/#11-enforce-sso-with-domain-verification
#
# Transcribed from the provider registry doc fetched 2026-08-19 and saved at
# https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/resources/sso_configuration (registry v2
# provider-doc 13236814, provider-version 105656 = 0.4.0-beta.1). Every argument
# below appears in that schema.
#
# THIS FILE CARRIES THE PROVIDER BLOCK FOR THE WHOLE ona TERRAFORM PACK SET.
# Every other hth-ona-*.tf pack omits `terraform {}` / `provider "ona" {}` and
# points here. Copy this block once into your root module.
#
# WHY TERRAFORM FOR THIS CONTROL: ona_sso_configuration is the only surface that
# expresses the whole OIDC configuration — issuer, client id, write-only client
# secret, allowed email domains, extra scopes, the CEL claims expression, and the
# active/inactive state — as one reviewable object under version control.
#
# TRAPS
#  1. BETA PROVIDER. 0.4.0-beta.1 published 2026-08-15; all 51 published versions
#     are 0.x-beta.N. The vendor's own guidance: "Pin an exact version, review each
#     upgrade, and test upgrades outside production before broad rollout." The
#     `version` below is an exact pin (`=`) for that reason, not a `~>` range.
#  2. LINUX ONLY. The provider publishes Linux amd64 and Linux arm64 packages only
#     — no macOS, no Windows. `terraform init` fails on a Mac or Windows
#     workstation; run it from Linux CI or a Linux container. Terraform CLI >= 1.14.
#  3. NAMESAKE COLLISION. A different, unrelated `combor/ona` provider exists in
#     the registry. Always write source = "gitpod-io/ona". Never `ona/ona`, never
#     a bare `ona`.
#  4. DOMAIN VERIFICATION IS CLICKOPS. The provider exposes no resource for the
#     DNS TXT domain-verification record. "Sign in with SSO" does not appear on the
#     login screen until the domain is verified, so this resource can apply cleanly
#     and still leave users unable to use SSO. Do the DNS step first.
#  5. client_secret IS A WRITE-ONLY ARGUMENT (Terraform >= 1.11). It is sent to Ona
#     and is NOT stored in plan or state. Terraform therefore cannot detect that the
#     remote secret changed: rotation only happens when you also change
#     `client_secret_version`. Changing the secret value alone can leave the remote
#     value unchanged.
#  6. email_domains CANNOT BE CLEARED through Terraform — the Ona API rejects it.
#     Omit the attribute entirely to leave it unmanaged; do not set it to [].
#  7. SSO CANNOT BE MANDATED ORG-WIDE and at least one provider must stay active.
#     A valid SSO login alone can still create a membership. Pair this pack with
#     hth-ona-1.02 (restrict_account_creation_to_scim) or the join path stays open.
#  8. Registry doc lag: the provider's overview page still says "The current
#     published version is 0.3.0-beta.48" while serving the 0.4.0-beta.1 schema.
#     Trust the version index, not that sentence.
# =============================================================================

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
terraform {
  # The provider publishes Linux amd64/arm64 packages only and requires CLI >= 1.14.
  required_version = ">= 1.14"

  required_providers {
    ona = {
      # gitpod-io/ona is the vendor's provider. An unrelated `combor/ona` also
      # exists in the registry — the source line is what tells them apart.
      source = "gitpod-io/ona"
      # Exact pin: every published version is a beta. Review each upgrade.
      version = "0.4.0-beta.1"
    }
  }
}

# Reads ONA_TOKEN from the environment. Use a read-write personal access token:
# service-account tokens are documented for reads and automation starts only,
# unless Ona has confirmed write support for your organization.
# Set ONA_HOST only for a non-default Ona application host.
provider "ona" {}

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
