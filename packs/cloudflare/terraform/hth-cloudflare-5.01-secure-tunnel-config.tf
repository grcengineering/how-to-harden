# =============================================================================
# HTH Cloudflare Control 5.1: Secure Cloudflare Tunnel Configuration
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-7, SC-8 | CIS 12.1
# Source: https://howtoharden.com/guides/cloudflare/#51-secure-cloudflare-tunnel-configuration
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "random_id" "tunnel_secret" {
  byte_length = 35
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "app_tunnel" {
  account_id    = var.cloudflare_account_id
  name          = "app-tunnel"
  config_src    = "cloudflare"
  tunnel_secret = random_id.tunnel_secret.b64_std
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "app_tunnel_config" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.app_tunnel.id

  config = {
    ingress = [{
      hostname = var.app_domain
      service  = var.app_origin_url

      origin_request = {
        connect_timeout = 10
        no_tls_verify   = false
      }
    }, {
      service = "http_status:404"
    }]
  }
}

resource "cloudflare_dns_record" "tunnel_cname" {
  zone_id = var.cloudflare_zone_id
  name    = var.app_subdomain
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.app_tunnel.id}.cfargotunnel.com"
  proxied = true
}
# HTH Guide Excerpt: end terraform
