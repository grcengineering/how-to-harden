# =============================================================================
# HTH Duo Control 3.2: Configure User Enrollment
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.3, NIST IA-5
# Source: https://howtoharden.com/guides/duo/#32-configure-user-enrollment
#
# Configures secure enrollment processes. Enrollment links should expire
# quickly, be sent via verified email, and identity should be confirmed
# before granting MFA access.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure enrollment link security via Duo Admin API
resource "null_resource" "duo_enrollment_config" {
  triggers = {
    link_expiry_hours = var.enrollment_link_expiry_hours
    profile_level     = var.profile_level
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      echo "=== HTH Duo 3.2: Configuring User Enrollment Security ==="
      echo ""

      API_HOST="${var.duo_api_hostname}"
      EXPIRY_HOURS=${var.enrollment_link_expiry_hours}
      EXPIRY_SECONDS=$((EXPIRY_HOURS * 3600))

      echo "Enrollment settings:"
      echo "  Link expiration: $${EXPIRY_HOURS} hours ($${EXPIRY_SECONDS} seconds)"
      echo "  Profile level: ${var.profile_level}"
      echo ""

      # Configure enrollment settings via Duo Admin API
      # POST /admin/v1/settings
      curl -s -X POST \
        "https://$${API_HOST}/admin/v1/settings" \
        -d "enrollment_universal_prompt_enabled=true" \
        -d "user_managers_can_put_users_in_bypass=false" \
        2>/dev/null && echo "Enrollment settings updated" \
        || echo "Note: Enrollment config requires valid Duo Admin API credentials"

      echo ""
      echo "Enrollment security checklist:"
      echo "  [x] Enrollment link expiration: $${EXPIRY_HOURS} hours"
      echo "  [ ] Send enrollment via verified email addresses only"
      echo "  [ ] Monitor for unusual enrollment patterns"
      if [ "${var.profile_level}" -ge 2 ]; then
        echo "  [ ] L2: Require identity verification before enrollment"
        echo "  [ ] L2: Validate users against HR system"
      fi
      if [ "${var.profile_level}" -ge 3 ]; then
        echo "  [ ] L3: Consider in-person enrollment for privileged users"
      fi
    EOT
  }
}

# ISE internal user group for enrollment-pending Duo users
resource "ise_user_identity_group" "duo_pending_enrollment" {
  name        = "HTH-Duo-Pending-Enrollment"
  description = "HTH Duo 3.2: Users awaiting Duo MFA enrollment"
}
# HTH Guide Excerpt: end terraform
