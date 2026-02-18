# =============================================================================
# HTH CrowdStrike Control 4.2: Configure Rollback Procedures
# Profile Level: L2 (Hardened)
# Frameworks: NIST CM-3
# Source: https://howtoharden.com/guides/crowdstrike/#42-configure-rollback-procedures
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Sensor update policy for canary ring -- receives latest sensor version first
resource "crowdstrike_sensor_update_policy" "canary_ring" {
  count = var.profile_level >= 2 ? 1 : 0

  name                 = "HTH Sensor Update - Canary Ring"
  description          = "Canary ring: receives latest (N) sensor version immediately. Used for early detection of sensor update issues."
  platform_name        = "Windows"
  enabled              = true
  uninstall_protection = "ENABLED"

  build = var.sensor_update_canary_build != "" ? var.sensor_update_canary_build : null

  schedule = {
    enabled  = true
    timezone = var.sensor_update_schedule_timezone
    time_blocks = [{
      days       = ["sunday"]
      start_time = "02:00"
      end_time   = "06:00"
    }]
  }
}

# Sensor update policy for production ring -- N-1 version for stability
resource "crowdstrike_sensor_update_policy" "production_ring" {
  count = var.profile_level >= 2 ? 1 : 0

  name                 = "HTH Sensor Update - Production Ring"
  description          = "Production ring: runs N-1 sensor version for proven stability. Only updates after canary ring validates the newer version."
  platform_name        = "Windows"
  enabled              = true
  uninstall_protection = "ENABLED"

  build = var.sensor_update_production_build != "" ? var.sensor_update_production_build : null

  schedule = {
    enabled  = true
    timezone = var.sensor_update_schedule_timezone
    time_blocks = [{
      days       = ["saturday"]
      start_time = "02:00"
      end_time   = "06:00"
    }]
  }
}

# Critical infrastructure sensor update policy -- most conservative (L3)
resource "crowdstrike_sensor_update_policy" "critical_ring" {
  count = var.profile_level >= 3 ? 1 : 0

  name                 = "HTH Sensor Update - Critical Infrastructure"
  description          = "Critical infrastructure ring: runs N-1 sensor version with restricted update windows. Requires manual approval for version changes."
  platform_name        = "Windows"
  enabled              = true
  uninstall_protection = "ENABLED"

  build = var.sensor_update_production_build != "" ? var.sensor_update_production_build : null

  schedule = {
    enabled  = true
    timezone = var.sensor_update_schedule_timezone
    time_blocks = [{
      days       = ["sunday"]
      start_time = "03:00"
      end_time   = "05:00"
    }]
  }
}
# HTH Guide Excerpt: end terraform
