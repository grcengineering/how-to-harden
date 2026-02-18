# =============================================================================
# HTH CrowdStrike Control 3.2: Configure Prevention Policy Hardening
# Profile Level: L1 (Baseline), L2/L3 increase aggressiveness
# Frameworks: NIST SI-3, SI-4
# Source: https://howtoharden.com/guides/crowdstrike/#32-configure-prevention-policy-hardening
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Hardened Windows prevention policy
# ML levels scale with profile: L1=MODERATE, L2=AGGRESSIVE, L3=EXTRA_AGGRESSIVE
resource "crowdstrike_prevention_policy_windows" "hardened" {
  name        = var.prevention_policy_windows_name
  description = "HTH hardened prevention policy - Profile Level ${var.profile_level}"
  enabled     = true
  host_groups = []
  ioa_rule_groups = []

  # Cloud-based machine learning
  cloud_anti_malware = {
    detection  = var.profile_level >= 3 ? "EXTRA_AGGRESSIVE" : var.profile_level >= 2 ? "AGGRESSIVE" : "MODERATE"
    prevention = var.profile_level >= 3 ? "EXTRA_AGGRESSIVE" : var.profile_level >= 2 ? "AGGRESSIVE" : "MODERATE"
  }

  # Sensor-based machine learning
  sensor_anti_malware = {
    detection  = var.profile_level >= 3 ? "EXTRA_AGGRESSIVE" : var.profile_level >= 2 ? "AGGRESSIVE" : "MODERATE"
    prevention = var.profile_level >= 3 ? "EXTRA_AGGRESSIVE" : var.profile_level >= 2 ? "AGGRESSIVE" : "MODERATE"
  }

  # Adware and PUP detection
  adware_and_pup = {
    detection  = var.profile_level >= 2 ? "AGGRESSIVE" : "MODERATE"
    prevention = var.profile_level >= 2 ? "AGGRESSIVE" : "MODERATE"
  }

  # Script-based execution monitoring (PowerShell, VBA, etc.)
  script_based_execution_monitoring = true

  # Sensor tamper protection -- always enabled
  sensor_tampering_protection = true

  # Quarantine malicious files on write
  quarantine_on_write = true

  # Notify end users on detection
  notify_end_users = true

  # Volume shadow copy protection (ransomware defense)
  volume_shadow_copy_protect = true

  # Memory scanning for in-memory attacks (L2+)
  memory_scanning = var.profile_level >= 2 ? true : false

  # Driver load prevention (L2+)
  driver_load_prevention = var.profile_level >= 2 ? true : false

  # Vulnerable driver protection requires driver_load_prevention (L2+)
  vulnerable_driver_protection = var.profile_level >= 2 ? true : false

  # Extended user mode data for enhanced detection
  extended_user_mode_data = true
}

# Hardened Linux prevention policy
resource "crowdstrike_prevention_policy_linux" "hardened" {
  name        = var.prevention_policy_linux_name
  description = "HTH hardened prevention policy - Profile Level ${var.profile_level}"
  enabled     = true
  host_groups = []
  ioa_rule_groups = []

  # Cloud-based machine learning
  cloud_anti_malware = {
    detection  = var.profile_level >= 3 ? "EXTRA_AGGRESSIVE" : var.profile_level >= 2 ? "AGGRESSIVE" : "MODERATE"
    prevention = var.profile_level >= 3 ? "EXTRA_AGGRESSIVE" : var.profile_level >= 2 ? "AGGRESSIVE" : "MODERATE"
  }

  # Sensor-based machine learning
  sensor_anti_malware = {
    detection  = var.profile_level >= 3 ? "EXTRA_AGGRESSIVE" : var.profile_level >= 2 ? "AGGRESSIVE" : "MODERATE"
    prevention = var.profile_level >= 3 ? "EXTRA_AGGRESSIVE" : var.profile_level >= 2 ? "AGGRESSIVE" : "MODERATE"
  }

  # Script-based execution monitoring (shell/scripting visibility)
  script_based_execution_monitoring = true

  # Sensor tamper protection
  sensor_tampering_protection = true

  # Block suspicious processes
  prevent_suspicious_processes = true

  # Quarantine malicious files
  quarantine = true

  # Network visibility (L2+)
  network_visibility = var.profile_level >= 2 ? true : false

  # Extended command line visibility (L2+)
  extended_command_line_visibility = var.profile_level >= 2 ? true : false

  # Drift prevention for containers (L3)
  drift_prevention = var.profile_level >= 3 ? true : false
}

# Hardened Mac prevention policy
resource "crowdstrike_prevention_policy_mac" "hardened" {
  name        = var.prevention_policy_mac_name
  description = "HTH hardened prevention policy - Profile Level ${var.profile_level}"
  enabled     = true
  host_groups = []
  ioa_rule_groups = []

  # Cloud-based machine learning
  cloud_anti_malware = {
    detection  = var.profile_level >= 3 ? "EXTRA_AGGRESSIVE" : var.profile_level >= 2 ? "AGGRESSIVE" : "MODERATE"
    prevention = var.profile_level >= 3 ? "EXTRA_AGGRESSIVE" : var.profile_level >= 2 ? "AGGRESSIVE" : "MODERATE"
  }

  # Sensor-based machine learning
  sensor_anti_malware = {
    detection  = var.profile_level >= 3 ? "EXTRA_AGGRESSIVE" : var.profile_level >= 2 ? "AGGRESSIVE" : "MODERATE"
    prevention = var.profile_level >= 3 ? "EXTRA_AGGRESSIVE" : var.profile_level >= 2 ? "AGGRESSIVE" : "MODERATE"
  }

  # Cloud adware and PUP detection
  cloud_adware_and_pup = {
    detection  = var.profile_level >= 2 ? "AGGRESSIVE" : "MODERATE"
    prevention = var.profile_level >= 2 ? "AGGRESSIVE" : "MODERATE"
  }

  # Sensor adware and PUP detection
  sensor_adware_and_pup = {
    detection  = var.profile_level >= 2 ? "AGGRESSIVE" : "MODERATE"
    prevention = var.profile_level >= 2 ? "AGGRESSIVE" : "MODERATE"
  }

  # Script-based execution monitoring
  script_based_execution_monitoring = true

  # Sensor tamper protection
  sensor_tampering_protection = true

  # Block suspicious processes
  prevent_suspicious_processes = true

  # Quarantine malicious files
  quarantine = true

  # Quarantine on write
  quarantine_on_write = true

  # Notify end users
  notify_end_users = true
}
# HTH Guide Excerpt: end terraform
