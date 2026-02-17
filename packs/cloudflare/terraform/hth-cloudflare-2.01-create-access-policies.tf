# =============================================================================
# HTH Cloudflare Control 2.1: Create Secure Application Policies
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-3, AC-6 | CIS 6.4
# Source: https://howtoharden.com/guides/cloudflare/#21-create-secure-application-policies
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "cloudflare_zero_trust_access_group" "employees" {
  account_id = var.cloudflare_account_id
  name       = "All Employees"

  include = [{
    email_domain = {
      domain = var.corporate_domain
    }
  }]
}

resource "cloudflare_zero_trust_access_application" "internal_app" {
  zone_id          = var.cloudflare_zone_id
  name             = "Internal Application"
  domain           = var.app_domain
  type             = "self_hosted"
  session_duration = "8h"

  allowed_idps              = [cloudflare_zero_trust_access_identity_provider.corporate_idp.id]
  auto_redirect_to_identity = true
}

resource "cloudflare_zero_trust_access_policy" "allow_employees" {
  account_id = var.cloudflare_account_id
  name       = "Allow authenticated employees"
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
