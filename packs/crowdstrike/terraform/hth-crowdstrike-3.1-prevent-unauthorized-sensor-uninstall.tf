# =============================================================================
# HTH CrowdStrike Control 3.1: Prevent Unauthorized Sensor Uninstall
# Profile Level: L1 (Baseline)
# Frameworks: NIST SI-3
# Source: https://howtoharden.com/guides/crowdstrike/#31-prevent-unauthorized-sensor-uninstall
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Sensor update policy with uninstall protection enabled (Windows)
resource "crowdstrike_sensor_update_policy" "anti_tamper_windows" {
  name                 = "HTH Anti-Tamper - Windows"
  description          = "Enables uninstall protection to prevent unauthorized sensor removal on Windows hosts"
  platform_name        = "Windows"
  enabled              = true
  uninstall_protection = var.uninstall_protection_enabled ? "ENABLED" : "DISABLED"

  build = var.sensor_update_canary_build != "" ? var.sensor_update_canary_build : null

  schedule = {
    enabled = false
  }
}

# Sensor update policy with uninstall protection enabled (Linux)
resource "crowdstrike_sensor_update_policy" "anti_tamper_linux" {
  name                 = "HTH Anti-Tamper - Linux"
  description          = "Enables uninstall protection to prevent unauthorized sensor removal on Linux hosts"
  platform_name        = "Linux"
  enabled              = true
  uninstall_protection = var.uninstall_protection_enabled ? "ENABLED" : "DISABLED"

  build = var.sensor_update_canary_build != "" ? var.sensor_update_canary_build : null

  schedule = {
    enabled = false
  }
}

# Sensor update policy with uninstall protection enabled (Mac)
resource "crowdstrike_sensor_update_policy" "anti_tamper_mac" {
  name                 = "HTH Anti-Tamper - Mac"
  description          = "Enables uninstall protection to prevent unauthorized sensor removal on Mac hosts"
  platform_name        = "Mac"
  enabled              = true
  uninstall_protection = var.uninstall_protection_enabled ? "ENABLED" : "DISABLED"

  build = var.sensor_update_canary_build != "" ? var.sensor_update_canary_build : null

  schedule = {
    enabled = false
  }
}
# HTH Guide Excerpt: end terraform
