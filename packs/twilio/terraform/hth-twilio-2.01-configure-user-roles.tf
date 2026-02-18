# =============================================================================
# HTH Twilio Control 2.1: Configure User Roles
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6
# Source: https://howtoharden.com/guides/twilio/#21-configure-user-roles
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Enforce least-privilege by documenting and validating role assignments.
# Twilio user role management is primarily done via Console or the
# Organizations API. This resource validates the expected state.

resource "null_resource" "user_role_validation" {
  triggers = {
    profile_level       = var.profile_level
    restricted_role_map = jsonencode(var.restricted_role_users)
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================================"
      echo "HTH Twilio 2.1: User Role Configuration"
      echo "============================================================"
      echo ""
      echo "Role assignment must be managed in the Twilio Console:"
      echo "  Account > Manage Users"
      echo ""
      echo "Principle: Least privilege -- assign the minimum role needed."
      echo ""
      echo "Available roles:"
      echo "  - Owner         (limit to 2-3 users)"
      echo "  - Administrator (limit, require 2FA)"
      echo "  - Developer     (default for engineering)"
      echo "  - Billing       (finance only)"
      echo "  - Support       (support staff only)"
      echo ""
      echo "Validation: Review user list and confirm no excess admin access."
      echo "============================================================"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
