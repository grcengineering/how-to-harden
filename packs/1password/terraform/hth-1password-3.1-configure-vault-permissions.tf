# =============================================================================
# HTH 1Password Control 3.1: Configure Vault Permissions
# Profile Level: L1 (Baseline)
# Source: https://howtoharden.com/guides/1password/#31-configure-vault-permissions
# =============================================================================
#
# Vaults are the primary organizational unit in 1Password. The Terraform
# provider supports reading existing vaults via data sources (vaults are
# created via the Admin Console or CLI, not Terraform). This control
# references a least-privilege vault structure for different access tiers.
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Infrastructure vault -- server credentials, API keys, infrastructure secrets.
# Access: IT/DevOps group only.
# NOTE: Vaults must be created in the Admin Console first; Terraform reads them.
data "onepassword_vault" "infrastructure" {
  name = "Infrastructure"
}

# Team Shared vault -- shared team credentials and service accounts.
# Access: Designated team groups.
data "onepassword_vault" "team_shared" {
  name = "Team Shared"
}

# Executive vault -- sensitive business credentials.
# Access: Executives only (L2+ enforced).
data "onepassword_vault" "executive" {
  count = var.profile_level >= 2 ? 1 : 0

  name = "Executive"
}

# Security vault -- security tools, certificates, and compliance credentials.
# Access: Security team only (L2+ enforced).
data "onepassword_vault" "security" {
  count = var.profile_level >= 2 ? 1 : 0

  name = "Security"
}

# Break-glass vault -- emergency access credentials.
# Access: Owners only (L3 enforced).
data "onepassword_vault" "break_glass" {
  count = var.profile_level >= 3 ? 1 : 0

  name = "Break Glass - Emergency Access"
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
      echo "Vault structure referenced:"
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
