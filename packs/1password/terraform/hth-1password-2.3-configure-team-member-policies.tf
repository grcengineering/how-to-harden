# =============================================================================
# HTH 1Password Control 2.3: Configure Team Member Policies
# Profile Level: L1 (Baseline)
# Source: https://howtoharden.com/guides/1password/#23-configure-team-member-policies
# =============================================================================
#
# Team member policies govern vault creation, external sharing, Travel Mode,
# and account recovery. These are admin-level settings configured via the
# 1Password Admin Console (Policies section).
#
# This control documents the expected policy state per profile level and
# stores the configuration for audit purposes.
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Document and verify team member policy configuration.
resource "null_resource" "verify_team_policies" {
  triggers = {
    profile_level = var.profile_level
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "======================================================="
      echo "HTH 1Password Control 2.3: Team Member Policies"
      echo "======================================================="
      echo ""
      echo "Profile Level: ${var.profile_level}"
      echo ""
      echo "Navigate to: Admin Console > Policies"
      echo ""
      echo "Required policy settings:"
      echo ""
      echo "  Vault Creation:"
      if [ "${var.profile_level}" -ge 2 ]; then
        echo "    Restrict to admins only (L2+)"
      else
        echo "    Allow for team members (L1 default)"
      fi
      echo ""
      echo "  External Sharing:"
      if [ "${var.profile_level}" -ge 2 ]; then
        echo "    Require approval for external sharing (L2+)"
      else
        echo "    Configure external sharing restrictions"
      fi
      if [ "${var.profile_level}" -ge 3 ]; then
        echo "    Disable external sharing entirely (L3)"
      fi
      echo ""
      echo "  Travel Mode:"
      echo "    Enable Travel Mode capability"
      if [ "${var.profile_level}" -ge 2 ]; then
        echo "    Restrict vault visibility during travel (L2+)"
      fi
      echo ""
      echo "  Account Recovery:"
      echo "    Enable recovery group"
      if [ "${var.profile_level}" -ge 2 ]; then
        echo "    Limit recovery group to designated admins (L2+)"
      fi
    EOT
  }
}

# Store team policy audit record.
resource "onepassword_item" "team_policies_audit" {
  vault    = data.onepassword_vault.infrastructure.uuid
  title    = "HTH Team Member Policies Configuration"
  category = "secure_note"

  section {
    label = "Policy Settings"

    field {
      label = "Profile Level"
      value = tostring(var.profile_level)
      type  = "STRING"
    }

    field {
      label = "Vault Creation"
      value = var.profile_level >= 2 ? "Admins only" : "Team members allowed"
      type  = "STRING"
    }

    field {
      label = "External Sharing"
      value = var.profile_level >= 3 ? "Disabled" : var.profile_level >= 2 ? "Approval required" : "Restricted"
      type  = "STRING"
    }

    field {
      label = "Travel Mode"
      value = "Enabled"
      type  = "STRING"
    }

    field {
      label = "Recovery Group"
      value = var.profile_level >= 2 ? "Designated admins only" : "Enabled"
      type  = "STRING"
    }
  }

  tags = ["hth-hardening", "team-policies", "audit"]
}

# HTH Guide Excerpt: end terraform
