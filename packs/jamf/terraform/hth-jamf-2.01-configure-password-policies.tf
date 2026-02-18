# =============================================================================
# HTH Jamf Pro Control 2.1: Configure Password Policies
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.2, NIST IA-5
# Source: https://howtoharden.com/guides/jamf/#21-configure-password-policies
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Password policy configuration profile for managed macOS devices
resource "jamfpro_macos_configuration_profile_plist" "password_policy" {
  name                = "HTH Password Policy (L${var.profile_level})"
  description         = "Device password policy per HTH hardening guide - Profile Level ${var.profile_level}"
  distribution_method = "Install Automatically"
  user_removable      = false
  level               = "System"
  redeploy_on_update  = "All"

  payloads = <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>PayloadContent</key>
      <array>
        <dict>
          <key>PayloadType</key>
          <string>com.apple.mobiledevice.passwordpolicy</string>
          <key>PayloadVersion</key>
          <integer>1</integer>
          <key>PayloadIdentifier</key>
          <string>com.howtoharden.jamf.password</string>
          <key>PayloadUUID</key>
          <string>A1B2C3D4-E5F6-7890-ABCD-EF1234567890</string>
          <key>PayloadDisplayName</key>
          <string>Password Policy</string>
          <key>minLength</key>
          <integer>${var.password_min_length}</integer>
          <key>requireAlphanumeric</key>
          <true/>
          <key>minComplexChars</key>
          <integer>1</integer>
          <key>maxPINAgeInDays</key>
          <integer>${var.password_max_age_days}</integer>
          <key>pinHistory</key>
          <integer>${var.password_history_count}</integer>
          <key>maxInactivity</key>
          <integer>${var.auto_lock_minutes}</integer>
          <key>maxFailedAttempts</key>
          <integer>10</integer>
        </dict>
      </array>
      <key>PayloadDisplayName</key>
      <string>HTH Password Policy</string>
      <key>PayloadIdentifier</key>
      <string>com.howtoharden.jamf.password.profile</string>
      <key>PayloadType</key>
      <string>Configuration</string>
      <key>PayloadUUID</key>
      <string>B2C3D4E5-F6A7-8901-BCDE-F12345678901</string>
      <key>PayloadVersion</key>
      <integer>1</integer>
    </dict>
    </plist>
  XML

  scope {
    all_computers      = var.scope_all_computers
    computer_group_ids = var.scope_all_computers ? [] : toset(var.scope_computer_group_ids)
  }
}
# HTH Guide Excerpt: end terraform
