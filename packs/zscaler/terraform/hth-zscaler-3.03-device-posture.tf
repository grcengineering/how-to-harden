# =============================================================================
# HTH Zscaler Control 3.3: Enable Device Posture Checks
# Profile Level: L2 (Hardened)
# Frameworks: NIST AC-2(11) | CIS 4.1
# Source: https://howtoharden.com/guides/zscaler/#33-enable-device-posture-checks
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Posture profile: require disk encryption (L2+)
resource "zpa_posture_profile" "disk_encryption" {
  count = var.profile_level >= 2 ? 1 : 0

  name           = "HTH-Require-Disk-Encryption"
  posture_udid   = "zscaler-client-posture-disk-encryption"
  domain         = var.zpa_customer_id
  master_customer_id = var.zpa_customer_id
}

# Posture profile: require firewall enabled (L2+)
resource "zpa_posture_profile" "firewall_enabled" {
  count = var.profile_level >= 2 ? 1 : 0

  name           = "HTH-Require-Firewall-Enabled"
  posture_udid   = "zscaler-client-posture-firewall"
  domain         = var.zpa_customer_id
  master_customer_id = var.zpa_customer_id
}

# Posture profile: require minimum OS version (L2+)
resource "zpa_posture_profile" "os_version" {
  count = var.profile_level >= 2 ? 1 : 0

  name           = "HTH-Require-Minimum-OS-Version"
  posture_udid   = "zscaler-client-posture-os-version"
  domain         = var.zpa_customer_id
  master_customer_id = var.zpa_customer_id
}

# Access policy rule requiring device posture (L2+)
resource "zpa_policy_access_rule" "require_posture" {
  count = var.profile_level >= 2 ? 1 : 0

  name        = "HTH-Require-Device-Posture"
  description = "Require device posture compliance for application access"
  action      = "ALLOW"
  policy_type = data.zpa_policy_type.access_policy.id
  operator    = "AND"

  conditions {
    operator = "OR"

    operands {
      object_type = "POSTURE"
      lhs         = zpa_posture_profile.disk_encryption[0].posture_udid
      rhs         = "true"
    }
  }

  conditions {
    operator = "OR"

    operands {
      object_type = "POSTURE"
      lhs         = zpa_posture_profile.firewall_enabled[0].posture_udid
      rhs         = "true"
    }
  }
}

# HTH Guide Excerpt: end terraform
