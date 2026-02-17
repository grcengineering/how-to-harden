# =============================================================================
# HTH Cloudflare Control 6.1: Configure Logging
# Profile Level: L1 (Baseline)
# Frameworks: NIST AU-2, AU-6 | CIS 8.2
# Source: https://howtoharden.com/guides/cloudflare/#61-configure-logging
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "cloudflare_logpush_job" "access_requests" {
  account_id       = var.cloudflare_account_id
  name             = "hth-access-requests"
  dataset          = "access_requests"
  destination_conf = var.logpush_destination
  enabled          = true
  frequency        = "high"
}

resource "cloudflare_logpush_job" "gateway_dns" {
  account_id       = var.cloudflare_account_id
  name             = "hth-gateway-dns"
  dataset          = "gateway_dns"
  destination_conf = var.logpush_destination
  enabled          = true
  frequency        = "high"
}

resource "cloudflare_logpush_job" "gateway_http" {
  account_id       = var.cloudflare_account_id
  name             = "hth-gateway-http"
  dataset          = "gateway_http"
  destination_conf = var.logpush_destination
  enabled          = true
  frequency        = "high"
}

resource "cloudflare_logpush_job" "gateway_network" {
  account_id       = var.cloudflare_account_id
  name             = "hth-gateway-network"
  dataset          = "gateway_network"
  destination_conf = var.logpush_destination
  enabled          = true
  frequency        = "high"
}
# HTH Guide Excerpt: end terraform
