# =============================================================================
# HTH Auth0 Control 5.1: Enable Logging and Monitoring
# Profile Level: L1 (Baseline)
# Frameworks: NIST AU-2, AU-6 | CIS 8.2
# Source: https://howtoharden.com/guides/auth0/#51-enable-logging-and-monitoring
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "auth0_log_stream" "siem" {
  name   = "SIEM Log Stream"
  type   = "http"
  status = "active"

  sink {
    http_endpoint       = var.siem_webhook_url
    http_content_type   = "application/json"
    http_content_format = "JSONOBJECT"
    http_authorization  = "Bearer ${var.siem_token}"
  }
}
# HTH Guide Excerpt: end terraform
