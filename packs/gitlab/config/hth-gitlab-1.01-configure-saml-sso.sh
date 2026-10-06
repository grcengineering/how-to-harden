#!/usr/bin/env bash
# =============================================================================
# HTH GitLab Control 1.1: Configure SAML SSO (Self-Managed)
# Profile: L1 | NIST: IA-2(1)
# https://howtoharden.com/guides/gitlab/#11-enforce-sso-with-mfa
#
# Config emitter: prints an Omnibus gitlab.rb SAML block for you to merge into
# /etc/gitlab/gitlab.rb, then apply with `sudo gitlab-ctl reconfigure`. It
# writes nothing itself. Keys and example values follow the SAML example in
# docs.gitlab.com/integration/saml -- replace the hostnames and fingerprint.
#
# Password sign-in is NOT a gitlab.rb setting on current GitLab. Turn it off
# once SAML sign-in works for an administrator (a lockout risk otherwise):
# Admin > Settings > General > Sign-in restrictions, or the application
# settings API fields password_authentication_enabled_for_web and
# password_authentication_enabled_for_git (docs.gitlab.com/api/settings).
# =============================================================================
set -euo pipefail

cat <<'RUBY'
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
      assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
      idp_cert_fingerprint: 'XX:XX:XX...',
      idp_sso_target_url: 'https://idp.example.com/saml/sso',
      issuer: 'https://gitlab.example.com',
      name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
    }
  }
]
# HTH Guide Excerpt: end cli-configure-saml-sso
RUBY
