# =============================================================================
# HTH OneLogin Control 4.3: Configure Device Trust
# Profile Level: L2 (Hardened)
# Frameworks: CIS 13.7, NIST AC-17
# Source: https://howtoharden.com/guides/onelogin/#43-configure-device-trust
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Device trust policy requiring managed device certificates
# Only deployed at L2+ for environments requiring device posture verification
resource "onelogin_user_security_policy" "device_trust" {
  count = var.profile_level >= 2 ? 1 : 0

  name = "HTH Device Trust Policy"

  # Require trusted/managed devices for login
  device_trust_enabled        = true
  require_managed_device      = true
  require_domain_joined       = true
  require_certificate         = true
}

# L3: strictest device trust with no exceptions
resource "onelogin_user_security_policy" "device_trust_max" {
  count = var.profile_level >= 3 ? 1 : 0

  name = "HTH Device Trust Policy - Maximum Security"

  device_trust_enabled        = true
  require_managed_device      = true
  require_domain_joined       = true
  require_certificate         = true
  block_untrusted_devices     = true
}
# HTH Guide Excerpt: end terraform
