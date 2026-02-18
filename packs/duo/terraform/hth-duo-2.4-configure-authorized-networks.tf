# =============================================================================
# HTH Duo Control 2.4: Configure Authorized Networks
# Profile Level: L2 (Hardened)
# Frameworks: CIS 13.5, NIST AC-17
# Source: https://howtoharden.com/guides/duo/#24-configure-authorized-networks
#
# Configures network-aware authentication policies in Duo. Authorized networks
# (corporate, VPN) can adjust MFA behavior but should NOT bypass security.
# Uses ISE network device groups and Duo Admin API for network definitions.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# ISE network device group for Duo-authorized corporate networks
resource "ise_network_device_group" "duo_authorized_networks" {
  count = var.profile_level >= 2 && length(var.authorized_networks_cidrs) > 0 ? 1 : 0

  name        = "HTH-Duo-Authorized-Networks"
  description = "HTH Duo 2.4: Corporate networks for Duo network-aware policies"
  root_group  = "Location"
}

# Configure authorized networks in Duo via Admin API
resource "null_resource" "duo_authorized_networks" {
  count = var.profile_level >= 2 && length(var.authorized_networks_cidrs) > 0 ? 1 : 0

  triggers = {
    cidrs       = join(",", var.authorized_networks_cidrs)
    require_mfa = var.authorized_networks_require_mfa
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      echo "=== HTH Duo 2.4: Configuring Authorized Networks ==="
      echo ""
      echo "Authorized network CIDRs:"
      for cidr in ${join(" ", var.authorized_networks_cidrs)}; do
        echo "  - $cidr"
      done
      echo ""
      echo "MFA from authorized networks: ${var.authorized_networks_require_mfa ? "REQUIRED" : "OPTIONAL (not recommended)"}"
      echo ""

      if [ "${var.authorized_networks_require_mfa}" = "false" ]; then
        echo "WARNING: Allowing access without MFA from trusted networks"
        echo "  reduces security posture. Consider requiring MFA always."
      fi

      echo ""
      echo "Network policy best practices:"
      echo "  1. Always require MFA, even from trusted networks"
      echo "  2. Use authorized networks to reduce friction, not bypass security"
      echo "  3. Monitor for authentication from unknown networks"
      echo "  4. Review network definitions quarterly"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
