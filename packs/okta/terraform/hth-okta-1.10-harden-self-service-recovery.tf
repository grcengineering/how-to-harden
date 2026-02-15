# =============================================================================
# HTH Okta Control 1.10: Harden Self-Service Recovery
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5(1), IA-11
# Source: https://howtoharden.com/guides/okta/#110-harden-self-service-recovery
# =============================================================================

# HTH Guide Excerpt: begin terraform
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
# HTH Guide Excerpt: end terraform
