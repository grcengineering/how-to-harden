# =============================================================================
# HTH Fivetran Control 1.4: Configure Session Timeout
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.2, NIST AC-12
# Source: https://howtoharden.com/guides/fivetran/#14-configure-session-timeout
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure session timeout for dashboard access
# Shorter timeouts reduce risk of session hijacking
#
# Recommended values by profile level:
#   L1 (Baseline):          60 minutes (1 hour)
#   L2 (Hardened):          30 minutes
#   L3 (Maximum Security):  15 minutes
resource "null_resource" "configure_session_timeout" {
  triggers = {
    profile_level   = var.profile_level
    timeout_minutes = var.session_timeout_minutes
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X PATCH \
        "https://api.fivetran.com/v1/account/config" \
        -H "Authorization: Basic $(echo -n '${var.fivetran_api_key}:${var.fivetran_api_secret}' | base64)" \
        -H "Content-Type: application/json" \
        -d '{
          "session_timeout": ${var.session_timeout_minutes}
        }'
    EOT
  }
}
# HTH Guide Excerpt: end terraform
