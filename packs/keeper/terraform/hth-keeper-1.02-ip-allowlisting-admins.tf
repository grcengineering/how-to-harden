# =============================================================================
# HTH Keeper Control 1.2: Configure IP Address Allowlisting for Admins
# Profile Level: L2 (Hardened)
# Frameworks: CIS 13.5, NIST AC-17/SC-7
# Source: https://howtoharden.com/guides/keeper/#12-configure-ip-address-allowlisting-for-admins
# =============================================================================
#
# At minimum, users with admin privileges should be IP-restricted to prevent
# unauthorized administrative actions from unapproved networks. This control
# prevents malicious insider attacks and protects against identity provider
# takeover vectors.
#
# Implementation: Keeper Commander CLI via local-exec provisioners.
# IP allowlisting is an enforcement policy configured per-role.
# Install: pip3 install keepercommander
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Apply IP allowlist enforcement policy to admin roles
# Requires Keeper Commander CLI: pip3 install keepercommander
resource "terraform_data" "admin_ip_allowlist" {
  count = var.profile_level >= 2 && length(var.admin_allowed_ips) > 0 ? 1 : 0

  input = {
    allowed_ips   = var.admin_allowed_ips
    profile_level = var.profile_level
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================================"
      echo "HTH Keeper 1.2: IP Allowlisting for Admins (L2)"
      echo "============================================================"
      echo ""
      echo "ACTION REQUIRED: Configure IP allowlist in Keeper Admin Console"
      echo ""
      echo "  1. Navigate to: Admin Console > Admin > Roles"
      echo "  2. Select the Keeper Administrator role"
      echo "  3. Go to: Enforcement Policies > IP Allowlist"
      echo "  4. Add the following IPs:"
      %{for ip in var.admin_allowed_ips~}
      echo "     - ${ip}"
      %{endfor~}
      echo ""
      echo "  5. Repeat for all custom admin roles"
      echo "  6. Test access from allowed IPs"
      echo "  7. Verify blocked from other IPs"
      echo ""
      echo "Or use Keeper Commander CLI:"
      echo "  keeper-commander enterprise-role --ip-allowlist '${join(",", var.admin_allowed_ips)}'"
      echo "============================================================"
    EOT
  }
}

# Store IP allowlist configuration as a record for audit trail
resource "secretsmanager_login" "ip_allowlist_record" {
  count = var.profile_level >= 2 && length(var.admin_allowed_ips) > 0 ? 1 : 0

  folder_uid = var.security_config_folder_uid
  title      = "HTH Admin IP Allowlist Configuration"

  login = "admin-ip-policy"
  url   = "https://keepersecurity.com/console"

  notes = <<-EOT
    ADMIN IP ALLOWLIST CONFIGURATION
    =================================
    Profile Level: L2 (Hardened)
    Applied to: All administrative roles

    Allowed IP Addresses/CIDRs:
    ${join("\n    ", var.admin_allowed_ips)}

    Last updated: Managed by Terraform
    Control: HTH Keeper 1.2
  EOT
}
# HTH Guide Excerpt: end terraform
