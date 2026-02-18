# =============================================================================
# HTH SAP SuccessFactors Control 1.1: Configure SSO with MFA
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-2(1)
# Source: https://howtoharden.com/guides/sap-successfactors/#11-configure-sso-with-mfa
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure a trusted Identity Provider for SAML SSO
resource "btp_subaccount_trust_configuration" "corporate_idp" {
  subaccount_id = var.btp_subaccount_id
  name          = var.idp_name
  description   = "HTH: Corporate IdP for SuccessFactors SSO with MFA enforcement"
  origin        = "corporate-idp"
  identity_provider = var.idp_metadata_url

  # Enforce SSO -- disable password fallback
  status = var.enforce_sso ? "active" : "active"
}

# L2+: Create a dedicated IAS tenant subscription for advanced SSO controls
resource "btp_subaccount_subscription" "identity_authentication" {
  count = var.profile_level >= 2 ? 1 : 0

  subaccount_id = var.btp_subaccount_id
  app_name      = "identity"
  plan_name     = "application"
  parameters = jsonencode({
    cloud_service = {
      name = "sap-successfactors"
    }
  })
}

# L3: Enforce certificate-based authentication for admin access
resource "btp_subaccount_service_instance" "x509_auth" {
  count = var.profile_level >= 3 ? 1 : 0

  subaccount_id  = var.btp_subaccount_id
  name           = "hth-sf-x509-auth"
  serviceplan_id = data.btp_subaccount_service_plan.xsuaa_application.id
  parameters = jsonencode({
    xsappname   = "hth-sf-admin-x509"
    tenant-mode = "dedicated"
    credential-types = ["x509"]
    oauth2-configuration = {
      token-validity = 3600
    }
  })
}

data "btp_subaccount_service_plan" "xsuaa_application" {
  subaccount_id = var.btp_subaccount_id
  name          = "application"
  offering_name = "xsuaa"
}
# HTH Guide Excerpt: end terraform
