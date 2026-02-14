# =============================================================================
# HTH Okta Control 5.4: Behavior Detection
# Profile Level: L2 (Hardened)
# Frameworks: NIST SI-4, AC-7
# Source: https://howtoharden.com/guides/okta/#54-configure-behavior-detection-rules
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
