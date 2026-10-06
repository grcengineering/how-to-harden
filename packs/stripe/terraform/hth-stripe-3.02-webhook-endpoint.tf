# =============================================================================
# HTH Pack Contract: v1
#   control: stripe-3.2
#   guide:   https://howtoharden.com/guides/stripe/#32-configure-webhook-security
#   profile: L2
#   mode:    mutating
#   requires: STRIPE_API_KEY(restricted key with Webhook Endpoints: Write; apply with a sandbox key first)
#
# HTH Stripe Control 3.2: Configure Webhook Security
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 3.11 | NIST 800-53 SC-8
# Source: https://howtoharden.com/guides/stripe/#32-configure-webhook-security
#
# Transcribed from the registry docs for stripe/stripe 0.3.0 (provider-version
# 105537), fetched 2026-09-24:
#   https://registry.terraform.io/providers/stripe/stripe/0.3.0/docs                            (doc 13221499)
#   https://registry.terraform.io/providers/stripe/stripe/0.3.0/docs/resources/webhook_endpoint (doc 13221560)
# and Stripe's own index at https://docs.stripe.com/terraform/resources ("Webhook
# endpoints"). Every argument below appears in that schema; every event type is
# in the enabled_events enum of POST /v1/webhook_endpoints in Stripe's OpenAPI spec.
#
# WHY TERRAFORM FOR THIS CONTROL: webhook endpoints accrete. Declaring the set you
# own turns an endpoint nobody remembers creating into a plan diff, and keeps the
# account under Stripe's limit of 16 endpoints by construction.
#
# TRAPS
#  1. 0.x PROVIDER. Pin an exact version and review each upgrade; resource schemas
#     can still change between 0.x releases.
#  2. THE SIGNING SECRET LANDS IN STATE. `secret` is a Sensitive, read-only
#     attribute that Stripe returns only at creation, and Terraform stores it in
#     state. Use an encrypted remote backend with restricted access, never output
#     it, and read it from state into your secrets manager once.
#  3. NO DATA SOURCES. Provider 0.3.0 ships resources and ephemeral resources but
#     no data sources, so Terraform can set this control but not audit an account
#     it does not manage. The read-only audit is packs/stripe/api/hth-stripe-3.02.
#  4. THE KEY COMES FROM THE ENVIRONMENT. The provider reads STRIPE_API_KEY; do not
#     set api_key in HCL, where it would be committed or written to plan files.
# =============================================================================

# HTH Guide Excerpt: begin terraform-webhook-endpoint
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    stripe = {
      source  = "stripe/stripe"
      version = "= 0.3.0"
    }
  }
}

# Reads the API key from the STRIPE_API_KEY environment variable.
provider "stripe" {}

variable "security_webhook_url" {
  description = "HTTPS URL that receives Stripe security events (your SIEM collector or handler)"
  type        = string

  validation {
    condition     = startswith(var.security_webhook_url, "https://")
    error_message = "Stripe webhook endpoints must be HTTPS; Stripe supports only TLS 1.2 and 1.3."
  }
}

resource "stripe_webhook_endpoint" "security_events" {
  url         = var.security_webhook_url
  description = "HTH security events"

  enabled_events = [
    "account.updated",
    "account.application.authorized",
    "account.application.deauthorized",
    "account.external_account.created",
    "account.external_account.deleted",
    "capability.updated",
    "person.created",
    "person.updated",
    "person.deleted",
    "payment_method.attached",
    "payment_method.detached",
    "identity.verification_session.created",
    "identity.verification_session.verified",
  ]
}
# HTH Guide Excerpt: end terraform-webhook-endpoint
