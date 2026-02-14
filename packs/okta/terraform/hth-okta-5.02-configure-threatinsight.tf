# =============================================================================
# HTH Okta Control 5.2: ThreatInsight
# Profile Level: L1 (Baseline)
# Frameworks: NIST SI-4, IR-4, DISA STIG V-273200
# Source: https://howtoharden.com/guides/okta/#52-configure-threatinsight
# =============================================================================

# Enable ThreatInsight in block mode
resource "okta_threat_policy" "threatinsight" {
  action = "block"
}
