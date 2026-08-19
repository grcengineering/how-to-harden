# =============================================================================
# HTH Pack Contract: v1
#   control: ona-4.2
#   guide:   https://howtoharden.com/guides/ona/#42-use-oidc-workload-identity-for-keyless-cloud-access
#   profile: L2
#   mode:    mutating
#   requires: ONA_TOKEN(read-write PAT)
#
# HTH Ona Control 4.2: Use OIDC Workload Identity for Keyless Cloud Access
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 3.3, 16.9 | NIST 800-53 IA-5, AC-3
# Source: https://howtoharden.com/guides/ona/#42-use-oidc-workload-identity-for-keyless-cloud-access
#
# PROVIDER BLOCK LIVES IN hth-ona-1.01-configure-sso.tf.
#
# Transcribed from https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/resources/oidc_config
# (registry v2 provider-doc 13236798, provider-version 105656 = 0.4.0-beta.1).
# The full supported-value list below is verbatim from that schema.
#
# WHY TERRAFORM FOR THIS CONTROL: the set of custom `sub` claim fields is the
# contract your cloud IAM trust policy is written against. If someone removes a
# field here, every trust policy that conditions on it silently stops matching —
# or, worse, starts matching more broadly. That set belongs under review.
#
# TRAPS
#  1. THIS IS ONLY THE ONA HALF. The keyless story is two-sided: this resource
#     shapes the `sub` claim Ona issues; your cloud IAM must then constrain its
#     trust policy on those claim values. Applying this alone changes nothing
#     about who can assume what. Write the cloud-side condition in the same
#     change.
#  2. SINGLETON, AND DESTROY DOES NOT RESET. Verbatim: "Destroying this resource
#     removes Terraform state only; it does not reset the remote organization
#     setting." Unlike ona_organization_policies, a destroy here leaves the remote
#     claim configuration exactly as it was. Import ID is `current`.
#  3. NARROWER IS NOT AUTOMATICALLY SAFER. Removing a field from this set removes
#     it from the `sub` claim, so a cloud trust policy that conditions on it stops
#     matching — that fails closed, which is survivable. ADDING a field changes
#     the `sub` string shape and can also break existing conditions. Either
#     direction is a breaking change to a live trust relationship; roll it out
#     with the cloud-side policy, not before it.
#  4. FIELDS ARE PRINCIPAL-DEPENDENT. Verbatim: "A field is included only for
#     principal types that provide it." A trust policy that requires
#     creator_email will never match a token minted for a service-account
#     principal that has no creator email. Condition on fields the calling
#     principal actually carries.
#  5. THE SUPPORTED SET IS FIXED. Only these values are accepted: creator_id,
#     creator_principal, creator_email, creator_name, creator_idp, account_id,
#     user_id, organization_id, project_id, runner_id, environment_id, email,
#     name, idp, runner_name, service_account_id,
#     environment_initializers.git.remote_uri,
#     environment_initializers.git.upstream_remote_uri,
#     environment_initializers.context_url. Anything else is rejected.
#  6. GetOIDCConfig RETURNS 404 WHEN UNCONFIGURED. Evidence scripts must report
#     "not configured" as a finding, not crash on the not_found.
# =============================================================================

variable "oidc_custom_claim_fields" {
  description = "Additional fields included in the OIDC V3 sub claim. Must be drawn from the provider's fixed supported list; a field appears only for principal types that provide it."
  type        = set(string)
  default = [
    # Coarse tenancy boundary — the minimum any cloud trust policy should pin.
    "organization_id",
    # Scopes the trust to a reviewed project rather than "any Ona workload".
    "project_id",
    # Attribution for the human behind the workload.
    "creator_email",
    # Lets a trust policy distinguish a specific environment or runner.
    "environment_id",
    "runner_name",
  ]

  validation {
    condition = alltrue([
      for f in var.oidc_custom_claim_fields : contains([
        "creator_id", "creator_principal", "creator_email", "creator_name",
        "creator_idp", "account_id", "user_id", "organization_id", "project_id",
        "runner_id", "environment_id", "email", "name", "idp", "runner_name",
        "service_account_id",
        "environment_initializers.git.remote_uri",
        "environment_initializers.git.upstream_remote_uri",
        "environment_initializers.context_url",
      ], f)
    ])
    error_message = "oidc_custom_claim_fields contains a value outside the provider's supported list."
  }
}

# HTH Guide Excerpt: begin terraform
resource "ona_oidc_config" "org" {
  # These fields become part of the OIDC V3 `sub` claim. Your cloud IAM trust
  # policy conditions on them — change this set and the cloud side in one change,
  # never separately.
  custom_claim_fields = var.oidc_custom_claim_fields
}
# HTH Guide Excerpt: end terraform

output "ona_oidc_custom_claim_fields" {
  description = "The claim fields your cloud trust policies may condition on. Treat this as an interface contract."
  value       = ona_oidc_config.org.custom_claim_fields
}
