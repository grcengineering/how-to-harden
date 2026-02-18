# =============================================================================
# HTH Jamf Pro Control 2.4: Configure Software Updates
# Profile Level: L1 (Baseline)
# Frameworks: CIS 7.3, NIST SI-2
# Source: https://howtoharden.com/guides/jamf/#24-configure-software-updates
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Automatic software update configuration profile
resource "jamfpro_macos_configuration_profile_plist" "software_updates" {
  name                = "HTH Software Update Policy (L${var.profile_level})"
  description         = "Configure automatic software updates per HTH hardening guide"
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
          <string>com.apple.SoftwareUpdate</string>
          <key>PayloadVersion</key>
          <integer>1</integer>
          <key>PayloadIdentifier</key>
          <string>com.howtoharden.jamf.softwareupdate</string>
          <key>PayloadUUID</key>
          <string>A7B8C9D0-E1F2-3456-ABCD-567890123456</string>
          <key>PayloadDisplayName</key>
          <string>Software Update</string>
          <key>AutomaticCheckEnabled</key>
          <true/>
          <key>AutomaticDownload</key>
          <true/>
          <key>AutomaticallyInstallAppUpdates</key>
          <true/>
          <key>AutomaticallyInstallMacOSUpdates</key>
          <true/>
          <key>CriticalUpdateInstall</key>
          <true/>
          <key>ConfigDataInstall</key>
          <true/>
        </dict>
      </array>
      <key>PayloadDisplayName</key>
      <string>HTH Software Update Policy</string>
      <key>PayloadIdentifier</key>
      <string>com.howtoharden.jamf.softwareupdate.profile</string>
      <key>PayloadType</key>
      <string>Configuration</string>
      <key>PayloadUUID</key>
      <string>B8C9D0E1-F2A3-4567-BCDE-678901234567</string>
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

# L2: Software update deferral profile for controlled environments
resource "jamfpro_macos_configuration_profile_plist" "software_update_deferral" {
  count = var.profile_level >= 2 ? 1 : 0

  name                = "HTH Software Update Deferral (L${var.profile_level})"
  description         = "Defer OS updates for testing before deployment per HTH hardening guide"
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
          <string>com.apple.applicationaccess</string>
          <key>PayloadVersion</key>
          <integer>1</integer>
          <key>PayloadIdentifier</key>
          <string>com.howtoharden.jamf.updatedeferral</string>
          <key>PayloadUUID</key>
          <string>C9D0E1F2-A3B4-5678-CDEF-789012345678</string>
          <key>PayloadDisplayName</key>
          <string>Software Update Deferral</string>
          <key>enforcedSoftwareUpdateDelay</key>
          <integer>${var.software_update_deferral_days}</integer>
          <key>enforcedSoftwareUpdateMajorOSDeferredInstallDelay</key>
          <integer>${var.software_update_deferral_days}</integer>
          <key>enforcedSoftwareUpdateMinorOSDeferredInstallDelay</key>
          <integer>${var.security_update_deferral_days}</integer>
          <key>enforcedSoftwareUpdateNonOSDeferredInstallDelay</key>
          <integer>${var.security_update_deferral_days}</integer>
          <key>forceDelayedSoftwareUpdates</key>
          <true/>
          <key>forceDelayedMajorSoftwareUpdates</key>
          <true/>
        </dict>
      </array>
      <key>PayloadDisplayName</key>
      <string>HTH Software Update Deferral</string>
      <key>PayloadIdentifier</key>
      <string>com.howtoharden.jamf.updatedeferral.profile</string>
      <key>PayloadType</key>
      <string>Configuration</string>
      <key>PayloadUUID</key>
      <string>D0E1F2A3-B4C5-6789-DEFA-890123456789</string>
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

# Smart group to identify computers with outdated OS
resource "jamfpro_smart_computer_group" "os_not_current" {
  name = "HTH - OS Not Current"

  criteria {
    name        = "Operating System Version"
    search_type = "less than"
    value       = "15.0"
    priority    = 0
  }
}
# HTH Guide Excerpt: end terraform
