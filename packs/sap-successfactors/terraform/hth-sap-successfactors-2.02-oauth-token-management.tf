# =============================================================================
# HTH SAP SuccessFactors Control 2.2: OAuth Token Management
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5(13)
# Source: https://howtoharden.com/guides/sap-successfactors/#22-oauth-token-management
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Token management is primarily handled through the XSUAA service instance
# parameters in control 2.1. This file enforces token lifetime governance
# through a dedicated service instance with strict expiration policies.

# L1: Standard token governance service instance
resource "btp_subaccount_service_instance" "sf_token_governance" {
  subaccount_id  = var.btp_subaccount_id
  name           = "hth-sf-token-governance"
  serviceplan_id = data.btp_subaccount_service_plan.xsuaa_application.id
  parameters = jsonencode({
    xsappname   = "hth-sf-token-gov"
    tenant-mode = "dedicated"
    oauth2-configuration = {
      # L1: Access token = 1 hour, Refresh token = 24 hours
      token-validity         = var.access_token_validity_seconds
      refresh-token-validity = var.refresh_token_validity_seconds
      # Disable client credentials grant to prevent unattended token minting
      grant-types = [
        "authorization_code",
        "refresh_token"
      ]
      redirect-uris = []
    }
  })
}

# L2+: Enforce tighter refresh token lifetime (8 hours)
resource "btp_subaccount_service_instance" "sf_token_governance_l2" {
  count = var.profile_level >= 2 ? 1 : 0

  subaccount_id  = var.btp_subaccount_id
  name           = "hth-sf-token-governance-l2"
  serviceplan_id = data.btp_subaccount_service_plan.xsuaa_application.id
  parameters = jsonencode({
    xsappname   = "hth-sf-token-gov-l2"
    tenant-mode = "dedicated"
    oauth2-configuration = {
      # L2: Access token = 1 hour, Refresh token = 8 hours
      token-validity         = 3600
      refresh-token-validity = 28800
      grant-types = [
        "authorization_code",
        "refresh_token"
      ]
      redirect-uris = []
    }
  })
}

# L3: Disable refresh tokens entirely -- require re-authentication
resource "btp_subaccount_service_instance" "sf_token_governance_l3" {
  count = var.profile_level >= 3 ? 1 : 0

  subaccount_id  = var.btp_subaccount_id
  name           = "hth-sf-token-governance-l3"
  serviceplan_id = data.btp_subaccount_service_plan.xsuaa_application.id
  parameters = jsonencode({
    xsappname   = "hth-sf-token-gov-l3"
    tenant-mode = "dedicated"
    oauth2-configuration = {
      # L3: Access token = 30 minutes, no refresh tokens
      token-validity = 1800
      grant-types = [
        "authorization_code"
      ]
      redirect-uris = []
    }
  })
}
# HTH Guide Excerpt: end terraform
