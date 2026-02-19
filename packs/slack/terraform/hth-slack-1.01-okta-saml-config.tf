# =============================================================================
# HTH Slack Control 1.1: Okta SAML SSO Configuration
# Profile: L1 | NIST: IA-2, IA-8
# =============================================================================

# HTH Guide Excerpt: begin terraform-okta-saml
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
