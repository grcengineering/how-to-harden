# =============================================================================
# HTH Keeper Control 2.4: Restrict Browser Extension Installation
# Profile Level: L2 (Hardened)
# Frameworks: CIS 2.5, NIST CM-7
# Source: https://howtoharden.com/guides/keeper/#24-restrict-browser-extension-installation
# =============================================================================
#
# Browser extensions with elevated permissions can access information in
# websites, including vault data. Malicious extensions could capture
# credentials during autofill. This control limits browser extensions to
# Keeper and an approved whitelist only.
#
# Implementation: This is primarily an MDM/endpoint management control.
# Terraform documents the policy and stores the approved extension list
# as an auditable record in the Keeper vault.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Document approved browser extension policy (L2+)
resource "terraform_data" "browser_extension_policy" {
  count = var.profile_level >= 2 ? 1 : 0

  input = {
    profile_level       = var.profile_level
    approved_extensions = var.approved_browser_extensions
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================================"
      echo "HTH Keeper 2.4: Restrict Browser Extensions (L2)"
      echo "============================================================"
      echo ""
      echo "ACTION REQUIRED: Configure browser extension policy via MDM"
      echo ""
      echo "  1. Use device management (MDM) to:"
      echo "     - Allow only Keeper browser extension"
      echo "     - Block unapproved extensions"
      echo "     - Remove unknown extensions"
      echo ""
      echo "  2. Approved Extension IDs:"
      echo "     - Chrome: bfogiafebfohielmmehodmfbbebbbpei (Keeper)"
      %{for ext in var.approved_browser_extensions~}
      echo "     - ${ext}"
      %{endfor~}
      echo ""
      echo "  3. Communicate policy to users"
      echo "  4. Schedule regular audit of installed extensions"
      echo ""
      echo "MDM Configuration (Google Workspace example):"
      echo "  Admin Console > Devices > Chrome > Apps & extensions"
      echo "  Set 'Allow/block mode' to 'Allow approved apps'"
      echo "============================================================"
    EOT
  }
}

# Store approved extension whitelist for audit trail
resource "secretsmanager_login" "extension_policy_record" {
  count = var.profile_level >= 2 ? 1 : 0

  folder_uid = var.security_config_folder_uid
  title      = "HTH Browser Extension Policy"

  login = "extension-policy"
  url   = "https://keepersecurity.com/console"

  notes = <<-EOT
    BROWSER EXTENSION RESTRICTION POLICY
    =======================================
    Profile Level: L2 (Hardened)

    Approved Extensions:
    - Keeper Password Manager (bfogiafebfohielmmehodmfbbebbbpei)
    ${join("\n    ", var.approved_browser_extensions)}

    Enforcement Method: MDM / Endpoint Management
    Policy: Block all unapproved browser extensions
    Audit Frequency: Monthly

    Last updated: Managed by Terraform
    Control: HTH Keeper 2.4
  EOT
}
# HTH Guide Excerpt: end terraform
