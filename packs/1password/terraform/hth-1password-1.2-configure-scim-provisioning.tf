# =============================================================================
# HTH 1Password Control 1.2: Configure SCIM Provisioning
# Profile Level: L2 (Hardened)
# Source: https://howtoharden.com/guides/1password/#12-configure-scim-provisioning
# =============================================================================
#
# SCIM provisioning syncs users and groups from your identity provider to
# 1Password. This requires deploying the 1Password SCIM Bridge, which runs
# as a container or on 1Password's infrastructure.
#
# The 1Password Terraform provider manages items/vaults, not SCIM. This
# control uses null_resource to verify SCIM bridge health and document setup.
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Verify SCIM bridge connectivity and health (L2+ only).
resource "null_resource" "verify_scim_provisioning" {
  count = var.profile_level >= 2 && var.scim_bridge_url != "" ? 1 : 0

  triggers = {
    scim_bridge_url = var.scim_bridge_url
    profile_level   = var.profile_level
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================="
      echo "HTH 1Password Control 1.2: SCIM Provisioning"
      echo "============================================="
      echo ""
      echo "SCIM Bridge URL: ${var.scim_bridge_url}"
      echo ""
      echo "Verifying SCIM bridge health..."
      HEALTH_RESPONSE=$(curl -sf "${var.scim_bridge_url}/health" 2>/dev/null)
      if [ $? -eq 0 ]; then
        echo "SCIM bridge is healthy: $HEALTH_RESPONSE"
      else
        echo "WARNING: SCIM bridge health check failed."
        echo "Ensure the SCIM bridge is deployed and accessible."
        echo ""
        echo "Deployment options:"
        echo "  - Docker: https://support.1password.com/scim-deploy-docker/"
        echo "  - Kubernetes: https://support.1password.com/scim-deploy-k8s/"
        echo "  - AWS ECS: https://support.1password.com/scim-deploy-aws/"
        echo "  - Google Cloud Run: https://support.1password.com/scim-deploy-gcp/"
      fi
      echo ""
      echo "Required SCIM provisioning features:"
      echo "  - Create users"
      echo "  - Update user attributes"
      echo "  - Deactivate users (removes 1Password access)"
      echo "  - Sync groups to 1Password groups"
    EOT
  }
}

# Store SCIM bridge configuration reference in a dedicated vault item.
resource "onepassword_item" "scim_bridge_config" {
  count = var.profile_level >= 2 && var.scim_bridge_url != "" ? 1 : 0

  vault    = data.onepassword_vault.infrastructure.uuid
  title    = "SCIM Bridge Configuration"
  category = "secure_note"

  section {
    label = "SCIM Bridge Details"

    field {
      label = "SCIM Bridge URL"
      value = var.scim_bridge_url
      type  = "STRING"
    }

    field {
      label = "Status"
      value = "Active"
      type  = "STRING"
    }

    field {
      label = "Profile Level"
      value = tostring(var.profile_level)
      type  = "STRING"
    }
  }

  tags = ["hth-hardening", "scim", "infrastructure"]
}

# HTH Guide Excerpt: end terraform
