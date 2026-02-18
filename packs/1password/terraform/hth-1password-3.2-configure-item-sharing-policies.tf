# =============================================================================
# HTH 1Password Control 3.2: Configure Item Sharing Policies
# Profile Level: L2 (Hardened)
# Source: https://howtoharden.com/guides/1password/#32-configure-item-sharing-policies
# =============================================================================
#
# Item sharing policies control how credentials can be shared within and
# outside the organization. These are admin-level settings configured via
# Admin Console > Policies > Sharing.
#
# L2 restricts guest sharing and requires approval. L3 disables share links
# or enforces strict expiration and view limits.
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Document and verify item sharing policy configuration (L2+ only).
resource "null_resource" "verify_sharing_policies" {
  count = var.profile_level >= 2 ? 1 : 0

  triggers = {
    profile_level       = var.profile_level
    allow_item_sharing  = tostring(var.allow_item_sharing)
    allow_guest_sharing = tostring(var.allow_guest_sharing)
    link_expiry_hours   = var.share_link_expiry_hours
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "======================================================="
      echo "HTH 1Password Control 3.2: Item Sharing Policies"
      echo "======================================================="
      echo ""
      echo "Profile Level: ${var.profile_level}"
      echo ""
      echo "Navigate to: Admin Console > Policies > Sharing"
      echo ""
      echo "Required sharing policy settings:"
      echo ""
      echo "  Allow item sharing:       ${var.allow_item_sharing}"
      echo "  Allow sharing with guests: ${var.allow_guest_sharing}"
      echo ""
      if [ "${var.profile_level}" -ge 2 ]; then
        echo "  L2 Requirements:"
        echo "    - Disable guest sharing or require approval"
        echo "    - Configure share link expiration: ${var.share_link_expiry_hours}h"
      fi
      if [ "${var.profile_level}" -ge 3 ]; then
        echo ""
        echo "  L3 Requirements:"
        echo "    - Disable share links entirely, OR:"
        echo "    - Maximum link expiration: 24 hours"
        echo "    - Require view limits on all share links"
        echo "    - Disable guest access completely"
      fi
    EOT
  }
}

# Store sharing policy audit record (L2+ only).
resource "onepassword_item" "sharing_policies_audit" {
  count = var.profile_level >= 2 ? 1 : 0

  vault    = onepassword_vault.infrastructure[0].uuid
  title    = "HTH Item Sharing Policies Configuration"
  category = "secure_note"

  section {
    label = "Sharing Settings"

    field {
      label = "Profile Level"
      value = tostring(var.profile_level)
      type  = "STRING"
    }

    field {
      label = "Item Sharing"
      value = var.allow_item_sharing ? "Allowed" : "Disabled"
      type  = "STRING"
    }

    field {
      label = "Guest Sharing"
      value = var.allow_guest_sharing ? "Allowed" : "Disabled"
      type  = "STRING"
    }

    field {
      label = "Share Link Expiry"
      value = var.profile_level >= 3 ? "24 hours (or disabled)" : "${var.share_link_expiry_hours} hours"
      type  = "STRING"
    }

    field {
      label = "View Limits"
      value = var.profile_level >= 3 ? "Required" : "Optional"
      type  = "STRING"
    }
  }

  tags = ["hth-hardening", "sharing-policy", "data-protection"]
}

# HTH Guide Excerpt: end terraform
