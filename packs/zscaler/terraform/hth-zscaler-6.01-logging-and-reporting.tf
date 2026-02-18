# =============================================================================
# HTH Zscaler Control 6.1: Configure Logging and Reporting
# Profile Level: L1 (Baseline)
# Frameworks: NIST AU-2, AU-6 | CIS 8.2
# Source: https://howtoharden.com/guides/zscaler/#61-configure-logging-and-reporting
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Note: Zscaler logging configuration (enabling web, firewall, DNS, and
# sandbox logs) is managed through the ZIA Admin Portal at:
#   Administration > Log Settings
#
# Nanolog Streaming Service (NSS) for SIEM integration is configured at:
#   Administration > Nanolog Streaming Service
#
# NSS feeds can stream logs to Splunk, Azure Sentinel, QRadar, and
# generic syslog collectors. JSON format is recommended.
#
# The ZIA Terraform provider does not currently expose NSS feed
# configuration as a managed resource. Use the ZIA API directly or
# configure through the Admin Portal.
#
# Critical alert categories to configure:
#   - Malware detection events
#   - Policy violation events
#   - Admin configuration changes
#   - Authentication failures
#   - SSL inspection bypass events

# HTH Guide Excerpt: end terraform
