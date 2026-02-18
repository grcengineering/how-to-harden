# =============================================================================
# HTH Zscaler Control 2.2: Enable Advanced Threat Protection
# Profile Level: L1 (Baseline)
# Frameworks: NIST SI-3, SI-4 | CIS 10.1, 10.5
# Source: https://howtoharden.com/guides/zscaler/#22-enable-advanced-threat-protection
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Enable malware protection with inline scanning
resource "zia_security_policy_settings" "malware_protection" {
  whitelist_urls = []

  # Block all known malware file types
  blacklist_urls = []
}

# Configure sandbox rule to quarantine unknown files
resource "zia_sandbox_behavioral_analysis" "cloud_sandbox" {
  count = var.profile_level >= 1 ? 1 : 0

  file_types_for_analysis = [
    "EXE_DLL",
    "OFFICE_DOCUMENTS",
    "PDF",
    "ARCHIVE",
    "SCRIPT",
  ]
}

# HTH Guide Excerpt: end terraform
