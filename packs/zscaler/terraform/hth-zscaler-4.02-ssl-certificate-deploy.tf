# =============================================================================
# HTH Zscaler Control 4.2: Install SSL Certificate for Inspection
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-8, SI-4 | CIS 3.10
# Source: https://howtoharden.com/guides/zscaler/#42-install-ssl-certificate-for-inspection
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Note: SSL certificate deployment to endpoints is handled through:
#   1. MDM/UEM tools (Intune, JAMF) for managed device deployment
#   2. Client Connector auto-install during enrollment
#   3. GPO distribution for domain-joined Windows devices
#
# The Zscaler root CA certificate must be added to the Trusted Root CA store
# on all endpoints that will be subject to SSL inspection.
#
# Certificate download: ZIA Admin Portal > Administration > SSL Policy
#
# This control is infrastructure/endpoint-managed and not directly
# configurable via the ZIA/ZPA Terraform providers.

# HTH Guide Excerpt: end terraform
