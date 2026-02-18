# =============================================================================
# HTH CrowdStrike Control 3.3: Implement Sensor Grouping Strategy
# Profile Level: L1 (Baseline)
# Frameworks: NIST CM-2
# Source: https://howtoharden.com/guides/crowdstrike/#33-implement-sensor-grouping-strategy
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Canary group -- receives updates first for early issue detection (1-5% of fleet)
resource "crowdstrike_host_group" "canary" {
  name            = "HTH Content-Update-Canary"
  description     = "Canary ring for staged content and sensor updates. Non-production and IT systems for early issue detection."
  type            = "dynamic"
  assignment_rule = var.canary_group_assignment_rule
}

# Production-Critical group -- domain controllers, databases, payment systems
resource "crowdstrike_host_group" "production_critical" {
  name            = "HTH Production-Critical"
  description     = "Critical infrastructure: domain controllers, database servers, payment systems. Receives N-1 sensor version and delayed content updates."
  type            = "dynamic"
  assignment_rule = var.production_critical_assignment_rule
}

# Production-Standard group -- application and web servers
resource "crowdstrike_host_group" "production_standard" {
  name            = "HTH Production-Standard"
  description     = "Standard production hosts: application servers, web servers. Receives updates after canary validation."
  type            = "dynamic"
  assignment_rule = var.production_standard_assignment_rule
}

# Workstation group -- end-user devices
resource "crowdstrike_host_group" "workstation" {
  name            = "HTH Workstations"
  description     = "End-user workstations: executive, engineering, and general user devices."
  type            = "dynamic"
  assignment_rule = var.workstation_assignment_rule
}

# Early Adopter group (L2+) -- 10% of fleet validates after canary
resource "crowdstrike_host_group" "early_adopter" {
  count = var.profile_level >= 2 ? 1 : 0

  name            = "HTH Early-Adopter"
  description     = "Early adopter ring: ~10% of fleet. Validates updates after canary before broad production rollout."
  type            = "dynamic"
  assignment_rule = "tags:'SensorGroupingTags/early-adopter'"
}
# HTH Guide Excerpt: end terraform
