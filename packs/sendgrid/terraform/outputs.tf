# =============================================================================
# SendGrid Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.2: SAML Single Sign-On (L2+)
# -----------------------------------------------------------------------------

output "sso_integration_id" {
  description = "ID of the SSO integration (L2+ only)"
  value       = var.profile_level >= 2 && var.sso_signin_url != "" ? sendgrid_sso_integration.corporate[0].id : null
}

output "sso_audience_url" {
  description = "SendGrid SAML audience URL to configure in your IdP (L2+ only)"
  value       = var.profile_level >= 2 && var.sso_signin_url != "" ? sendgrid_sso_integration.corporate[0].audience_url : null
}

output "sso_single_signon_url" {
  description = "SendGrid SAML single sign-on URL to configure in your IdP (L2+ only)"
  value       = var.profile_level >= 2 && var.sso_signin_url != "" ? sendgrid_sso_integration.corporate[0].single_signon_url : null
}


# -----------------------------------------------------------------------------
# Section 1.3: SSO Teammates (L2+)
# -----------------------------------------------------------------------------

output "sso_teammate_emails" {
  description = "List of SSO teammate email addresses provisioned (L2+ only)"
  value       = var.profile_level >= 2 ? [for t in sendgrid_sso_teammate.managed : t.email] : []
}


# -----------------------------------------------------------------------------
# Section 2.1: API Keys
# -----------------------------------------------------------------------------

output "api_key_ids" {
  description = "Map of API key names to their IDs"
  value       = { for k, v in sendgrid_api_key.managed : k => v.id }
}

output "api_key_values" {
  description = "Map of API key names to their secret values (sensitive)"
  value       = { for k, v in sendgrid_api_key.managed : k => v.api_key }
  sensitive   = true
}


# -----------------------------------------------------------------------------
# Section 3.2: Teammate Permissions
# -----------------------------------------------------------------------------

output "teammate_usernames" {
  description = "Map of teammate email addresses to their assigned usernames"
  value       = { for k, v in sendgrid_teammate.managed : k => v.username }
}


# -----------------------------------------------------------------------------
# Section 3.3: Sender Authentication
# -----------------------------------------------------------------------------

output "sender_authentication_id" {
  description = "ID of the authenticated sender domain"
  value       = var.authenticated_domain != "" ? sendgrid_sender_authentication.primary[0].id : null
}

output "sender_authentication_valid" {
  description = "Whether the authenticated domain DNS records are valid"
  value       = var.authenticated_domain != "" ? sendgrid_sender_authentication.primary[0].valid : null
}

output "sender_authentication_dns" {
  description = "DNS records required for sender authentication"
  value       = var.authenticated_domain != "" ? sendgrid_sender_authentication.primary[0].dns : null
}

output "link_branding_id" {
  description = "ID of the branded link configuration"
  value       = var.link_branding_domain != "" ? sendgrid_link_branding.primary[0].id : null
}

output "link_branding_valid" {
  description = "Whether the branded link DNS records are valid"
  value       = var.link_branding_domain != "" ? sendgrid_link_branding.primary[0].valid : null
}

output "link_branding_dns" {
  description = "DNS records required for link branding"
  value       = var.link_branding_domain != "" ? sendgrid_link_branding.primary[0].dns : null
}


# -----------------------------------------------------------------------------
# Section 4.2: Event Webhooks (L2+)
# -----------------------------------------------------------------------------

output "event_webhook_id" {
  description = "ID of the event webhook (L2+ only)"
  value       = var.profile_level >= 2 && var.event_webhook_url != "" ? sendgrid_event_webhook.security[0].id : null
}

output "event_webhook_public_key" {
  description = "Public key for verifying event webhook signatures (L2+ only)"
  value       = var.profile_level >= 2 && var.event_webhook_url != "" ? sendgrid_event_webhook.security[0].public_key : null
}


# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

output "profile_level_applied" {
  description = "The hardening profile level that was applied"
  value       = var.profile_level
}

output "hardening_summary" {
  description = "Summary of hardening controls applied at the selected profile level"
  value = {
    profile_level             = var.profile_level
    l1_controls_applied       = true
    l2_controls_applied       = var.profile_level >= 2
    l3_controls_applied       = var.profile_level >= 3
    api_keys_created          = length(var.api_keys)
    teammates_provisioned     = length(var.teammates)
    sso_configured            = var.profile_level >= 2 && var.sso_signin_url != ""
    sso_teammates_provisioned = var.profile_level >= 2 ? length(var.sso_teammates) : 0
    sender_authentication     = var.authenticated_domain != "" ? "configured" : "not configured"
    link_branding             = var.link_branding_domain != "" ? "configured" : "not configured"
    event_webhook             = var.profile_level >= 2 && var.event_webhook_url != "" ? "enabled" : "not configured"
    two_factor_auth           = "mandatory (SendGrid enforced since Q4 2020)"
    ip_access_management      = "requires manual configuration via UI/API"
  }
}
