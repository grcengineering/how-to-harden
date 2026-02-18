# =============================================================================
# HTH Jenkins Control 1.2: Configure LDAP or SAML SSO
# Profile Level: L2 (Hardened)
# Frameworks: CIS 6.3/12.5, NIST IA-2/IA-8
# Source: https://howtoharden.com/guides/jenkins/#12-configure-ldap-or-saml-sso
#
# NOTE: SSO configuration is a system-level setting managed via JCasC.
# This file generates the JCasC YAML for SAML or LDAP security realm.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# JCasC configuration for SAML SSO (L2+)
resource "local_file" "configure_saml_sso" {
  count = var.profile_level >= 2 && var.sso_type == "saml" ? 1 : 0

  filename = "${path.module}/generated/casc-saml-sso.yaml"
  content  = yamlencode({
    jenkins = {
      securityRealm = {
        saml = {
          idpMetadataConfiguration = {
            url = var.saml_idp_metadata_url
          }
          usernameAttributeName     = var.saml_username_attribute
          emailAttributeName        = var.saml_email_attribute
          groupsAttributeName       = var.saml_group_attribute
          maximumAuthenticationLifetime = 86400
          binding                   = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
        }
      }
    }
  })

  file_permission = "0644"
}

# JCasC configuration for LDAP authentication (L2+)
resource "local_file" "configure_ldap" {
  count = var.profile_level >= 2 && var.sso_type == "ldap" ? 1 : 0

  filename = "${path.module}/generated/casc-ldap.yaml"
  content  = yamlencode({
    jenkins = {
      securityRealm = {
        ldap = {
          configurations = [
            {
              server                  = var.ldap_server_url
              rootDN                  = var.ldap_root_dn
              userSearchBase          = var.ldap_user_search_base
              userSearch              = var.ldap_user_search_filter
              groupSearchBase         = var.ldap_group_search_base
              inhibitInferRootDN      = false
              managerDN               = var.ldap_manager_dn
              managerPasswordSecret   = var.ldap_manager_password
            }
          ]
          disableMailAddressResolver = false
          disableRolePrefixing       = true
        }
      }
    }
  })

  file_permission = "0644"
}
# HTH Guide Excerpt: end terraform
