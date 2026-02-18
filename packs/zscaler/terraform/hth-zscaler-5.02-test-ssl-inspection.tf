# =============================================================================
# HTH Zscaler Control 5.2: Test SSL Inspection Thoroughly
# Profile Level: L1 (Baseline)
# Frameworks: NIST CA-2 | CIS 3.10
# Source: https://howtoharden.com/guides/zscaler/#52-test-ssl-inspection-thoroughly
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Note: SSL inspection testing is an operational procedure, not a
# Terraform-managed resource. This control requires manual validation.
#
# Pre-deployment testing checklist:
#   1. Test major business applications through Zscaler proxy
#   2. Verify certificate chain validity on all endpoint types
#   3. Test certificate-pinned applications (banking, healthcare)
#   4. Validate mobile app functionality
#   5. Confirm the "Do Not Inspect" list covers required exceptions
#
# Post-deployment validation:
#   1. Monitor for user-reported certificate errors
#   2. Check ZIA logs for SSL handshake failures
#   3. Verify malware detection is functional with SSL inspection
#   4. Confirm DLP policies apply to inspected HTTPS traffic
#
# Use ZIA Admin Portal > Logs > SSL Logs to identify inspection gaps.

# HTH Guide Excerpt: end terraform
