# =============================================================================
# HTH Pack Contract: v1
#   control: ona-4.3
#   guide:   https://howtoharden.com/guides/ona/#43-scope-repository-access-to-least-privilege
#   profile: L2
#   mode:    mutating
#   requires: ONA_TOKEN(read-write PAT)
#
# HTH Ona Control 4.3: Scope Repository Access to Least Privilege
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 3.3, 6.8 | NIST 800-53 AC-3, AC-6
# Source: https://howtoharden.com/guides/ona/#43-scope-repository-access-to-least-privilege
#
# PROVIDER BLOCK LIVES IN hth-ona-1.01-configure-sso.tf.
#
# Transcribed from https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/resources/scm_integration
# (registry v2 provider-doc 13236809, provider-version 105656 = 0.4.0-beta.1).
#
# WHY TERRAFORM FOR THIS CONTROL: SCM integrations are per-runner, they hold
# stored credentials, and the guide's control is largely "do not leave unused ones
# around". A declared set is the only way an unused integration becomes a visible
# deletion rather than an invisible standing credential.
#
# TRAPS
#  1. THE CONTROL IS THE auth_mode CHOICE, AND OAUTH IS THE HARDENED ONE. Verbatim
#     from the schema, supported values are `oauth` and `pat`. With `pat` you must
#     additionally attach a personal access token through ona_git_authentication —
#     a long-lived credential on a human or service identity. Prefer `oauth`;
#     where the platform forces `pat` (Azure DevOps Server "currently requires
#     pat"), mint the PAT on a least-privilege service identity.
#  2. THE OAUTH SECRET IS WRITE-ONLY AND ROTATION IS MARKER-DRIVEN.
#     oauth_client_secret is sent to Ona and never stored in plan or state, so
#     Terraform cannot see that it changed. Rotation happens only when you also
#     change oauth_client_secret_version. Changing the secret alone can leave the
#     remote value unchanged.
#  3. host AND kind FORCE REPLACEMENT, AND SO DOES runner_id. Replacing an
#     integration revokes the stored credential and re-issues it; projects on that
#     runner lose repository access for the window. Never let that land during a
#     deploy freeze or an incident.
#  4. THE SCOPE IS BROAD BY PLATFORM DESIGN. The GitHub integration requests
#     all-repository access with scopes repo, read:user, user:email, workflow;
#     per-repository scoping is roadmap only. Nothing in this schema narrows it.
#     The honest least-privilege lever is WHICH identity backs the connection and
#     WHICH runner carries it — so keep sensitive repositories on their own runner
#     (pack 5.01) rather than assuming this resource scopes anything.
#  5. DELETION IS THE REVOCATION. Removing an unused integration removes its
#     stored credentials. That is the actual "revoke access" action for this
#     control — a `terraform destroy` of an integration block is not cleanup, it
#     is the control being applied.
#  6. `terraform validate` CANNOT PASS ON THIS PACK, AND THE CONFIG IS STILL
#     CORRECT. The provider's OAuth validator treats an UNKNOWN value as unset,
#     and `terraform validate` treats every root-module input variable as unknown
#     — even one with a default. So any variable-driven oauth_client_id fails:
#       Error: Missing OAuth Client ID
#       Set oauth_client_id when auth_mode is "oauth".
#     Measured on 0.4.0-beta.1 / Terraform 1.14 (linux/amd64), isolated with a
#     three-way probe: literal oauth_client_id -> "Success! The configuration is
#     valid."; the SAME config with `oauth_client_id = var.cid` (var carrying a
#     default) -> the error above. It is a validate-time artifact of unknown
#     values, not a defect in this configuration, and it does not occur at plan or
#     apply where the value is known. Do NOT hardcode a client id to silence it.
#     `terraform validate` cannot be told the value either — it does not accept
#     -var ("flag provided but not defined: -var", measured on 1.14). Gate this
#     pack in CI with `terraform plan -var=...` or a *.tfvars file instead.
#  7. issuer_url IS REQUIRED ONLY FOR azuredevops_entra + oauth;
#     virtual_directory ONLY FOR azuredevops_server. Setting them elsewhere is
#     noise; omitting them where required fails at apply.
# =============================================================================

variable "scm_runner_id" {
  description = "Runner ID this SCM integration belongs to. Use ona_runner.<name>.runner_id from pack 5.01. Changing it REPLACES the integration."
  type        = string
}

variable "scm_kind" {
  description = "SCM integration kind, e.g. github, azuredevops_entra, azuredevops_server. Changing it REPLACES the integration."
  type        = string
  default     = "github"
}

variable "scm_host" {
  description = "SCM host name, e.g. github.com. Changing it REPLACES the integration."
  type        = string
  default     = "github.com"
}

variable "scm_oauth_client_id" {
  description = "OAuth app client ID. Required when auth_mode is oauth. Deliberately has no default — see TRAP 6 for why a default would not help `terraform validate` either."
  type        = string
}

variable "scm_oauth_client_secret" {
  description = "OAuth app client secret. Write-only: sent to Ona, never stored in Terraform plan or state. Supply from a secrets manager."
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "scm_oauth_client_secret_version" {
  description = "Rotation marker. Change this whenever scm_oauth_client_secret changes, or the remote secret may stay unchanged."
  type        = string
  default     = "v1"
}

# HTH Guide Excerpt: begin terraform
resource "ona_scm_integration" "primary" {
  runner_id = var.scm_runner_id

  kind = var.scm_kind
  host = var.scm_host

  # OAuth over PAT. `pat` mode requires attaching a long-lived personal access
  # token via ona_git_authentication — a standing credential this control exists
  # to avoid. Only fall back to `pat` where the platform requires it (Azure DevOps
  # Server), and then mint it on a least-privilege service identity.
  auth_mode = "oauth"

  oauth_client_id = var.scm_oauth_client_id

  # Write-only: never enters plan or state. Rotation is driven by the version
  # marker below, not by this value changing.
  oauth_client_secret         = var.scm_oauth_client_secret
  oauth_client_secret_version = var.scm_oauth_client_secret_version
}
# HTH Guide Excerpt: end terraform

output "ona_scm_integration_auth_mode" {
  description = "Authentication mode actually in force. 'pat' means a long-lived token backs repository access."
  value       = ona_scm_integration.primary.auth_mode
}
