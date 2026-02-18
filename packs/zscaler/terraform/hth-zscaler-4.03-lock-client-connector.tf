# =============================================================================
# HTH Zscaler Control 4.3: Lock Client Connector Settings
# Profile Level: L2 (Hardened)
# Frameworks: NIST CM-7 | CIS 4.1
# Source: https://howtoharden.com/guides/zscaler/#43-lock-client-connector-settings
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Note: Client Connector App Profile configuration (locking ZIA/ZPA switches,
# password-protected uninstall, disabling admin override) is managed through
# the ZIA Admin Portal (Policy > Client Connector Portal > App Profiles).
# These settings are not currently exposed as Terraform resources.
#
# Recommended configuration for L2+:
#   - Lock ZIA switch: Enabled (prevent user disable)
#   - Lock ZPA switch: Enabled (prevent user disable)
#   - Password-protect uninstall: Enabled
#
# L3 additional restrictions:
#   - Disable admin override codes
#   - Users cannot bypass even temporarily
#   - Implement support process for legitimate issues

# HTH Guide Excerpt: end terraform
