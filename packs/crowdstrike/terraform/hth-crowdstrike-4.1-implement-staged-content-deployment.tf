# =============================================================================
# HTH CrowdStrike Control 4.1: Implement Staged Content Deployment
# Profile Level: L1 (Baseline) - CRITICAL (Post-July 2024 Lesson)
# Frameworks: NIST CM-3
# Source: https://howtoharden.com/guides/crowdstrike/#41-implement-staged-content-deployment
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Canary ring -- immediate content updates for early issue detection
resource "crowdstrike_content_update_policy" "canary" {
  name        = "HTH Content Update - Canary Ring"
  description = "Canary ring (1-5%% of fleet): receives content updates immediately for early issue detection. Post-July 2024 lesson: never deploy content to entire fleet simultaneously."
  enabled     = true
  host_groups = [crowdstrike_host_group.canary.id]

  # Rapid response content -- immediate for canary
  rapid_response = {
    ring_assignment = "ea"
    delay_hours     = var.canary_content_delay_hours
  }

  # Sensor operations -- early access for canary
  sensor_operations = {
    ring_assignment = "ea"
    delay_hours     = var.canary_content_delay_hours
  }

  # System critical -- GA with minimal delay
  system_critical = {
    ring_assignment = "ga"
    delay_hours     = var.canary_content_delay_hours
  }

  # Vulnerability management -- early access
  vulnerability_management = {
    ring_assignment = "ea"
    delay_hours     = var.canary_content_delay_hours
  }
}

# Early Adopter ring (L2+) -- 4-hour delay after canary validation
resource "crowdstrike_content_update_policy" "early_adopter" {
  count = var.profile_level >= 2 ? 1 : 0

  name        = "HTH Content Update - Early Adopter Ring"
  description = "Early adopter ring (~10%% of fleet): receives content updates after ${var.early_adopter_content_delay_hours}-hour delay for canary validation."
  enabled     = true
  host_groups = var.profile_level >= 2 ? [crowdstrike_host_group.early_adopter[0].id] : []

  rapid_response = {
    ring_assignment = "ga"
    delay_hours     = var.early_adopter_content_delay_hours
  }

  sensor_operations = {
    ring_assignment = "ga"
    delay_hours     = var.early_adopter_content_delay_hours
  }

  system_critical = {
    ring_assignment = "ga"
    delay_hours     = var.early_adopter_content_delay_hours
  }

  vulnerability_management = {
    ring_assignment = "ga"
    delay_hours     = var.early_adopter_content_delay_hours
  }
}

# Production ring -- 24-48 hour delay for stable deployment
resource "crowdstrike_content_update_policy" "production" {
  name        = "HTH Content Update - Production Ring"
  description = "Production ring (~85%% of fleet): receives content updates after ${var.production_content_delay_hours}-hour delay. Updates only deploy after canary and early-adopter validation."
  enabled     = true
  host_groups = [
    crowdstrike_host_group.production_standard.id,
    crowdstrike_host_group.workstation.id,
  ]

  rapid_response = {
    ring_assignment = "ga"
    delay_hours     = var.production_content_delay_hours
  }

  sensor_operations = {
    ring_assignment = "ga"
    delay_hours     = var.production_content_delay_hours
  }

  system_critical = {
    ring_assignment = "ga"
    delay_hours     = var.production_content_delay_hours
  }

  vulnerability_management = {
    ring_assignment = "ga"
    delay_hours     = var.production_content_delay_hours
  }
}

# Production-Critical ring -- maximum delay for critical infrastructure
resource "crowdstrike_content_update_policy" "production_critical" {
  name        = "HTH Content Update - Production Critical Ring"
  description = "Production-critical ring (domain controllers, databases, payment systems): ${var.critical_content_delay_hours}-hour delay. Maximum caution for critical infrastructure."
  enabled     = true
  host_groups = [crowdstrike_host_group.production_critical.id]

  rapid_response = {
    ring_assignment = "ga"
    delay_hours     = var.critical_content_delay_hours
  }

  sensor_operations = {
    ring_assignment = "ga"
    delay_hours     = var.critical_content_delay_hours
  }

  system_critical = {
    ring_assignment = "ga"
    delay_hours     = var.critical_content_delay_hours
  }

  vulnerability_management = {
    ring_assignment = "ga"
    delay_hours     = var.critical_content_delay_hours
  }
}
# HTH Guide Excerpt: end terraform
