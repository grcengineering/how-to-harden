# =============================================================================
# HTH Cloudflare Control 2.3: Configure Device Posture Checks
# Profile Level: L2 (Hardened)
# Frameworks: NIST AC-2(11) | CIS 4.1
# Source: https://howtoharden.com/guides/cloudflare/#23-configure-device-posture-checks
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "cloudflare_zero_trust_device_posture_rule" "disk_encryption" {
  account_id  = var.cloudflare_account_id
  name        = "Require Disk Encryption"
  type        = "disk_encryption"
  description = "Ensure full-disk encryption is enabled (FileVault/BitLocker)"
  schedule    = "1h"

  input = {
    require_all = true
  }

  match = [{
    platform = "windows"
  }, {
    platform = "mac"
  }]
}

resource "cloudflare_zero_trust_device_posture_rule" "firewall_enabled" {
  account_id  = var.cloudflare_account_id
  name        = "Require Firewall Enabled"
  type        = "firewall"
  description = "Ensure host firewall is enabled"
  schedule    = "1h"

  match = [{
    platform = "windows"
  }, {
    platform = "mac"
  }]
}

resource "cloudflare_zero_trust_device_posture_rule" "os_version" {
  account_id  = var.cloudflare_account_id
  name        = "Minimum OS Version"
  type        = "os_version"
  description = "Require minimum OS version"
  schedule    = "24h"

  input = {
    version  = var.min_os_version
    operator = ">="
  }

  match = [{
    platform = "mac"
  }]
}
# HTH Guide Excerpt: end terraform
