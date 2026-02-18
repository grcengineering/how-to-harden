# =============================================================================
# HTH SendGrid Control 4.2: Configure Event Webhooks
# Profile Level: L2 (Hardened)
# Frameworks: CIS 8.2, NIST AU-6
# Source: https://howtoharden.com/guides/sendgrid/#42-configure-event-webhooks
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "sendgrid_event_webhook" "security" {
  count = var.profile_level >= 2 && var.event_webhook_url != "" ? 1 : 0

  url           = var.event_webhook_url
  enabled       = true
  signed        = true
  friendly_name = "HTH Security Event Webhook"

  # Delivery events
  processed = true
  delivered = true
  dropped   = true
  bounce    = true
  deferred  = true

  # Engagement events
  open  = true
  click = true

  # Abuse events
  spam_report       = true
  unsubscribe       = true
  group_unsubscribe = true
  group_resubscribe = true
}
# HTH Guide Excerpt: end terraform
