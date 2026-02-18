# =============================================================================
# HTH Microsoft 365 Control 5.2: Configure Security Alerts and Microsoft Defender
# Profile Level: L1 (Baseline)
# Source: https://howtoharden.com/guides/microsoft-365/#52-configure-security-alerts-and-microsoft-defender
# =============================================================================

# HTH Guide Excerpt: begin terraform

# NOTE: Microsoft Defender for Office 365 alert policies are managed through
# the Security & Compliance PowerShell module, not the azuread provider.
#
# This file provisions the Azure AD group structure needed for alert routing
# and the Conditional Access policy for risky sign-in detection.

# Security operations group for alert notification routing
resource "azuread_group" "security_operations" {
  display_name     = "HTH: Security Operations"
  description      = "Security team members receiving Defender and audit alert notifications"
  security_enabled = true
  mail_enabled     = false
}

# L1: Conditional Access policy responding to sign-in risk
# Requires Entra ID P2 for risk-based Conditional Access
resource "azuread_conditional_access_policy" "risky_signin_mfa" {
  display_name = "HTH: Require MFA for risky sign-ins"
  state        = "enabled"

  conditions {
    users {
      included_users = ["All"]
      excluded_users = [for u in data.azuread_user.break_glass : u.object_id]
    }

    applications {
      included_applications = ["All"]
    }

    sign_in_risk_levels = ["medium", "high"]
    client_app_types    = ["all"]
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }
}

# L2+: Block high-risk sign-ins entirely
resource "azuread_conditional_access_policy" "block_high_risk_signin" {
  count = var.profile_level >= 2 ? 1 : 0

  display_name = "HTH: Block high-risk sign-ins"
  state        = "enabled"

  conditions {
    users {
      included_users = ["All"]
      excluded_users = [for u in data.azuread_user.break_glass : u.object_id]
    }

    applications {
      included_applications = ["All"]
    }

    sign_in_risk_levels = ["high"]
    client_app_types    = ["all"]
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}

# L2+: Respond to user risk -- require password change for risky users
resource "azuread_conditional_access_policy" "risky_user_remediation" {
  count = var.profile_level >= 2 ? 1 : 0

  display_name = "HTH: Require password change for risky users"
  state        = "enabled"

  conditions {
    users {
      included_users = ["All"]
      excluded_users = [for u in data.azuread_user.break_glass : u.object_id]
    }

    applications {
      included_applications = ["All"]
    }

    user_risk_levels = ["high"]
    client_app_types = ["all"]
  }

  grant_controls {
    operator          = "AND"
    built_in_controls = ["mfa", "passwordChange"]
  }
}

# HTH Guide Excerpt: end terraform
