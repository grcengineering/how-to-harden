# =============================================================================
# HTH SAP SuccessFactors Control 2.1: Secure OData API Access
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5
# Source: https://howtoharden.com/guides/sap-successfactors/#21-secure-odata-api-access
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create a dedicated XSUAA service instance for OData API integration
resource "btp_subaccount_service_instance" "sf_odata_oauth" {
  subaccount_id  = var.btp_subaccount_id
  name           = "hth-sf-odata-${var.oauth_client_name}"
  serviceplan_id = data.btp_subaccount_service_plan.xsuaa_application.id
  parameters = jsonencode({
    xsappname   = var.oauth_client_name
    tenant-mode = "dedicated"
    scopes = [
      {
        name        = "$XSAPPNAME.employee.read"
        description = "Read employee data via OData"
      }
    ]
    role-templates = [
      {
        name        = "ODataReader"
        description = "HTH: Minimum-privilege OData API reader"
        scope-references = [
          "$XSAPPNAME.employee.read"
        ]
      }
    ]
    oauth2-configuration = {
      token-validity         = var.access_token_validity_seconds
      refresh-token-validity = var.refresh_token_validity_seconds
      credential-types       = ["binding-secret"]
    }
  })
}

# Create a service binding (credentials) for the OAuth client
resource "btp_subaccount_service_binding" "sf_odata_binding" {
  subaccount_id       = var.btp_subaccount_id
  name                = "hth-sf-odata-binding"
  service_instance_id = btp_subaccount_service_instance.sf_odata_oauth.id
}

# L2+: Create an IP-restricted destination for OData API calls
resource "btp_subaccount_service_instance" "sf_destination" {
  count = var.profile_level >= 2 && length(var.api_allowed_ip_cidrs) > 0 ? 1 : 0

  subaccount_id  = var.btp_subaccount_id
  name           = "hth-sf-api-destination"
  serviceplan_id = data.btp_subaccount_service_plan.destination_lite.id
  parameters = jsonencode({
    HTML5Runtime_enabled = false
    init_data = {
      subaccount = {
        destinations = [
          {
            Name                     = "HTH-SuccessFactors-OData"
            Type                     = "HTTP"
            URL                      = "https://api.successfactors.com/odata/v2"
            Authentication           = "OAuth2SAMLBearerAssertion"
            ProxyType                = "Internet"
            "ip.filter.allowedCIDRs" = join(",", var.api_allowed_ip_cidrs)
          }
        ]
      }
    }
  })
}

data "btp_subaccount_service_plan" "destination_lite" {
  subaccount_id = var.btp_subaccount_id
  name          = "lite"
  offering_name = "destination"
}

# L3: Enforce mTLS for all API client connections
resource "btp_subaccount_service_instance" "sf_odata_mtls" {
  count = var.profile_level >= 3 ? 1 : 0

  subaccount_id  = var.btp_subaccount_id
  name           = "hth-sf-odata-mtls"
  serviceplan_id = data.btp_subaccount_service_plan.xsuaa_application.id
  parameters = jsonencode({
    xsappname   = "${var.oauth_client_name}-mtls"
    tenant-mode = "dedicated"
    credential-types = ["x509"]
    oauth2-configuration = {
      token-validity         = var.access_token_validity_seconds
      refresh-token-validity = var.refresh_token_validity_seconds
      credential-types       = ["x509"]
    }
  })
}
# HTH Guide Excerpt: end terraform
