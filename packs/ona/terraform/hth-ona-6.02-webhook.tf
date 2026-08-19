# =============================================================================
# HTH Pack Contract: v1
#   control: ona-6.2
#   guide:   https://howtoharden.com/guides/ona/#62-secure-webhooks-with-hmac-verification
#   profile: L2
#   mode:    mutating
#   requires: ONA_TOKEN(read-write PAT)
#
# HTH Ona Control 6.2: Secure Webhooks with HMAC Verification
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 8.2 | NIST 800-53 SC-8, AU-10
# Source: https://howtoharden.com/guides/ona/#62-secure-webhooks-with-hmac-verification
#
# PROVIDER BLOCK LIVES IN hth-ona-1.01-configure-sso.tf.
#
# Transcribed from registry docs fetched 2026-08-19:
#   https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/resources/webhook                 (doc 13236821)
#   https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/ephemeral-resources/webhook_secret (doc 13236823)
# both for provider-version 105656 = 0.4.0-beta.1.
#
# WHY TERRAFORM FOR THIS CONTROL: rotation is the whole control, and rotation here
# is a marker bump — `secret_version`. Under version control, "when did we last
# rotate this signing secret" is answerable from git log instead of from memory.
# The ephemeral companion resource is what lets the rotated secret reach your
# receiver without ever landing in state.
#
# TRAPS
#  1. A PAT IS MANDATORY, A SERVICE-ACCOUNT TOKEN WILL NOT DO. Verbatim: "Webhooks
#     must be created with a user or administrator credential because the Ona API
#     does not allow service accounts to create them." A CI pipeline running on a
#     service-account token cannot apply this pack.
#  2. ROTATION INVALIDATES THE OLD SECRET IMMEDIATELY. Changing secret_version
#     rotates the signing secret "and immediately invalidates its previous value".
#     There is no overlap window: update your receiver in the same change or every
#     in-flight delivery fails signature verification.
#  3. THE SECRET IS NEVER IN THIS RESOURCE. ona_webhook does not expose it —
#     "The secret itself is never stored in this resource's state." Retrieve it
#     only through the EPHEMERAL ona_webhook_secret resource, whose value is not
#     written to plan or state, and which may only be referenced from an ephemeral
#     context (a write-only argument, a provider block, or a child module's
#     ephemeral output). You cannot `output` it — that restriction is the feature.
#     Never call the API's GetWebhookSecret from an evidence script; it is a
#     credential-disclosing Get.
#  4. HMAC VERIFICATION IS YOUR RECEIVER'S JOB. Ona signs; nothing in this schema
#     makes your consumer check the signature. An unverified receiver accepts
#     spoofed payloads no matter how this resource is configured. Verify with a
#     constant-time comparison, and reject on mismatch.
#  5. DESTROY HAS A BLAST RADIUS BEYOND THE WEBHOOK. Removing this resource
#     "deletes the webhook and converts triggers on bound workflows to manual
#     triggers" — automations silently stop firing rather than erroring.
#  6. type AND scm_provider FORCE REPLACEMENT, and the two scope attributes are
#     mutually exclusive: repository_scopes for type "repository" (1-100 entries),
#     organization_scope for type "organization". Setting both fails.
#  7. ENTERPRISE GATING ON THE READ PATH. WebhookService/ListWebhooks returns
#     HTTP 400 failed_precondition "feature is only available for enterprise
#     customers" on non-enterprise organizations (verified live 2026-08-19). Treat
#     that as a precondition, not as "no webhooks configured".
#  8. WEBHOOK MANAGEMENT IS AN ORG-ADMIN DUTY. The automations_admin delegated
#     role deliberately cannot manage webhooks — do not try to delegate this to it
#     (see pack 1.03).
# =============================================================================

variable "webhook_name" {
  description = "Webhook display name. 1-80 characters."
  type        = string
  default     = "hth-scm-events"
}

variable "webhook_description" {
  description = "What this webhook is for. Maximum 500 characters."
  type        = string
  default     = "SCM events consumed by an HMAC-verifying receiver."
}

variable "webhook_scm_provider" {
  description = "SCM provider. Supported values are github, gitlab, bitbucket. Changing it REPLACES the webhook."
  type        = string
  default     = "github"

  validation {
    condition     = contains(["github", "gitlab", "bitbucket"], var.webhook_scm_provider)
    error_message = "webhook_scm_provider must be one of: github, gitlab, bitbucket."
  }
}

variable "webhook_organization_scope" {
  description = "SCM organization this webhook covers. host is e.g. github.com."
  type = object({
    host = string
    name = string
  })
  default = {
    host = "github.com"
    name = "example-organization"
  }
}

variable "webhook_secret_version" {
  description = "Rotation marker. Bumping it rotates the signing secret and INVALIDATES THE OLD ONE IMMEDIATELY — update the receiver in the same change."
  type        = string
  default     = "v1"
}

# HTH Guide Excerpt: begin terraform
resource "ona_webhook" "scm_events" {
  name        = var.webhook_name
  description = var.webhook_description

  # "organization" scope: one webhook for every repository in the SCM org. Use
  # type = "repository" with repository_scopes instead to narrow it. The two
  # scope attributes are mutually exclusive.
  type         = "organization"
  scm_provider = var.webhook_scm_provider

  organization_scope = {
    host = var.webhook_organization_scope.host
    name = var.webhook_organization_scope.name
  }

  # Bumping this rotates the HMAC signing secret. The previous value stops
  # verifying immediately — there is no overlap window.
  secret_version = var.webhook_secret_version
}

# Ephemeral: retrieves the current signing secret WITHOUT writing it to plan or
# state. Ona audits this access and it requires webhook-update permission.
ephemeral "ona_webhook_secret" "scm_events" {
  webhook_id = ona_webhook.scm_events.id
}

# Consume the secret ONLY from an ephemeral context. Uncomment and point `source`
# at a module of yours that writes it to your receiver's secret store through an
# ephemeral variable or a write-only argument:
#
# module "webhook_secret_target" {
#   source         = "./modules/webhook-secret-target"
#   webhook_secret = ephemeral.ona_webhook_secret.scm_events.secret
# }
#
# It cannot be surfaced as a normal output, and it must never be echoed to logs.
# HTH Guide Excerpt: end terraform

output "ona_webhook_url" {
  description = "Generated webhook endpoint URL. Not a secret — the HMAC signature is what authenticates a delivery."
  value       = ona_webhook.scm_events.url
}

output "ona_webhook_secret_version" {
  description = "Current rotation marker. Diff this against your receiver's configured secret version after every rotation."
  value       = ona_webhook.scm_events.secret_version
}
