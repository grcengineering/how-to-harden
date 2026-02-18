# =============================================================================
# HTH Zscaler Control 4.1: Deploy Client Connector Securely
# Profile Level: L1 (Baseline)
# Frameworks: NIST CM-7, SC-7 | CIS 4.1
# Source: https://howtoharden.com/guides/zscaler/#41-deploy-client-connector-securely
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Note: Zscaler Client Connector deployment and tunnel mode configuration
# (Z-Tunnel 2.0, Always-On, split tunnel) is managed through the ZIA Admin
# Portal (Policy > Client Connector Portal) and MDM/UEM deployment tools
# (Intune, JAMF, SCCM). These settings are not exposed as Terraform resources.
#
# Recommended configuration (apply via ZIA Admin Portal):
#   - Tunnel mode: Z-Tunnel 2.0
#   - Always-On: Enabled
#   - Auto-update: Enabled
#   - Fallback: Configure based on network requirements
#
# Split tunnel exceptions (if required):
#   - Office 365 optimization routes
#   - Video conferencing (Zoom, Teams)
#   - Minimize split tunnel scope

# Retrieve Client Connector forwarding profile for reference
data "zia_location_management" "all_locations" {
  name = "All Other Sub-Locations"
}

# HTH Guide Excerpt: end terraform
