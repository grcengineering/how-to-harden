# =============================================================================
# HTH Keeper Control 3.1: Configure Biometric Authentication
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.5, NIST IA-2
# Source: https://howtoharden.com/guides/keeper/#31-configure-biometric-authentication
# =============================================================================
#
# Biometric authentication provides improved security and usability for
# vault access. Keeper supports Windows Hello, Touch ID, Face ID, and
# Android biometrics. A biometric timeout and periodic master password
# re-authentication should be configured.
#
# Implementation: Keeper Commander CLI via local-exec provisioners.
# Biometric settings are role-level enforcement policies.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure biometric authentication enforcement
resource "terraform_data" "biometric_authentication" {
  input = {
    biometrics_enabled     = true
    biometric_timeout_mins = var.biometric_timeout_minutes
    require_periodic_mp    = true
    profile_level          = var.profile_level
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================================"
      echo "HTH Keeper 3.1: Biometric Authentication (L1)"
      echo "============================================================"
      echo ""
      echo "ACTION REQUIRED: Configure biometrics in Keeper Admin Console"
      echo ""
      echo "  1. Navigate to: Role > Enforcement Policies > Biometrics"
      echo "  2. Configure allowed biometric methods:"
      echo "     - Windows Hello"
      echo "     - Touch ID"
      echo "     - Face ID"
      echo "     - Android biometrics"
      echo ""
      echo "  3. Configure biometric policy:"
      echo "     - Biometric timeout: ${var.biometric_timeout_minutes} minutes"
      echo "     - Require master password periodically: YES"
      echo "     - Fallback authentication: Master password"
      echo ""
      echo "Or use Keeper Commander CLI:"
      echo "  keeper-commander enterprise-role --enforcement \\"
      echo "    allow_biometrics=true \\"
      echo "    biometric_timeout=${var.biometric_timeout_minutes}"
      echo "============================================================"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
