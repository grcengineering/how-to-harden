# =============================================================================
# HTH Pack Contract: v1
#   control: ona-1.4
#   guide:   https://howtoharden.com/guides/ona/#14-harden-service-accounts-and-personal-access-tokens
#   profile: L2
#   mode:    mutating
#   requires: ONA_TOKEN(read-write PAT)
#
# HTH Ona Control 1.4: Harden Service Accounts and Personal Access Tokens
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 5.4, 16.9 | NIST 800-53 IA-5, AC-2 | SOC 2 CC6.1
# Source: https://howtoharden.com/guides/ona/#14-harden-service-accounts-and-personal-access-tokens
#
# PROVIDER BLOCK LIVES IN hth-ona-1.01-configure-sso.tf.
#
# Transcribed from registry docs fetched 2026-08-19:
#   https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/resources/service_account                 (doc 13236812)
#   https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/ephemeral-resources/service_account_token (doc 13236822)
# both for provider-version 105656 = 0.4.0-beta.1.
#
# WHY TERRAFORM FOR THIS CONTROL: `valid_until` is a REQUIRED argument on
# ona_service_account. Declaring machine identities here makes "indefinite
# validity" impossible to express by accident — the expiry is a mandatory,
# reviewable field in the diff rather than a console default someone skipped.
#
# TRAPS
#  1. valid_until IS REQUIRED AND REPLACES THE RESOURCE when changed. Extending a
#     service account's life destroys and recreates it, which invalidates every
#     token minted against the old ID and drops its group memberships. Plan the
#     rotation window; do not discover this mid-incident.
#  2. NEVER COPY THE DOC'S "2099-01-01T00:00:00Z". The vendor example uses a
#     74-year expiry, which is indefinite validity wearing a timestamp. The guide's
#     rule is 30/60/90 days or one year. The default below is one year.
#  3. THE EPHEMERAL RESOURCE IS THE WHOLE POINT. ona_service_account_token is an
#     EPHEMERAL resource: the minted token is returned once and is never written to
#     Terraform plan or state. Contrast ona_runner_token (pack 5.01), an ordinary
#     managed resource whose token DOES persist in state. Sensitive is redaction,
#     not exclusion — only ephemeral keeps a credential out of the state file.
#  4. EPHEMERAL VALUES ARE REFERENCE-RESTRICTED. ephemeral.ona_service_account_token
#     .automation.token may only be read from an ephemeral context: a provider
#     block, a write-only argument, a provisioner, or a child module's ephemeral
#     output. You cannot `output` it and you cannot store it in a normal resource.
#     The consumption pattern is shown commented out below because a module block
#     pointing at a path you have not created breaks `terraform init`.
#  5. valid_for IS CAPPED BY THE ACCOUNT. "The API caps validity to the service
#     account expiry" — asking for 8760h against a 90-day account silently yields
#     the shorter lifetime. Read expires_at, do not assume valid_for.
#  6. SERVICE-ACCOUNT TOKENS ARE NOT PAT REPLACEMENTS. Ona documents them for API
#     reads and starting automations; the provider's own guidance is to use a
#     personal access token for Terraform WRITES unless Ona has confirmed
#     service-account write support for your organization. Bootstrap and rotate
#     with a human/admin token — service-account-to-service-account management is
#     not supported.
#  7. PERSONAL ACCESS TOKENS HAVE NO TERRAFORM RESOURCE. The PAT half of control
#     1.4 (shortest expiry, read-only scope, scope immutable after creation) is
#     ClickOps/API only. This pack covers the service-account half.
# =============================================================================

variable "service_account_name" {
  description = "Service account display name."
  type        = string
  default     = "terraform-automation"
}

variable "service_account_description" {
  description = "What this machine identity is for. Written into Ona; keep it specific enough to justify at review."
  type        = string
  default     = "Terraform automation for Ona organization policy"
}

variable "service_account_valid_until" {
  description = "RFC3339 expiry. NEVER indefinite. CHANGING THIS REPLACES the service account and invalidates its tokens."
  type        = string
  default     = "2027-08-19T00:00:00Z"
}

variable "service_account_token_valid_for" {
  description = "Requested token lifetime as a Go duration. The API caps this to the service account's own expiry."
  type        = string
  default     = "720h"
}

# HTH Guide Excerpt: begin terraform
resource "ona_service_account" "automation" {
  name        = var.service_account_name
  description = var.service_account_description

  # REQUIRED by the schema — there is no way to express "indefinite" here, which
  # is exactly why this control belongs in Terraform. Keep it short; changing it
  # replaces the account.
  valid_until = var.service_account_valid_until
}

# Ephemeral: the token value is returned once and is NOT written to plan or state.
# This is the only credential-issuing surface on the provider that keeps the
# secret out of the state file.
ephemeral "ona_service_account_token" "automation" {
  service_account_id = ona_service_account.automation.id
  description        = var.service_account_description
  valid_for          = var.service_account_token_valid_for
}

# Consume the token ONLY from an ephemeral context. Uncomment and point `source`
# at a module of yours that writes to a secrets manager through an ephemeral
# variable or a write-only argument:
#
# module "automation_token_secret" {
#   source                = "./modules/service-account-token-secret"
#   service_account_token = ephemeral.ona_service_account_token.automation.token
# }
#
# It cannot be surfaced as a normal output, and that restriction is the feature.
# HTH Guide Excerpt: end terraform

output "ona_service_account_expiry" {
  description = "Expiry of the machine identity. Alert before this date — expiry replaces, it does not renew."
  value       = ona_service_account.automation.valid_until
}
