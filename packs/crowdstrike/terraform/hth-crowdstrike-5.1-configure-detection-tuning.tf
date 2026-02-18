# =============================================================================
# HTH CrowdStrike Control 5.1: Configure Detection Tuning
# Profile Level: L1 (Baseline)
# Frameworks: NIST SI-4
# Source: https://howtoharden.com/guides/crowdstrike/#51-configure-detection-tuning
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Hardened Real Time Response (RTR) policy for Windows
# Controls what remote response actions are available to responders
resource "crowdstrike_response_policy" "hardened_windows" {
  name          = "${var.response_policy_name} - Windows"
  description   = "HTH hardened RTR policy: enables essential response capabilities while restricting dangerous operations. Profile Level ${var.profile_level}."
  platform_name = "Windows"
  enabled       = true

  # Enable remote host connectivity for responders
  real_time_response = true

  # Allow file retrieval from endpoints (forensics)
  get_command = true

  # Allow file upload to endpoints (remediation tools)
  put_command = var.profile_level >= 2 ? true : false

  # Custom script execution -- L2+ only (requires approval workflows)
  custom_scripts = var.profile_level >= 2 ? true : false

  # Executable execution on remote hosts -- L3 only (maximum response capability)
  exec_command = var.profile_level >= 3 ? true : false
}

# Hardened RTR policy for Linux
resource "crowdstrike_response_policy" "hardened_linux" {
  name          = "${var.response_policy_name} - Linux"
  description   = "HTH hardened RTR policy for Linux hosts. Profile Level ${var.profile_level}."
  platform_name = "Linux"
  enabled       = true

  real_time_response = true
  get_command        = true
  put_command        = var.profile_level >= 2 ? true : false
  custom_scripts     = var.profile_level >= 2 ? true : false
  exec_command       = var.profile_level >= 3 ? true : false
}

# Hardened RTR policy for Mac
resource "crowdstrike_response_policy" "hardened_mac" {
  name          = "${var.response_policy_name} - Mac"
  description   = "HTH hardened RTR policy for Mac hosts. Profile Level ${var.profile_level}."
  platform_name = "Mac"
  enabled       = true

  real_time_response = true
  get_command        = true
  put_command        = var.profile_level >= 2 ? true : false
  custom_scripts     = var.profile_level >= 2 ? true : false
  exec_command       = var.profile_level >= 3 ? true : false
}
# HTH Guide Excerpt: end terraform
