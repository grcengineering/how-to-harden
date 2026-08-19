# =============================================================================
# HTH Pack Contract: v1
#   control: ona-1.2
#   guide:   https://howtoharden.com/guides/ona/#12-enforce-scim-provisioning-and-restrict-account-creation
#   profile: L1
#   mode:    mutating
#   requires: ONA_TOKEN(read-write PAT)
#
# HTH Ona Control 1.2: Enforce SCIM Provisioning and Restrict Account Creation
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 5.3, 6.2 | NIST 800-53 AC-2 | SOC 2 CC6.2
# Source: https://howtoharden.com/guides/ona/#12-enforce-scim-provisioning-and-restrict-account-creation
#
# PROVIDER BLOCK LIVES IN hth-ona-1.01-configure-sso.tf. Copy that file's
# terraform{} / provider "ona" {} block once into your root module.
#
# Transcribed from registry docs fetched 2026-08-19:
#   https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/resources/scim_configuration     (doc 13236808)
#   https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/resources/organization_policies  (doc 13236800)
# both for provider-version 105656 = 0.4.0-beta.1.
#
# SINGLETON — merge these attributes into ONE ona_organization_policies resource
# if you adopt more than one pack; two resources managing the same object drift
# forever. Packs 1.02, 2.02, 2.03, 2.04, 3.01, 3.02, 3.03, 3.04 and 5.01 each
# touch this same singleton object (import ID `current`).
#
# WHY TERRAFORM FOR THIS CONTROL: the SCIM configuration and the policy toggle
# that gives it teeth are two different API objects, and getting only one of them
# is the common failure. Declaring both here makes "SCIM enabled but joins still
# open" a visible diff instead of a silent gap.
#
# TRAPS
#  1. THE SCIM BEARER TOKEN IS NOT IN THIS RESOURCE. The provider deliberately
#     does not expose the one-time SCIM token in Terraform state — the resource
#     description says so explicitly. Read `token_expires_at` here for lifecycle
#     tracking, then collect the token itself from the Ona console once (it is
#     shown once and is unrecoverable) and put it straight into your secrets
#     manager for the IdP side.
#  2. token_expires_in FORCES REPLACEMENT. Changing it replaces the resource,
#     which mints a new SCIM token and breaks the IdP integration until you
#     re-enter the new token. Range: minimum 24h, maximum 17520h (2 years).
#  3. ORDER MATTERS. The restrict-account-creation toggle is meaningless — and in
#     the console stays disabled — until SCIM is configured and enabled. Apply
#     SCIM first; the depends_on below encodes that.
#  4. PROTO3 OMITS DEFAULTS. On the read path a false boolean is simply absent
#     from the API response. Absent restrict_account_creation_to_scim means
#     FALSE (open joins), never "compliant". Terraform hides this, but any
#     evidence script reading the API must treat absence as the insecure value.
#  5. DESTROY IS NOT DELETE for ona_organization_policies. Destroying it restores
#     the server-defined policy configuration captured before Terraform first
#     managed the organization — which may re-open account creation.
#  6. allow_unverified_email_account_linking = true lets SCIM bind a provisioned
#     identity to a pre-existing account on an email the IdP never verified. Keep
#     it false unless you have a specific, reviewed migration reason.
# =============================================================================

variable "scim_sso_configuration_id" {
  description = "SSO configuration ID to link SCIM to. Use the output of hth-ona-1.01 (ona_sso_configuration.corp.id)."
  type        = string
}

variable "scim_name" {
  description = "Human-readable SCIM configuration name."
  type        = string
  default     = "Corporate SCIM"
}

variable "scim_token_expires_in" {
  description = "Initial SCIM token lifetime. Minimum 24h, maximum 17520h. CHANGING THIS REPLACES THE RESOURCE and mints a new token."
  type        = string
  default     = "8760h"
}

# HTH Guide Excerpt: begin terraform
resource "ona_scim_configuration" "corp" {
  sso_configuration_id = var.scim_sso_configuration_id
  name                 = var.scim_name

  # SCIM is inert until enabled. The API has no `enabled` field on create, so a
  # one-call provisioning script leaves SCIM created-but-off; Terraform's
  # create-then-update flow is what closes that gap.
  enabled = true

  # Shortest lifetime the directory integration can live with. Replacing the
  # resource mints a new token — plan rotation windows deliberately.
  token_expires_in = var.scim_token_expires_in

  # Do not let SCIM claim an existing account on an email the IdP never verified.
  allow_unverified_email_account_linking = false
}

# The toggle that actually closes the uncontrolled-join path. SSO alone cannot be
# mandated org-wide, so without this a valid SSO login still creates a membership.
# SINGLETON: at most one ona_organization_policies per organization (import id "current") —
# merge these attributes with any other ona pack you adopt; two resources drift forever.
resource "ona_organization_policies" "scim_account_restriction" {
  restrict_account_creation_to_scim = true

  # Enabling the restriction before SCIM is live locks out legitimate joins.
  depends_on = [ona_scim_configuration.corp]
}
# HTH Guide Excerpt: end terraform

output "ona_scim_token_expires_at" {
  description = "RFC3339 expiry of the current SCIM token. Alert on this — an expired token silently stops deprovisioning."
  value       = ona_scim_configuration.corp.token_expires_at
}
