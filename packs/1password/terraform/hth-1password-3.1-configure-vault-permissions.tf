# =============================================================================
# HTH 1Password Control 3.1: Configure Vault Permissions
# Profile Level: L1 (Baseline)
# Source: https://howtoharden.com/guides/1password/#31-configure-vault-permissions
# =============================================================================
#
# Vaults are the primary organizational unit in 1Password. The Terraform
# provider directly supports creating and managing vaults. This control
# creates a least-privilege vault structure with dedicated vaults for
# different access tiers.
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Infrastructure vault -- server credentials, API keys, infrastructure secrets.
# Access: IT/DevOps group only.
resource "onepassword_vault" "infrastructure" {
  count = 1

  name        = "Infrastructure"
  description = "Server credentials, API keys, and infrastructure secrets -- managed by HTH hardening pack"
}

# Team Shared vault -- shared team credentials and service accounts.
# Access: Designated team groups.
resource "onepassword_vault" "team_shared" {
  count = 1

  name        = "Team Shared"
  description = "Shared team credentials and service accounts -- managed by HTH hardening pack"
}

# Executive vault -- sensitive business credentials.
# Access: Executives only (L2+ enforced).
resource "onepassword_vault" "executive" {
  count = var.profile_level >= 2 ? 1 : 0

  name        = "Executive"
  description = "Sensitive business credentials -- restricted access -- managed by HTH hardening pack"
}

# Security vault -- security tools, certificates, and compliance credentials.
# Access: Security team only (L2+ enforced).
resource "onepassword_vault" "security" {
  count = var.profile_level >= 2 ? 1 : 0

  name        = "Security"
  description = "Security tool credentials, certificates, and compliance items -- managed by HTH hardening pack"
}

# Break-glass vault -- emergency access credentials.
# Access: Owners only (L3 enforced).
resource "onepassword_vault" "break_glass" {
  count = var.profile_level >= 3 ? 1 : 0

  name        = "Break Glass - Emergency Access"
  description = "Emergency access credentials -- Owner access only -- managed by HTH hardening pack"
}

# Document vault permission requirements per profile level.
resource "null_resource" "verify_vault_permissions" {
  triggers = {
    profile_level = var.profile_level
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "======================================================="
      echo "HTH 1Password Control 3.1: Vault Permissions"
      echo "======================================================="
      echo ""
      echo "Profile Level: ${var.profile_level}"
      echo ""
      echo "Vault structure created:"
      echo ""
      echo "  | Vault              | Purpose                      | Access            |"
      echo "  |--------------------|------------------------------|-------------------|"
      echo "  | Employee Private   | Personal items               | Individual only   |"
      echo "  | Infrastructure     | Server/API credentials       | IT/DevOps group   |"
      echo "  | Team Shared        | Team credentials             | Team group        |"
      %{if var.profile_level >= 2~}
      echo "  | Executive          | Sensitive business           | Executives only   |"
      echo "  | Security           | Security tools/certs         | Security team     |"
      %{endif~}
      %{if var.profile_level >= 3~}
      echo "  | Break Glass        | Emergency access             | Owners only       |"
      %{endif~}
      echo ""
      echo "IMPORTANT: Assign vault permissions via Admin Console > Vaults"
      echo "  - Use groups for scalable permission management"
      echo "  - Follow least privilege: View < Edit < Manage"
      echo "  - Review vault access quarterly"
    EOT
  }
}

# HTH Guide Excerpt: end terraform
