# =============================================================================
# HTH 1Password Control 2.1: Configure Account Password Policy
# Profile Level: L1 (Baseline)
# Source: https://howtoharden.com/guides/1password/#21-configure-account-password-policy
# =============================================================================
#
# Master password policy is an account-level admin setting configured via the
# 1Password Admin Console (Security > Policies > Account Password). The
# Terraform provider manages items/vaults, not admin policies.
#
# This control uses null_resource to document and verify the expected policy
# state, and stores the policy configuration as a secure note for audit.
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Document and verify password policy configuration.
resource "null_resource" "verify_password_policy" {
  triggers = {
    profile_level  = var.profile_level
    min_length     = var.master_password_min_length
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "======================================================="
      echo "HTH 1Password Control 2.1: Account Password Policy"
      echo "======================================================="
      echo ""
      echo "Profile Level: ${var.profile_level}"
      echo ""
      echo "Required password policy settings:"
      echo "  Navigate to: Admin Console > Security > Policies > Account Password"
      echo ""
      if [ "${var.profile_level}" -eq 1 ]; then
        echo "  L1 (Baseline):"
        echo "    Minimum length: 10+ characters"
        echo "    Policy strength: Minimum or higher"
      elif [ "${var.profile_level}" -eq 2 ]; then
        echo "  L2 (Hardened):"
        echo "    Minimum length: 12+ characters"
        echo "    Policy strength: Medium or higher"
      else
        echo "  L3 (Maximum Security):"
        echo "    Minimum length: 14+ characters"
        echo "    Policy strength: Strict"
        echo "    Additional: uppercase, lowercase, numbers, symbols"
      fi
      echo ""
      echo "Configured minimum length variable: ${var.master_password_min_length}"
    EOT
  }
}

# Store password policy audit record as a secure note.
resource "onepassword_item" "password_policy_audit" {
  vault    = data.onepassword_vault.infrastructure.uuid
  title    = "HTH Password Policy Configuration"
  category = "secure_note"

  section {
    label = "Policy Settings"

    field {
      label = "Profile Level"
      value = tostring(var.profile_level)
      type  = "STRING"
    }

    field {
      label = "Minimum Password Length"
      value = tostring(var.master_password_min_length)
      type  = "STRING"
    }

    field {
      label = "Policy Strength"
      value = var.profile_level >= 3 ? "Strict (14+)" : var.profile_level >= 2 ? "Medium (12+)" : "Minimum (10+)"
      type  = "STRING"
    }

    field {
      label = "Last Verified"
      value = timestamp()
      type  = "STRING"
    }
  }

  tags = ["hth-hardening", "password-policy", "audit"]
}

# HTH Guide Excerpt: end terraform
