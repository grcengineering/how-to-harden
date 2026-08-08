# =============================================================================
# HTH GitLab Control 1.1: Configure SAML SSO (Self-Managed)
# Profile: L1 | NIST: IA-2(1)
# =============================================================================

# HTH Guide Excerpt: begin cli-configure-saml-sso
# /etc/gitlab/gitlab.rb

# SAML Configuration
gitlab_rails['omniauth_enabled'] = true
gitlab_rails['omniauth_allow_single_sign_on'] = ['saml']
gitlab_rails['omniauth_block_auto_created_users'] = false
gitlab_rails['omniauth_providers'] = [
  {
    name: 'saml',
    args: {
      assertion_consumer_service_url: 'https://gitlab.company.com/users/auth/saml/callback',
      idp_cert_fingerprint: 'XX:XX:XX...',
      idp_sso_target_url: 'https://idp.company.com/saml/sso',
      issuer: 'https://gitlab.company.com',
      name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
    }
  }
]

# Disable password authentication
gitlab_rails['gitlab_signin_enabled'] = false
# HTH Guide Excerpt: end cli-configure-saml-sso
