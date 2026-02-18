# =============================================================================
# HTH Twilio Control 2.3: Limit Admin Access
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6(1)
# Source: https://howtoharden.com/guides/twilio/#23-limit-admin-access
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Admin access restriction is managed via the Twilio Console.
# This resource documents the expected admin posture and serves
# as a Terraform-tracked validation checkpoint.

resource "null_resource" "limit_admin_access_validation" {
  triggers = {
    profile_level = var.profile_level
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================================"
      echo "HTH Twilio 2.3: Limit Admin Access"
      echo "============================================================"
      echo ""
      echo "Admin access must be minimized in the Twilio Console:"
      echo "  Account > Manage Users"
      echo ""
      echo "Expected configuration (Profile Level ${var.profile_level}):"
      echo "  Owner accounts:      Maximum 2-3 users"
      echo "  Admin accounts:      Minimum necessary"
      echo "  Admin 2FA:           REQUIRED"
      echo "  Admin activity:      MONITORED"
      echo ""
      echo "Actions:"
      echo "  1. Inventory all Owner and Administrator accounts"
      echo "  2. Remove unnecessary admin privileges"
      echo "  3. Confirm 2FA is active for all admins"
      echo "  4. Enable admin activity monitoring"
      echo ""
      echo "Validation: Confirm max 2-3 Owner accounts exist."
      echo "============================================================"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
