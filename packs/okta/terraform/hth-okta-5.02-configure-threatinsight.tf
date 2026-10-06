# =============================================================================
# HTH Okta Control 5.2: ThreatInsight
# Profile Level: L1 (Crawl)
# Frameworks: NIST SI-4, IR-4
# Source: https://howtoharden.com/guides/okta/#52-configure-threatinsight
#
# okta_threat_insight_settings.action: "none", "audit" (log only), or "block"
# (log and enforce). network_excludes takes IP network zone IDs to exempt.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Log and enforce ThreatInsight (console: "Log and enforce security based on threat level")
resource "okta_threat_insight_settings" "threatinsight" {
  action           = "block"
  network_excludes = var.threatinsight_exempt_zone_ids
}
# HTH Guide Excerpt: end terraform
