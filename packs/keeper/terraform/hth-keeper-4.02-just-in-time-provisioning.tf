# =============================================================================
# HTH Keeper Control 4.2: Configure Just-in-Time Provisioning
# Profile Level: L2 (Hardened)
# Frameworks: CIS 5.3, NIST AC-2
# Source: https://howtoharden.com/guides/keeper/#42-configure-just-in-time-provisioning
# =============================================================================
#
# Automatic user provisioning through SSO reduces manual account management
# overhead and ensures timely access. SCIM provisioning provides full
# lifecycle management including automated deprovisioning when users are
# removed from the identity provider.
#
# Implementation: Keeper Commander CLI and Admin Console.
# JIT provisioning is configured through the SSO Configuration panel.
# SCIM endpoints are configured separately for lifecycle management.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure Just-in-Time provisioning (L2+)
resource "terraform_data" "jit_provisioning" {
  count = var.profile_level >= 2 ? 1 : 0

  input = {
    jit_enabled      = true
    scim_enabled     = var.scim_endpoint != ""
    default_role     = var.jit_default_role
    profile_level    = var.profile_level
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================================"
      echo "HTH Keeper 4.2: Just-in-Time Provisioning (L2)"
      echo "============================================================"
      echo ""
      echo "ACTION REQUIRED: Configure provisioning in Keeper Admin Console"
      echo ""
      echo "  Step 1: Enable JIT Provisioning"
      echo "  1. Navigate to: SSO Configuration > Provisioning"
      echo "  2. Enable 'Just-in-Time provisioning'"
      echo "  3. Configure default role: ${var.jit_default_role}"
      echo ""
      %{if var.scim_endpoint != ""~}
      echo "  Step 2: Configure SCIM"
      echo "  1. Enable SCIM provisioning endpoint"
      echo "  2. SCIM endpoint: ${var.scim_endpoint}"
      echo "  3. Integrate with IdP SCIM client"
      echo "  4. Configure user lifecycle management:"
      echo "     - Create on assignment"
      echo "     - Deactivate on removal"
      echo "     - Sync group memberships"
      %{else~}
      echo "  Step 2: SCIM (Optional)"
      echo "  Consider configuring SCIM for automated lifecycle management"
      echo "  including automatic deprovisioning when users leave."
      %{endif~}
      echo ""
      echo "============================================================"
    EOT
  }
}

# Store SCIM configuration for audit trail
resource "secretsmanager_login" "scim_config_record" {
  count = var.profile_level >= 2 && var.scim_endpoint != "" ? 1 : 0

  folder_uid = var.security_config_folder_uid
  title      = "HTH SCIM Provisioning Configuration"

  login = "scim-config"
  url   = var.scim_endpoint

  notes = <<-EOT
    SCIM PROVISIONING CONFIGURATION
    ==================================
    Profile Level: L2 (Hardened)

    JIT Provisioning: Enabled
    SCIM Endpoint: ${var.scim_endpoint}
    Default Role: ${var.jit_default_role}

    Lifecycle Management:
    - Create user on IdP assignment
    - Deactivate user on IdP removal
    - Sync group memberships
    - Map IdP groups to Keeper roles

    Last updated: Managed by Terraform
    Control: HTH Keeper 4.2
  EOT
}
# HTH Guide Excerpt: end terraform
