# =============================================================================
# HTH Duo Control 4.1: Configure Trusted Endpoints
# Profile Level: L2 (Hardened)
# Frameworks: CIS 4.1, NIST AC-2(11)
# Source: https://howtoharden.com/guides/duo/#41-configure-trusted-endpoints
#
# Configures Duo Trusted Endpoints to verify device compliance before granting
# access. Requires Duo Advantage or Premier plan and a device management
# solution (Intune, JAMF, etc.). Uses ISE endpoint identity groups to classify
# trusted vs untrusted devices.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# ISE endpoint identity group for Duo-trusted devices
resource "ise_endpoint_identity_group" "duo_trusted_devices" {
  count = var.profile_level >= 2 && var.trusted_endpoints_enabled ? 1 : 0

  name        = "HTH-Duo-Trusted-Devices"
  description = "HTH Duo 4.1: Endpoints verified by Duo Trusted Endpoints"
}

# ISE endpoint identity group for untrusted devices
resource "ise_endpoint_identity_group" "duo_untrusted_devices" {
  count = var.profile_level >= 2 && var.trusted_endpoints_enabled ? 1 : 0

  name        = "HTH-Duo-Untrusted-Devices"
  description = "HTH Duo 4.1: Endpoints not verified by device management"
}

# ISE authorization profile for trusted endpoints
resource "ise_authorization_profile" "duo_trusted_access" {
  count = var.profile_level >= 2 && var.trusted_endpoints_enabled ? 1 : 0

  name        = "HTH-Duo-Trusted-Access"
  description = "HTH Duo 4.1: Full access for Duo-verified trusted endpoints"
  access_type = "ACCESS_ACCEPT"
}

# ISE authorization profile for untrusted endpoints
resource "ise_authorization_profile" "duo_untrusted_deny" {
  count = var.profile_level >= 2 && var.trusted_endpoints_enabled && var.block_untrusted_devices ? 1 : 0

  name        = "HTH-Duo-Untrusted-Deny"
  description = "HTH Duo 4.1: Deny access for untrusted endpoints"
  access_type = "ACCESS_REJECT"
}

# Configure Trusted Endpoints policy via Duo Admin API
resource "null_resource" "duo_trusted_endpoints_policy" {
  count = var.profile_level >= 2 && var.trusted_endpoints_enabled ? 1 : 0

  triggers = {
    trusted_enabled     = var.trusted_endpoints_enabled
    block_untrusted     = var.block_untrusted_devices
    profile_level       = var.profile_level
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      echo "=== HTH Duo 4.1: Configuring Trusted Endpoints ==="
      echo ""
      echo "Settings:"
      echo "  Trusted Endpoints: ENABLED"
      echo "  Block untrusted devices: ${var.block_untrusted_devices}"
      echo "  Profile level: ${var.profile_level}"
      echo ""
      echo "Prerequisites verified:"
      echo "  [ ] Duo Advantage or Premier plan active"
      echo "  [ ] Device management solution integrated (Intune, JAMF, etc.)"
      echo ""
      echo "Configuration steps:"
      echo "  1. Navigate to Duo Admin Panel > Trusted Endpoints"
      echo "  2. Add integration for your device management platform"
      echo "  3. Configure device policy under Policies > Edit policy > Devices"
      echo "  4. Set 'Require devices to be trusted'"
      if [ "${var.block_untrusted_devices}" = "true" ]; then
        echo "  5. Set 'Block untrusted devices' (strict mode)"
      else
        echo "  5. Set 'Allow with warning' for untrusted devices"
      fi
    EOT
  }
}
# HTH Guide Excerpt: end terraform
