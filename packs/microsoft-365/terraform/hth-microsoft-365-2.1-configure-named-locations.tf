# =============================================================================
# HTH Microsoft 365 Control 2.1: Configure Trusted Locations and Named Locations
# Profile Level: L2 (Hardened)
# Source: https://howtoharden.com/guides/microsoft-365/#21-configure-trusted-locations-and-named-locations
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Named location: Trusted corporate IP ranges
resource "azuread_named_location" "corporate_network" {
  count = var.profile_level >= 2 && length(var.trusted_ip_ranges) > 0 ? 1 : 0

  display_name = "HTH: Corporate Network"

  ip {
    ip_ranges = var.trusted_ip_ranges
    trusted   = true
  }
}

# Named location: Blocked countries
resource "azuread_named_location" "blocked_countries" {
  count = var.profile_level >= 2 && length(var.blocked_country_codes) > 0 ? 1 : 0

  display_name = "HTH: Blocked Countries"

  country {
    countries_and_regions                 = var.blocked_country_codes
    include_unknown_countries_and_regions = true
  }
}

# Conditional Access policy: Block sign-ins from high-risk countries
resource "azuread_conditional_access_policy" "block_countries" {
  count = var.profile_level >= 2 && length(var.blocked_country_codes) > 0 ? 1 : 0

  display_name = "HTH: Block sign-ins from restricted countries"
  state        = "enabled"

  conditions {
    users {
      included_users = ["All"]
      excluded_users = [for u in data.azuread_user.break_glass : u.object_id]
    }

    applications {
      included_applications = ["All"]
    }

    locations {
      included_locations = [azuread_named_location.blocked_countries[0].id]
    }

    client_app_types = ["all"]
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}

# L3: Require MFA from non-trusted locations (reduce MFA fatigue for trusted)
resource "azuread_conditional_access_policy" "mfa_untrusted_locations" {
  count = var.profile_level >= 3 && length(var.trusted_ip_ranges) > 0 ? 1 : 0

  display_name = "HTH: Require MFA from non-trusted locations"
  state        = "enabled"

  conditions {
    users {
      included_users = ["All"]
      excluded_users = [for u in data.azuread_user.break_glass : u.object_id]
    }

    applications {
      included_applications = ["All"]
    }

    locations {
      included_locations = ["All"]
      excluded_locations = [azuread_named_location.corporate_network[0].id]
    }

    client_app_types = ["all"]
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }
}

# HTH Guide Excerpt: end terraform
