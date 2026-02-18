# =============================================================================
# HTH SendGrid Control 1.3: Configure SSO Teammates
# Profile Level: L2 (Hardened)
# Frameworks: CIS 5.3, NIST AC-2
# Source: https://howtoharden.com/guides/sendgrid/#13-configure-sso-teammates
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "sendgrid_sso_teammate" "managed" {
  for_each = var.profile_level >= 2 ? {
    for t in var.sso_teammates : t.email => t
  } : {}

  email      = each.value.email
  first_name = each.value.first_name
  last_name  = each.value.last_name
  is_admin   = each.value.is_admin
  scopes     = each.value.scopes
}
# HTH Guide Excerpt: end terraform
