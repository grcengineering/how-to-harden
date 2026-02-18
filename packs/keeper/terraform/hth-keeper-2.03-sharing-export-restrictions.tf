# =============================================================================
# HTH Keeper Control 2.3: Configure Sharing and Export Restrictions
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.3, NIST AC-3
# Source: https://howtoharden.com/guides/keeper/#23-configure-sharing-and-export-restrictions
# =============================================================================
#
# Control how records can be shared and exported from Keeper. L1 enforces
# basic sharing controls. L2+ restricts sharing to within the organization
# and disables export/printing capabilities.
#
# Implementation: Keeper Commander CLI via local-exec provisioners.
# Sharing and export are role-level enforcement policies.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure sharing restrictions -- L2 tightens to org-only
resource "terraform_data" "sharing_restrictions" {
  input = {
    restrict_to_org = var.profile_level >= 2 ? true : var.restrict_sharing_to_org
    disable_export  = var.profile_level >= 2 ? true : var.disable_export
    profile_level   = var.profile_level
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================================"
      echo "HTH Keeper 2.3: Sharing and Export Restrictions (L1)"
      echo "============================================================"
      echo ""
      echo "ACTION REQUIRED: Configure sharing policy in Keeper Admin Console"
      echo ""
      echo "  1. Navigate to: Role > Enforcement Policies > Sharing"
      echo "  2. Configure:"
      %{if var.profile_level >= 2~}
      echo "     - Allow sharing: Within organization only (L2)"
      echo "     - Allow external sharing: DISABLED"
      %{else~}
      echo "     - Allow sharing: Enabled with controls"
      echo "     - Allow external sharing: Require approval"
      %{endif~}
      echo "     - One-time share: Configure expiration"
      echo ""
      echo "  3. Navigate to: Enforcement Policies > Export"
      echo "  4. Configure:"
      %{if var.profile_level >= 2~}
      echo "     - Allow export: DISABLED (L2)"
      echo "     - Allow printing: DISABLED (L2)"
      %{else~}
      echo "     - Allow export: Enabled (L1 baseline)"
      echo "     - Allow printing: Enabled (L1 baseline)"
      %{endif~}
      echo ""
      echo "Or use Keeper Commander CLI:"
      echo "  keeper-commander enterprise-role --enforcement \\"
      %{if var.profile_level >= 2~}
      echo "    restrict_sharing=org_only \\"
      echo "    restrict_export=true \\"
      echo "    restrict_printing=true"
      %{else~}
      echo "    restrict_sharing=allow_with_controls \\"
      echo "    restrict_export=false"
      %{endif~}
      echo "============================================================"
    EOT
  }
}

# Store sharing policy for audit trail
resource "secretsmanager_login" "sharing_policy_record" {
  folder_uid = var.security_config_folder_uid
  title      = "HTH Sharing and Export Restrictions"

  login = "sharing-policy"
  url   = "https://keepersecurity.com/console"

  notes = <<-EOT
    SHARING AND EXPORT RESTRICTIONS
    =================================
    Profile Level: L1+ (Baseline)
    Current Profile: L${var.profile_level}

    Sharing Policy:
    - Restrict to organization: ${var.profile_level >= 2 ? "YES (L2)" : var.restrict_sharing_to_org}
    - External sharing: ${var.profile_level >= 2 ? "DISABLED" : "Require approval"}
    - One-time share: Configured with expiration

    Export Policy:
    - Allow export: ${var.profile_level >= 2 ? "DISABLED (L2)" : "Enabled"}
    - Allow printing: ${var.profile_level >= 2 ? "DISABLED (L2)" : "Enabled"}

    Last updated: Managed by Terraform
    Control: HTH Keeper 2.3
  EOT
}
# HTH Guide Excerpt: end terraform
