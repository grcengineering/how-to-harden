# =============================================================================
# HTH Keeper Control 3.2: Configure Account Recovery
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.2, NIST IA-5
# Source: https://howtoharden.com/guides/keeper/#32-configure-account-recovery
# =============================================================================
#
# Secure account recovery options must be configured to balance usability
# with security. Enterprise environments should prefer admin-assisted
# recovery with verification steps over self-service recovery.
#
# Implementation: Keeper Commander CLI via local-exec provisioners.
# Recovery settings are role-level enforcement policies.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure account recovery enforcement policy
resource "terraform_data" "account_recovery" {
  input = {
    admin_assisted_recovery = true
    self_service_recovery   = var.profile_level <= 1
    profile_level           = var.profile_level
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================================"
      echo "HTH Keeper 3.2: Account Recovery (L1)"
      echo "============================================================"
      echo ""
      echo "ACTION REQUIRED: Configure recovery in Keeper Admin Console"
      echo ""
      echo "  1. Navigate to: Role > Enforcement Policies > Account Recovery"
      echo "  2. Enable appropriate recovery methods:"
      echo ""
      echo "     Admin-assisted recovery: ENABLED (recommended)"
      echo "       - Configure approval workflow"
      echo "       - Require verification steps"
      echo "       - Log all recovery events"
      echo ""
      %{if var.profile_level <= 1~}
      echo "     Self-service recovery: ENABLED (L1)"
      echo "       - With appropriate verification"
      echo "       - Consider disabling at L2+"
      %{else~}
      echo "     Self-service recovery: DISABLED (L2+)"
      echo "       - Admin-assisted only for tighter control"
      %{endif~}
      echo ""
      echo "Or use Keeper Commander CLI:"
      echo "  keeper-commander enterprise-role --enforcement \\"
      echo "    allow_admin_recovery=true \\"
      echo "    allow_self_recovery=${var.profile_level <= 1 ? "true" : "false"}"
      echo "============================================================"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
