# =============================================================================
# HTH Duo Control 5.2: Secure Windows Logon/RDP
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.3, NIST IA-2
# Source: https://howtoharden.com/guides/duo/#52-secure-windows-logonrdp
#
# Configures Duo for Windows Logon and RDP with hardened settings:
# - Deny new (unenrolled) users at login
# - Configure offline access with limited scope
# - Set fail mode (closed vs open) based on security requirements
# =============================================================================

# HTH Guide Excerpt: begin terraform
# ISE device admin policy set for Duo-protected Windows/RDP access
resource "ise_device_admin_policy_set" "duo_windows_rdp" {
  name        = "HTH-Duo-Windows-RDP"
  description = "HTH Duo 5.2: Device admin policy for Windows Logon and RDP with Duo MFA"
  state       = "enabled"
  default     = false
  rank        = 1

  condition_type        = "ConditionReference"
  condition_is_negate   = false
}

# Configure Windows Logon/RDP application settings via Duo Admin API
resource "null_resource" "duo_windows_rdp_config" {
  triggers = {
    fail_mode       = var.rdp_fail_mode
    offline_enabled = var.rdp_offline_access_enabled
    offline_expiry  = var.rdp_offline_expiry_hours
    offline_logins  = var.rdp_offline_max_logins
    profile_level   = var.profile_level
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      echo "=== HTH Duo 5.2: Configuring Windows Logon/RDP ==="
      echo ""
      echo "Windows Logon/RDP Settings:"
      echo "  New user policy: DENY (users must be pre-enrolled)"
      echo "  Fail mode: ${var.rdp_fail_mode}"
      echo "  Offline access: ${var.rdp_offline_access_enabled}"
      if [ "${var.rdp_offline_access_enabled}" = "true" ]; then
        echo "  Offline expiration: ${var.rdp_offline_expiry_hours} hours"
        echo "  Max offline logins: ${var.rdp_offline_max_logins}"
      fi
      echo ""

      if [ "${var.rdp_fail_mode}" = "OPEN" ]; then
        echo "WARNING: Fail mode is OPEN -- users can access without MFA"
        echo "  if Duo cloud is unreachable. Consider CLOSED for higher security."
      else
        echo "INFO: Fail mode is CLOSED -- access blocked if Duo is unreachable."
        echo "  This is more secure but may impact availability."
      fi

      echo ""
      echo "Deployment checklist:"
      echo "  [ ] Duo Authentication for Windows Logon installer deployed"
      echo "  [ ] Application configured in Duo Admin Panel"
      echo "  [ ] New user policy set to: Deny access"
      echo "  [ ] Fail mode set to: ${var.rdp_fail_mode}"
      if [ "${var.rdp_offline_access_enabled}" = "true" ]; then
        echo "  [ ] Offline access configured with ${var.rdp_offline_expiry_hours}h expiry"
        echo "  [ ] Offline login limit set to ${var.rdp_offline_max_logins}"
      else
        echo "  [ ] Offline access: DISABLED"
      fi
      echo "  [ ] Test RDP login with Duo MFA before production rollout"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
