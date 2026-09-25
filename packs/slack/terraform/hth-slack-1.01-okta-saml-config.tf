# =============================================================================
# HTH Pack Contract: v1
#   control: slack-1.1
#   guide:   https://howtoharden.com/guides/slack/#11-enable-saml-single-sign-on-sso
#   profile: L1
#   mode:    mutating
#   requires: okta/okta provider credentials for a sandbox or production Okta org (Okta, not Slack)
# =============================================================================
# HTH Slack Control 1.1: Okta SAML SSO Configuration
# Profile: L1 | NIST: IA-2, IA-8
# Source: https://registry.terraform.io/providers/okta/okta/latest/docs
#
# Creates the Okta side of Slack SAML SSO from Okta's preconfigured Slack app.
# The provider lives at okta/okta: without the required_providers block below,
# `terraform init` resolves the implicit hashicorp/okta, which does not exist.
# This is an SSO change in the IdP: plan it against a sandbox Okta org first.
# =============================================================================

# HTH Guide Excerpt: begin terraform-okta-saml
terraform {
  required_providers {
    okta = {
      source  = "okta/okta"
      version = "~> 7.0"
    }
  }
}

resource "okta_app_saml" "slack" {
  label             = "Slack"
  preconfigured_app = "slack"

  saml_version = "2.0"

  attribute_statements {
    name      = "User.Email"
    type      = "EXPRESSION"
    values    = ["user.email"]
  }
}

resource "okta_app_user_base_schema_property" "slack_user" {
  app_id      = okta_app_saml.slack.id
  index       = "userName"
  title       = "Username"
  type        = "string"
  master      = "PROFILE_MASTER"
}
# HTH Guide Excerpt: end terraform-okta-saml
