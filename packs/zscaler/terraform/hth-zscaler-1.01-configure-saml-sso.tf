# =============================================================================
# HTH Zscaler Control 1.1: Configure SAML SSO Authentication
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-2, IA-8 | CIS 6.3, 12.5
# Source: https://howtoharden.com/guides/zscaler/#11-configure-saml-sso-authentication
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Note: ZIA SAML SSO configuration is managed through the ZIA Admin Portal
# (Administration > Authentication Settings). The ZIA Terraform provider does
# not currently expose SAML IdP configuration as a managed resource.
#
# ZPA IdP configuration is created via the ZPA Admin Portal and can be
# referenced as a data source for use in access policies.

data "zpa_idp_controller" "corporate_idp" {
  count = var.idp_id != "" ? 0 : 1
  name  = "Corporate-SSO"
}

locals {
  idp_id = var.idp_id != "" ? var.idp_id : try(data.zpa_idp_controller.corporate_idp[0].id, "")
}

# HTH Guide Excerpt: end terraform
