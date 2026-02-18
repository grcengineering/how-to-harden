# =============================================================================
# HTH Microsoft 365 Control 1.1: Enforce Phishing-Resistant MFA for All Users
# Profile Level: L1 (Baseline)
# Source: https://howtoharden.com/guides/microsoft-365/#11-enforce-phishing-resistant-mfa-for-all-users
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Look up break-glass accounts to exclude from Conditional Access
data "azuread_user" "break_glass" {
  count               = length(var.break_glass_account_upns)
  user_principal_name = var.break_glass_account_upns[count.index]
}

# Conditional Access policy: Require MFA for all users
resource "azuread_conditional_access_policy" "require_mfa" {
  display_name = "HTH: Require MFA for all users"
  state        = var.mfa_policy_state

  conditions {
    users {
      included_users = ["All"]
      excluded_users = [for u in data.azuread_user.break_glass : u.object_id]
    }

    applications {
      included_applications = ["All"]
    }

    client_app_types = ["all"]
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }
}

# L2+: Require phishing-resistant authentication strength (FIDO2, WHfB, CBA)
resource "azuread_authentication_strength_policy" "phishing_resistant" {
  count = var.profile_level >= 2 ? 1 : 0

  display_name = "HTH: Phishing-Resistant MFA"
  description  = "Requires FIDO2 security keys, Windows Hello for Business, or certificate-based authentication"

  allowed_combinations = [
    "fido2",
    "windowsHelloForBusiness",
    "x509CertificateMultiFactor",
  ]
}

# L2+: Conditional Access policy requiring phishing-resistant MFA for admins
resource "azuread_conditional_access_policy" "require_phishing_resistant_mfa" {
  count = var.profile_level >= 2 ? 1 : 0

  display_name = "HTH: Require phishing-resistant MFA for admins"
  state        = "enabled"

  conditions {
    users {
      included_roles = [
        # Global Administrator
        "62e90394-69f5-4237-9190-012177145e10",
        # Security Administrator
        "194ae4cb-b126-40b2-bd5b-6091b380977d",
        # Privileged Role Administrator
        "e8611ab8-c189-46e8-94e1-60213ab1f814",
      ]
      excluded_users = [for u in data.azuread_user.break_glass : u.object_id]
    }

    applications {
      included_applications = ["All"]
    }

    client_app_types = ["all"]
  }

  grant_controls {
    operator                          = "OR"
    authentication_strength_policy_id = azuread_authentication_strength_policy.phishing_resistant[0].id
  }
}

# HTH Guide Excerpt: end terraform
