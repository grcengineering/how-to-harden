# =============================================================================
# HTH Twilio Control 3.2: Configure Webhook Security
# Profile Level: L2 (Hardened)
# Frameworks: CIS 3.11, NIST SC-8
# Source: https://howtoharden.com/guides/twilio/#32-configure-webhook-security
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Webhook security requires signature validation and HTTPS enforcement.
# The Twilio provider does not have a native webhook validation resource,
# so this documents the expected security posture and provides a
# validation checkpoint.

resource "null_resource" "webhook_security_validation" {
  count = var.profile_level >= 2 ? 1 : 0

  triggers = {
    profile_level      = var.profile_level
    allowed_ip_cidrs   = jsonencode(var.webhook_allowed_ip_cidrs)
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================================"
      echo "HTH Twilio 3.2: Webhook Security Configuration"
      echo "============================================================"
      echo ""
      echo "Webhook security must be enforced in application code and"
      echo "infrastructure configuration."
      echo ""
      echo "Required controls:"
      echo "  1. Validate X-Twilio-Signature on ALL webhook endpoints"
      echo "  2. Use HTTPS only for callback URLs"
      echo "  3. Reject requests with invalid signatures"
      echo ""
      if [ "${var.profile_level}" -ge 2 ]; then
        echo "L2+ controls:"
        echo "  4. Implement IP allowlisting for webhook origins"
        echo "  5. Monitor webhook endpoints for anomalies"
        echo "  6. Rotate webhook signing secrets regularly"
      fi
      echo ""
      echo "Twilio webhook source IPs are published at:"
      echo "  https://www.twilio.com/docs/sip-trunking/ip-addresses"
      echo ""
      echo "Validation: Send a test webhook and confirm signature check."
      echo "============================================================"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
