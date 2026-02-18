# =============================================================================
# HTH Ping Identity Control 1.3: IP-Based Access Restrictions
# Profile Level: L2 (Hardened)
# Frameworks: NIST AC-3(7), SC-7
# Source: https://howtoharden.com/guides/ping-identity/#13-configure-ip-based-access-restrictions
# =============================================================================

# HTH Guide Excerpt: begin terraform
# IP-based access restriction for admin console and API access (L2+)
resource "pingone_sign_on_policy" "ip_restricted" {
  count = var.profile_level >= 2 ? 1 : 0

  environment_id = var.pingone_environment_id
  name           = "HTH IP-Restricted Access"
  description    = "Restricts admin and API access to known corporate IP ranges"
}

# Allow access from corporate network CIDRs
resource "pingone_sign_on_policy_action" "allow_corporate_ips" {
  count = var.profile_level >= 2 && length(var.corporate_gateway_cidrs) > 0 ? 1 : 0

  environment_id    = var.pingone_environment_id
  sign_on_policy_id = pingone_sign_on_policy.ip_restricted[0].id
  priority          = 1

  login {
    recovery_enabled = true
  }

  conditions {
    ip_out_of_range_cidr = var.corporate_gateway_cidrs
  }
}

# Allow access from VPN egress IPs
resource "pingone_sign_on_policy_action" "allow_vpn_ips" {
  count = var.profile_level >= 2 && length(var.vpn_egress_cidrs) > 0 ? 1 : 0

  environment_id    = var.pingone_environment_id
  sign_on_policy_id = pingone_sign_on_policy.ip_restricted[0].id
  priority          = 2

  login {
    recovery_enabled = true
  }

  conditions {
    ip_out_of_range_cidr = var.vpn_egress_cidrs
  }
}

# L3: Deny all traffic outside corporate and VPN ranges
resource "pingone_sign_on_policy_action" "deny_unknown_ips" {
  count = var.profile_level >= 3 ? 1 : 0

  environment_id    = var.pingone_environment_id
  sign_on_policy_id = pingone_sign_on_policy.ip_restricted[0].id
  priority          = 99

  login {
    recovery_enabled = false
  }
}
# HTH Guide Excerpt: end terraform
