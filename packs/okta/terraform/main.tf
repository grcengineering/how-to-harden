# =============================================================================
# Okta Hardening Code Pack - Main Resources
# How to Harden (howtoharden.com)
#
# All resources extracted from the Okta Hardening Guide.
# Profile-level guards: L1 = always applied, L2+ = count-gated.
#
# Source: https://howtoharden.com/guides/okta/
# =============================================================================


# =============================================================================
# Section 1.1: Phishing-Resistant MFA (FIDO2/WebAuthn)
# Profile Level: L1 (Baseline)
# Guide: Authentication & Access Controls > 1.1
# Frameworks: CIS 6.3/6.5, NIST IA-2(1)/IA-2(6), DISA STIG V-273190/191/193/194
# =============================================================================

# Enable FIDO2 (WebAuthn) as an authenticator
resource "okta_authenticator" "fido2" {
  name   = "FIDO2 WebAuthn"
  key    = "webauthn"
  status = "ACTIVE"
  settings = jsonencode({
    userVerification = "REQUIRED"
    attachment       = "ANY"
  })
}

# Signon policy requiring phishing-resistant MFA for admins
resource "okta_policy_signon" "phishing_resistant" {
  name        = "Phishing-Resistant MFA Policy"
  status      = "ACTIVE"
  description = "Requires FIDO2 for all admin access"
  priority    = 1

  groups_included = [var.admin_group_id]
}

# Rule enforcing FIDO2 on the phishing-resistant policy
resource "okta_policy_rule_signon" "require_fido2" {
  policy_id          = okta_policy_signon.phishing_resistant.id
  name               = "Require FIDO2"
  status             = "ACTIVE"
  priority           = 1
  access             = "ALLOW"
  mfa_required       = true
  mfa_prompt         = "ALWAYS"
  primary_factor     = "PASSWORD_IDP_ANY_FACTOR"
  session_lifetime   = 120
  session_persistent = false
}


# =============================================================================
# Section 1.9: Audit Default Authentication Policy
# Profile Level: L1 (Baseline)
# Guide: Authentication & Access Controls > 1.9
# Frameworks: NIST AC-3, IA-2
# =============================================================================

# Reference the immutable Default Authentication Policy
data "okta_policy" "default_access" {
  name = "Default Policy"
  type = "ACCESS_POLICY"
}

# Custom catch-all policy to replace reliance on the default policy
resource "okta_app_signon_policy" "mfa_required" {
  name        = "MFA Required - All Applications"
  description = "Enforces MFA for all applications - prevents fallthrough to default policy"
}

# Catch-all deny rule (lowest priority in custom policy)
resource "okta_app_signon_policy_rule" "catch_all_deny" {
  policy_id          = okta_app_signon_policy.mfa_required.id
  name               = "Catch-All Deny"
  priority           = 99
  access             = "DENY"
  factor_mode        = "2FA"
  constraints        = []
  groups_excluded    = []
  groups_included    = ["EVERYONE"]
  network_connection = "ANYWHERE"
}

# MFA enforcement rule (higher priority than catch-all)
resource "okta_app_signon_policy_rule" "require_mfa" {
  policy_id                   = okta_app_signon_policy.mfa_required.id
  name                        = "Require MFA"
  priority                    = 1
  access                      = "ALLOW"
  factor_mode                 = "2FA"
  groups_included             = ["EVERYONE"]
  network_connection          = "ANYWHERE"
  re_authentication_frequency = "PT2H"
}


# =============================================================================
# Section 1.10: Harden Self-Service Recovery
# Profile Level: L1 (Baseline)
# Guide: Authentication & Access Controls > 1.10
# Frameworks: NIST IA-5(1), IA-11
# =============================================================================

# Deactivate security question authenticator
resource "okta_authenticator" "security_question" {
  name   = "Security Question"
  key    = "security_question"
  status = "INACTIVE"
}

# Configure phone authenticator -- remove recovery usage, keep for auth only
resource "okta_authenticator" "phone" {
  name   = "Phone"
  key    = "phone_number"
  status = "ACTIVE"
  settings = jsonencode({
    allowedFor = "authentication"
  })
}

# Password policy with hardened recovery settings
resource "okta_policy_password" "hardened_recovery" {
  name                     = "Hardened Password Policy"
  status                   = "ACTIVE"
  description              = "Password policy with restricted recovery methods"
  priority                 = 1
  password_min_length      = var.password_min_length
  password_min_lowercase   = 1
  password_min_uppercase   = 1
  password_min_number      = 1
  password_min_symbol      = 1
  password_max_age_days    = var.password_max_age_days
  password_min_age_minutes = 1440
  password_history_count   = var.password_history_count
  recovery_email_token     = 1
  email_recovery           = "ACTIVE"
  sms_recovery             = "INACTIVE"
  call_recovery            = "INACTIVE"
  question_recovery        = "INACTIVE"

  groups_included = [var.everyone_group_id]
}


# =============================================================================
# Section 1.11: Enable End-User Security Notifications
# Profile Level: L1 (Baseline)
# Guide: Authentication & Access Controls > 1.11
# Frameworks: NIST SI-4, IR-6
# =============================================================================

# Org-level configuration for end-user support
resource "okta_org_configuration" "notifications" {
  end_user_support_help_url = var.support_url

  # End-user notification settings are managed via the org settings API.
  # Use the provisioners below for full control.
}

# Enable Suspicious Activity Reporting via API call
# (Not all org-level settings are natively supported in Terraform)
resource "null_resource" "enable_suspicious_activity_reporting" {
  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X POST "https://${var.okta_domain}/api/v1/org/privacy/suspicious-activity-reporting" \
        -H "Authorization: SSWS ${var.okta_api_token}" \
        -H "Content-Type: application/json" \
        -d '{"enabled": true}'
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}

# Enable all end-user notification types via API call
resource "null_resource" "enable_end_user_notifications" {
  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X PUT "https://${var.okta_domain}/api/v1/org/settings" \
        -H "Authorization: SSWS ${var.okta_api_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "endUserNotifications": {
            "newSignOnNotification": {"enabled": true},
            "authenticatorEnrolledNotification": {"enabled": true},
            "authenticatorResetNotification": {"enabled": true},
            "passwordChangedNotification": {"enabled": true},
            "factorResetNotification": {"enabled": true}
          }
        }'
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}


# =============================================================================
# Section 2.3: Dynamic Network Zones and Anonymizer Blocking
# Profile Level: L2 (Hardened)
# Guide: Network Access Controls > 2.3
# Frameworks: NIST AC-3, SC-7
# =============================================================================

# Block anonymizing proxies and Tor exit nodes
resource "okta_network_zone" "block_anonymizers" {
  count = var.profile_level >= 2 ? 1 : 0

  name               = "Block Anonymizers"
  type               = "DYNAMIC_V2"
  status             = "ACTIVE"
  usage              = "BLOCKLIST"
  dynamic_proxy_type = "TorAnonymizer"
}

# Block traffic from high-risk countries
resource "okta_network_zone" "block_countries" {
  count = var.profile_level >= 2 ? 1 : 0

  name              = "Blocked Countries"
  type              = "DYNAMIC"
  status            = "ACTIVE"
  usage             = "BLOCKLIST"
  dynamic_locations = var.blocked_countries
}


# =============================================================================
# Section 3.4: Govern Non-Human Identities (NHI)
# Profile Level: L1 (Baseline)
# Guide: OAuth & Integration Security > 3.4
# Frameworks: CIS 6.2, NIST AC-6, CM-7
# =============================================================================

# OAuth 2.0 service app using client_credentials with private_key_jwt
resource "okta_app_oauth" "service_automation" {
  label                      = "SVC - Automation API Access"
  type                       = "service"
  grant_types                = ["client_credentials"]
  response_types             = ["token"]
  token_endpoint_auth_method = "private_key_jwt"
  pkce_required              = false

  jwks {
    kty = "RSA"
    e   = var.service_app_public_key_e
    n   = var.service_app_public_key_n
  }
}

# Grant minimum-required API scopes to the service app
resource "okta_app_oauth_api_scope" "users_read" {
  app_id = okta_app_oauth.service_automation.id
  issuer = "https://${var.okta_domain}"
  scopes = ["okta.users.read"]
}


# =============================================================================
# Section 4.2: Disable Session Persistence
# Profile Level: L2 (Hardened)
# Guide: Session Management > 4.2
# Frameworks: NIST SC-23, DISA STIG V-273206
# =============================================================================

# Global signon policy that disables persistent sessions
# Prevents session cookies from surviving browser restarts
resource "okta_policy_signon" "disable_session_persistence" {
  count = var.profile_level >= 2 ? 1 : 0

  name        = "Disable Session Persistence"
  status      = "ACTIVE"
  description = "Disables Remember Me and persistent session cookies to reduce session hijacking risk"
  priority    = 2
}

# Rule enforcing non-persistent sessions with strict timeouts
resource "okta_policy_rule_signon" "no_persistent_sessions" {
  count = var.profile_level >= 2 ? 1 : 0

  policy_id          = okta_policy_signon.disable_session_persistence[0].id
  name               = "No Persistent Sessions"
  status             = "ACTIVE"
  priority           = 1
  access             = "ALLOW"
  mfa_required       = true
  mfa_prompt         = "SESSION"
  session_lifetime   = 480
  session_idle       = 30
  session_persistent = false
}


# =============================================================================
# Section 2.1: Network Zones
# Profile Level: L1 (Baseline)
# Guide: Network Access Controls > 2.1
# Frameworks: CIS 6.7, NIST AC-3, SC-7
# =============================================================================

# Corporate network zone with configurable CIDRs
resource "okta_network_zone" "corporate" {
  count = length(var.corporate_gateway_cidrs) > 0 ? 1 : 0

  name     = "Corporate Network"
  type     = "IP"
  status   = "ACTIVE"
  gateways = var.corporate_gateway_cidrs
}

# IP blocklist zone
resource "okta_network_zone" "blocklist" {
  count = length(var.blocked_ip_cidrs) > 0 ? 1 : 0

  name     = "Blocked IPs"
  type     = "IP"
  status   = "ACTIVE"
  usage    = "BLOCKLIST"
  gateways = var.blocked_ip_cidrs
}


# =============================================================================
# Section 4.1: Session Timeouts
# Profile Level: L1 (Baseline)
# Guide: Session Management > 4.1
# Frameworks: NIST AC-12, SC-23, DISA STIG V-273206
# =============================================================================

# Global session policy with hardened timeout values
resource "okta_policy_signon" "session_timeouts" {
  name        = "Hardened Session Timeouts"
  status      = "ACTIVE"
  description = "Session timeout configuration per HTH hardening guide"
  priority    = 3
}

resource "okta_policy_rule_signon" "session_timeout_rule" {
  policy_id          = okta_policy_signon.session_timeouts.id
  name               = "Enforce Session Timeouts"
  status             = "ACTIVE"
  priority           = 1
  access             = "ALLOW"
  mfa_required       = true
  mfa_prompt         = "SESSION"
  session_lifetime   = var.session_max_lifetime_minutes
  session_idle       = var.session_max_idle_minutes
  session_persistent = false
}


# =============================================================================
# Section 5.2: ThreatInsight
# Profile Level: L1 (Baseline)
# Guide: Monitoring & Threat Detection > 5.2
# Frameworks: NIST SI-4, IR-4, DISA STIG V-273200
# =============================================================================

# Enable ThreatInsight in block mode
resource "okta_threat_policy" "threatinsight" {
  action = "block"
}


# =============================================================================
# Section 5.4: Behavior Detection
# Profile Level: L2 (Hardened)
# Guide: Monitoring & Threat Detection > 5.4
# Frameworks: NIST SI-4, AC-7
# =============================================================================

# Behavior detection rule for new location sign-on
resource "okta_behaviour" "new_location" {
  count = var.profile_level >= 2 ? 1 : 0

  name                      = "New Location Sign-On"
  type                      = "ANOMALOUS_LOCATION"
  status                    = "ACTIVE"
  number_of_authentications  = 3
  location_granularity_type  = "CITY"
}

# Behavior detection rule for new device
resource "okta_behaviour" "new_device" {
  count = var.profile_level >= 2 ? 1 : 0

  name                      = "New Device Sign-On"
  type                      = "ANOMALOUS_DEVICE"
  status                    = "ACTIVE"
  number_of_authentications  = 3
}
