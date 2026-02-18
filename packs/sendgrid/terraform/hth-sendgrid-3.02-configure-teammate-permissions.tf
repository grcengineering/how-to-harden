# =============================================================================
# HTH SendGrid Control 3.2: Configure Teammate Permissions
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6
# Source: https://howtoharden.com/guides/sendgrid/#32-configure-teammate-permissions
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "sendgrid_teammate" "managed" {
  for_each = {
    for t in var.teammates : t.email => t
  }

  email    = each.value.email
  is_admin = each.value.is_admin
  scopes   = each.value.scopes
}
# HTH Guide Excerpt: end terraform
