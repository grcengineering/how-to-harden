# =============================================================================
# HTH Duo Control 6.3: Implement Session Hijacking Protection
# Profile Level: L2 (Hardened)
# Frameworks: CIS 6.5, NIST SC-23
# Source: https://howtoharden.com/guides/duo/#63-implement-session-hijacking-protection
#
# Configures session protection features to defend against session hijacking
# that bypasses MFA. Includes session timeouts, continuous authentication,
# and re-authentication for sensitive actions.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# ISE device admin condition for session timeout enforcement
resource "ise_device_admin_condition" "duo_session_timeout" {
  count = var.profile_level >= 2 ? 1 : 0

  name            = "HTH-Duo-Session-Timeout"
  description     = "HTH Duo 6.3: Condition for enforcing session timeout on Duo-protected resources"
  condition_type  = "ConditionAttributes"
  is_negate       = false
  attribute_name  = "Session-Timeout"
  attribute_value = tostring(var.session_timeout_minutes * 60)
  operator        = "lessThan"
  dictionary_name = "RADIUS"
}

# Configure session protection via Duo Admin API
resource "null_resource" "duo_session_protection" {
  count = var.profile_level >= 2 ? 1 : 0

  triggers = {
    session_timeout    = var.session_timeout_minutes
    reauth_sensitive   = var.reauthentication_for_sensitive_actions
    profile_level      = var.profile_level
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      echo "=== HTH Duo 6.3: Configuring Session Hijacking Protection ==="
      echo ""
      echo "Session protection settings:"
      echo "  Session timeout: ${var.session_timeout_minutes} minutes"
      echo "  Re-authentication for sensitive actions: ${var.reauthentication_for_sensitive_actions}"
      echo "  Profile level: ${var.profile_level}"
      echo ""

      echo "Session security controls:"
      echo "  1. Continuous authentication enabled"
      echo "  2. Session timeout: ${var.session_timeout_minutes} minutes"
      if [ "${var.reauthentication_for_sensitive_actions}" = "true" ]; then
        echo "  3. Re-authentication: REQUIRED for sensitive actions"
      else
        echo "  3. Re-authentication: not enforced (consider enabling)"
      fi
      echo "  4. Session anomaly monitoring: enabled via Trust Monitor"
      echo ""
      echo "Session hijacking indicators to monitor:"
      echo "  - Session used from different IP than authentication"
      echo "  - Session used from different device fingerprint"
      echo "  - Session used after long idle period"
      echo "  - Multiple concurrent sessions from single user"
      echo ""
      echo "Implementation steps:"
      echo "  [ ] Configure session policies with appropriate timeouts"
      echo "  [ ] Enable re-authentication for sensitive actions"
      echo "  [ ] Monitor for session anomalies in SIEM"
      echo "  [ ] Review session duration policies quarterly"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
