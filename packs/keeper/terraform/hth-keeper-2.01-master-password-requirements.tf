# =============================================================================
# HTH Keeper Control 2.1: Configure Master Password Requirements
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.2, NIST IA-5
# Source: https://howtoharden.com/guides/keeper/#21-configure-master-password-requirements
# =============================================================================
#
# Master password requirements are enforced through role enforcement policies.
# The master password is the user's primary secret in Keeper's zero-knowledge
# architecture -- it never leaves the client device and cannot be recovered
# by Keeper Support.
#
# Implementation: Keeper Commander CLI via local-exec provisioners.
# Enforcement policies are role-level configurations managed through
# the Admin Console or Commander CLI.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure master password enforcement policy
resource "terraform_data" "master_password_policy" {
  input = {
    min_length      = var.master_password_min_length
    require_upper   = var.master_password_require_upper
    require_lower   = var.master_password_require_lower
    require_digits  = var.master_password_require_digits
    require_special = var.master_password_require_special
    profile_level   = var.profile_level
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================================"
      echo "HTH Keeper 2.1: Master Password Requirements (L1)"
      echo "============================================================"
      echo ""
      echo "ACTION REQUIRED: Configure password policy in Keeper Admin Console"
      echo ""
      echo "  1. Navigate to: Admin Console > Admin > Roles"
      echo "  2. Select role to configure"
      echo "  3. Click Enforcement Policies"
      echo "  4. Navigate to Master Password section"
      echo "  5. Configure:"
      echo "     - Minimum length: ${var.master_password_min_length} characters"
      echo "     - Require uppercase: ${var.master_password_require_upper}"
      echo "     - Require lowercase: ${var.master_password_require_lower}"
      echo "     - Require digits: ${var.master_password_require_digits}"
      echo "     - Require special characters: ${var.master_password_require_special}"
      echo "     - Password history: Enable (prevent reuse)"
      echo ""
      echo "  6. Apply to all user roles"
      echo "  7. Allow grace period for compliance"
      echo "  8. Monitor compliance dashboard"
      echo ""
      echo "Or use Keeper Commander CLI:"
      echo "  keeper-commander enterprise-role --enforcement \\"
      echo "    master_password_minimum_length=${var.master_password_min_length} \\"
      echo "    master_password_restrict_days_before_reuse=365"
      echo "============================================================"
    EOT
  }
}

# Store password policy configuration for audit trail
resource "secretsmanager_login" "password_policy_record" {
  folder_uid = var.security_config_folder_uid
  title      = "HTH Master Password Policy Configuration"

  login = "password-policy"
  url   = "https://keepersecurity.com/console"

  notes = <<-EOT
    MASTER PASSWORD ENFORCEMENT POLICY
    ====================================
    Profile Level: L1 (Baseline)

    Minimum Length: ${var.master_password_min_length} characters
    Require Uppercase: ${var.master_password_require_upper}
    Require Lowercase: ${var.master_password_require_lower}
    Require Digits: ${var.master_password_require_digits}
    Require Special Characters: ${var.master_password_require_special}
    Password History: Enabled (prevent reuse)

    Recommended Settings by Profile:
    - L1 (Baseline): 16+ characters, mixed case + numbers + symbols
    - L2 (Hardened): 20+ characters, all complexity requirements
    - L3 (Maximum):  24+ characters, all complexity, 90-day review

    Last updated: Managed by Terraform
    Control: HTH Keeper 2.1
  EOT
}
# HTH Guide Excerpt: end terraform
