# =============================================================================
# Okta Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: Phishing-Resistant MFA
# -----------------------------------------------------------------------------

output "fido2_authenticator_id" {
  description = "ID of the FIDO2 (WebAuthn) authenticator"
  value       = okta_authenticator.fido2.id
}

output "phishing_resistant_policy_id" {
  description = "ID of the phishing-resistant signon policy"
  value       = okta_policy_signon.phishing_resistant.id
}

output "require_fido2_rule_id" {
  description = "ID of the FIDO2 enforcement rule"
  value       = okta_policy_rule_signon.require_fido2.id
}


# -----------------------------------------------------------------------------
# Section 1.9: Default Authentication Policy Audit
# -----------------------------------------------------------------------------

output "default_access_policy_id" {
  description = "ID of the immutable Default Authentication Policy (for audit reference)"
  value       = data.okta_policy.default_access.id
}

output "mfa_required_policy_id" {
  description = "ID of the custom MFA-required application signon policy"
  value       = okta_app_signon_policy.mfa_required.id
}

output "catch_all_deny_rule_id" {
  description = "ID of the catch-all deny rule in the MFA-required policy"
  value       = okta_app_signon_policy_rule.catch_all_deny.id
}

output "require_mfa_rule_id" {
  description = "ID of the MFA enforcement rule"
  value       = okta_app_signon_policy_rule.require_mfa.id
}


# -----------------------------------------------------------------------------
# Section 1.10: Self-Service Recovery Hardening
# -----------------------------------------------------------------------------

output "security_question_authenticator_id" {
  description = "ID of the deactivated security question authenticator"
  value       = okta_authenticator.security_question.id
}

output "phone_authenticator_id" {
  description = "ID of the phone authenticator (auth-only, no recovery)"
  value       = okta_authenticator.phone.id
}

output "hardened_password_policy_id" {
  description = "ID of the hardened password policy with restricted recovery"
  value       = okta_policy_password.hardened_recovery.id
}


# -----------------------------------------------------------------------------
# Section 2.3: Anonymizer Blocking (L2+)
# -----------------------------------------------------------------------------

output "block_anonymizers_zone_id" {
  description = "ID of the anonymizer-blocking network zone (L2+ only)"
  value       = var.profile_level >= 2 ? okta_network_zone.block_anonymizers[0].id : null
}

output "block_countries_zone_id" {
  description = "ID of the country-blocking network zone (L2+ only)"
  value       = var.profile_level >= 2 ? okta_network_zone.block_countries[0].id : null
}


# -----------------------------------------------------------------------------
# Section 3.4: Non-Human Identity Governance
# -----------------------------------------------------------------------------

output "service_app_id" {
  description = "ID of the OAuth 2.0 service automation app"
  value       = okta_app_oauth.service_automation.id
}

output "service_app_client_id" {
  description = "Client ID of the OAuth 2.0 service automation app"
  value       = okta_app_oauth.service_automation.client_id
}


# -----------------------------------------------------------------------------
# Section 4.2: Session Persistence (L2+)
# -----------------------------------------------------------------------------

output "session_persistence_policy_id" {
  description = "ID of the session persistence policy (L2+ only)"
  value       = var.profile_level >= 2 ? okta_policy_signon.disable_session_persistence[0].id : null
}


# -----------------------------------------------------------------------------
# Section 2.1: Network Zones
# -----------------------------------------------------------------------------

output "corporate_zone_id" {
  description = "ID of the corporate network zone"
  value       = length(var.corporate_gateway_cidrs) > 0 ? okta_network_zone.corporate[0].id : null
}

output "blocklist_zone_id" {
  description = "ID of the IP blocklist zone"
  value       = length(var.blocked_ip_cidrs) > 0 ? okta_network_zone.blocklist[0].id : null
}


# -----------------------------------------------------------------------------
# Section 4.1: Session Timeouts
# -----------------------------------------------------------------------------

output "session_timeout_policy_id" {
  description = "ID of the hardened session timeout policy"
  value       = okta_policy_signon.session_timeouts.id
}


# -----------------------------------------------------------------------------
# Section 5.2: ThreatInsight
# -----------------------------------------------------------------------------

output "threatinsight_action" {
  description = "ThreatInsight action mode (block/log)"
  value       = okta_threat_policy.threatinsight.action
}


# -----------------------------------------------------------------------------
# Section 5.4: Behavior Detection (L2+)
# -----------------------------------------------------------------------------

output "behavior_new_location_id" {
  description = "ID of the new location behavior detection rule (L2+ only)"
  value       = var.profile_level >= 2 ? okta_behaviour.new_location[0].id : null
}

output "behavior_new_device_id" {
  description = "ID of the new device behavior detection rule (L2+ only)"
  value       = var.profile_level >= 2 ? okta_behaviour.new_device[0].id : null
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
    profile_level          = var.profile_level
    l1_controls_applied    = true
    l2_controls_applied    = var.profile_level >= 2
    l3_controls_applied    = var.profile_level >= 3
    network_zones          = length(var.corporate_gateway_cidrs) > 0
    anonymizer_blocking    = var.profile_level >= 2
    country_blocking       = var.profile_level >= 2
    session_timeouts       = "configured"
    session_persistence    = var.profile_level >= 2 ? "disabled" : "default"
    threatinsight          = "block"
    behavior_detection     = var.profile_level >= 2
    fido2_enforced         = true
    security_questions     = "INACTIVE"
    sms_recovery           = "INACTIVE"
    suspicious_activity    = "ENABLED"
    end_user_notifications = "ENABLED"
  }
}
