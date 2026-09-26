# =============================================================================
# HTH Cloudflare Control 6.1: Configure Logging
# Profile Level: L1 (Crawl)
# Frameworks: NIST AU-2, AU-6 | CIS 8.2
# Source: https://howtoharden.com/guides/cloudflare/#61-configure-logging
#
# Zero Trust Logpush is Enterprise-only
# (developers.cloudflare.com/cloudflare-one/insights/logs/logpush/).
# Destinations such as S3, GCS and Azure require an ownership challenge:
# request one with POST /accounts/{account_id}/logpush/ownership and pass the
# token as var.logpush_ownership_challenge. The deprecated `frequency`
# argument is not used; batching defaults apply (max_upload_* arguments).
# The audit_logs job carries the admin-change events section 6.2 relies on.
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "cloudflare_logpush_job" "access_requests" {
  account_id          = var.cloudflare_account_id
  name                = "hth-access-requests"
  dataset             = "access_requests"
  destination_conf    = var.logpush_destination
  ownership_challenge = var.logpush_ownership_challenge
  enabled             = true
}

resource "cloudflare_logpush_job" "gateway_dns" {
  account_id          = var.cloudflare_account_id
  name                = "hth-gateway-dns"
  dataset             = "gateway_dns"
  destination_conf    = var.logpush_destination
  ownership_challenge = var.logpush_ownership_challenge
  enabled             = true
}

resource "cloudflare_logpush_job" "gateway_http" {
  account_id          = var.cloudflare_account_id
  name                = "hth-gateway-http"
  dataset             = "gateway_http"
  destination_conf    = var.logpush_destination
  ownership_challenge = var.logpush_ownership_challenge
  enabled             = true
}

resource "cloudflare_logpush_job" "gateway_network" {
  account_id          = var.cloudflare_account_id
  name                = "hth-gateway-network"
  dataset             = "gateway_network"
  destination_conf    = var.logpush_destination
  ownership_challenge = var.logpush_ownership_challenge
  enabled             = true
}

resource "cloudflare_logpush_job" "audit_logs" {
  account_id          = var.cloudflare_account_id
  name                = "hth-audit-logs"
  dataset             = "audit_logs"
  destination_conf    = var.logpush_destination
  ownership_challenge = var.logpush_ownership_challenge
  enabled             = true
}
# HTH Guide Excerpt: end terraform
