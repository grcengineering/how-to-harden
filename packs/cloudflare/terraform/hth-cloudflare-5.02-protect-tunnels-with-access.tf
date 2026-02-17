# =============================================================================
# HTH Cloudflare Control 5.2: Protect Tunnels with Access Policies
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-3 | CIS 6.4
# Source: https://howtoharden.com/guides/cloudflare/#52-protect-tunnels-with-access-policies
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "cloudflare_zero_trust_access_application" "tunnel_app" {
  zone_id          = var.cloudflare_zone_id
  name             = "Tunnel-Protected Application"
  domain           = var.app_domain
  type             = "self_hosted"
  session_duration = "8h"

  allowed_idps              = [cloudflare_zero_trust_access_identity_provider.corporate_idp.id]
  auto_redirect_to_identity = true
}

resource "cloudflare_zero_trust_access_policy" "tunnel_app_policy" {
  account_id = var.cloudflare_account_id
  name       = "Allow authenticated employees via tunnel"
  decision   = "allow"

  include = [{
    group = {
      id = cloudflare_zero_trust_access_group.employees.id
    }
  }]

  require = [{
    auth_method = {
      auth_method = "mfa"
    }
  }]

  session_duration = "8h"
}
# HTH Guide Excerpt: end terraform
