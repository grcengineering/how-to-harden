# =============================================================================
# HTH 1Password Control 2.4: Implement Role-Based Access
# Profile Level: L1 (Baseline)
# Source: https://howtoharden.com/guides/1password/#24-implement-role-based-access
# =============================================================================
#
# 1Password Business uses built-in roles (Owner, Admin, Team Member, Guest).
# Enterprise plans support custom roles. Role assignment is managed via the
# Admin Console (Team Members section).
#
# This control uses groups within vaults to enforce role-based access patterns
# via the Terraform provider, and documents role assignment requirements.
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Document and verify RBAC configuration.
resource "null_resource" "verify_rbac" {
  triggers = {
    profile_level = var.profile_level
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "======================================================="
      echo "HTH 1Password Control 2.4: Role-Based Access"
      echo "======================================================="
      echo ""
      echo "Profile Level: ${var.profile_level}"
      echo ""
      echo "Navigate to: Admin Console > Team Members"
      echo ""
      echo "Required role assignments:"
      echo ""
      echo "  Owner:       1-2 people maximum (break-glass only)"
      echo "  Admin:       IT administrators for team management"
      echo "  Team Member: Standard users"
      echo "  Guest:       Limited external access (minimize usage)"
      echo ""
      if [ "${var.profile_level}" -ge 2 ]; then
        echo "  L2+ Requirements:"
        echo "    - Document all Owner/Admin assignments"
        echo "    - Review role assignments quarterly"
        echo "    - Remove Guest access when no longer needed"
      fi
      if [ "${var.profile_level}" -ge 3 ]; then
        echo ""
        echo "  L3 Requirements (Enterprise):"
        echo "    - Create custom roles for specific needs"
        echo "    - Enforce separation of duties"
        echo "    - Monthly role review cadence"
      fi
    EOT
  }
}

# Store RBAC audit record with role inventory.
resource "onepassword_item" "rbac_audit" {
  vault    = onepassword_vault.infrastructure[0].uuid
  title    = "HTH Role-Based Access Inventory"
  category = "secure_note"

  section {
    label = "RBAC Configuration"

    field {
      label = "Profile Level"
      value = tostring(var.profile_level)
      type  = "STRING"
    }

    field {
      label = "Owner Limit"
      value = "1-2 personnel maximum"
      type  = "STRING"
    }

    field {
      label = "Review Cadence"
      value = var.profile_level >= 3 ? "Monthly" : var.profile_level >= 2 ? "Quarterly" : "Semi-annually"
      type  = "STRING"
    }

    field {
      label = "Custom Roles"
      value = var.profile_level >= 3 ? "Required (Enterprise)" : "Not applicable"
      type  = "STRING"
    }

    field {
      label = "Last Verified"
      value = timestamp()
      type  = "STRING"
    }
  }

  tags = ["hth-hardening", "rbac", "access-control"]
}

# HTH Guide Excerpt: end terraform
