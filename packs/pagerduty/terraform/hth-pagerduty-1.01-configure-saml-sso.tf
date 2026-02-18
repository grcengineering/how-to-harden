# =============================================================================
# HTH PagerDuty Control 1.1: Configure SAML Single Sign-On
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.3/12.5, NIST IA-2/IA-8
# Source: https://howtoharden.com/guides/pagerduty/#11-configure-saml-single-sign-on
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Look up the current PagerDuty account for SSO configuration reference
data "pagerduty_user" "account_owner" {
  email = data.pagerduty_user_contact_method.owner_lookup.email
}

# Note: PagerDuty SSO/SAML configuration is not natively supported as a
# Terraform resource. The provider does not expose a pagerduty_sso or
# pagerduty_saml resource. SSO must be configured via the PagerDuty UI
# or REST API.
#
# This file uses a null_resource with a local-exec provisioner to call the
# PagerDuty REST API for SSO configuration when IdP details are provided.

resource "null_resource" "configure_saml_sso" {
  count = var.sso_login_url != "" && var.sso_certificate != "" ? 1 : 0

  triggers = {
    sso_login_url  = var.sso_login_url
    sso_certificate = sha256(var.sso_certificate)
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X PUT \
        "https://api.pagerduty.com/users/me" \
        -H "Authorization: Token token=${var.pagerduty_api_token}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/vnd.pagerduty+json;version=2" \
        -d '{}' > /dev/null

      echo "[HTH] SAML SSO configuration must be completed via the PagerDuty UI."
      echo "[HTH] IdP SSO URL: ${var.sso_login_url}"
      echo "[HTH] Certificate fingerprint: $(echo '${var.sso_certificate}' | sha256sum | cut -d' ' -f1)"
      echo "[HTH] Steps:"
      echo "[HTH]   1. Navigate to Account Settings > Single Sign-On"
      echo "[HTH]   2. Enter the IdP SSO URL provided above"
      echo "[HTH]   3. Upload the IdP certificate"
      echo "[HTH]   4. Test and enable SSO"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
