# =============================================================================
# HTH Jamf Pro Control 3.1: Deploy CIS Benchmark Profiles
# Profile Level: L2 (Hardened)
# Frameworks: CIS 4.1, NIST CM-6
# Source: https://howtoharden.com/guides/jamf/#31-deploy-cis-benchmark-profiles
# =============================================================================

# HTH Guide Excerpt: begin terraform
# CIS 2.1.2 - Gatekeeper enforcement profile (L2+)
resource "jamfpro_macos_configuration_profile_plist" "cis_gatekeeper" {
  count = var.profile_level >= 2 ? 1 : 0

  name                = "HTH CIS - Gatekeeper Enforcement"
  description         = "CIS macOS Benchmark 2.1.2: Enable Gatekeeper"
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
          <string>com.apple.systempolicy.control</string>
          <key>PayloadVersion</key>
          <integer>1</integer>
          <key>PayloadIdentifier</key>
          <string>com.howtoharden.jamf.cis.gatekeeper</string>
          <key>PayloadUUID</key>
          <string>E1F2A3B4-C5D6-7890-EFAB-901234567890</string>
          <key>PayloadDisplayName</key>
          <string>Gatekeeper</string>
          <key>AllowIdentifiedDevelopers</key>
          <${var.cis_gatekeeper_enabled ? "true" : "false"}/>
          <key>EnableAssessment</key>
          <true/>
        </dict>
      </array>
      <key>PayloadDisplayName</key>
      <string>HTH CIS Gatekeeper</string>
      <key>PayloadIdentifier</key>
      <string>com.howtoharden.jamf.cis.gatekeeper.profile</string>
      <key>PayloadType</key>
      <string>Configuration</string>
      <key>PayloadUUID</key>
      <string>F2A3B4C5-D6E7-8901-FABC-012345678901</string>
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

# CIS 2.3.1 - Screen saver idle time profile (L2+)
resource "jamfpro_macos_configuration_profile_plist" "cis_screensaver" {
  count = var.profile_level >= 2 ? 1 : 0

  name                = "HTH CIS - Screen Saver Idle Time"
  description         = "CIS macOS Benchmark 2.3.1: Set screen saver idle time"
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
          <string>com.apple.screensaver</string>
          <key>PayloadVersion</key>
          <integer>1</integer>
          <key>PayloadIdentifier</key>
          <string>com.howtoharden.jamf.cis.screensaver</string>
          <key>PayloadUUID</key>
          <string>A3B4C5D6-E7F8-9012-ABCD-123456789012</string>
          <key>PayloadDisplayName</key>
          <string>Screen Saver</string>
          <key>idleTime</key>
          <integer>${var.cis_screen_saver_idle_time}</integer>
          <key>askForPassword</key>
          <true/>
          <key>askForPasswordDelay</key>
          <integer>0</integer>
        </dict>
      </array>
      <key>PayloadDisplayName</key>
      <string>HTH CIS Screen Saver</string>
      <key>PayloadIdentifier</key>
      <string>com.howtoharden.jamf.cis.screensaver.profile</string>
      <key>PayloadType</key>
      <string>Configuration</string>
      <key>PayloadUUID</key>
      <string>B4C5D6E7-F8A9-0123-BCDE-234567890123</string>
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

# CIS 3.3 - Disable Remote Login (SSH) profile (L2+)
resource "jamfpro_macos_configuration_profile_plist" "cis_disable_remote_login" {
  count = var.profile_level >= 2 && var.cis_disable_remote_login ? 1 : 0

  name                = "HTH CIS - Disable Remote Login"
  description         = "CIS macOS Benchmark 3.3: Disable Remote Login (SSH)"
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
          <string>com.apple.MCX</string>
          <key>PayloadVersion</key>
          <integer>1</integer>
          <key>PayloadIdentifier</key>
          <string>com.howtoharden.jamf.cis.remotelogin</string>
          <key>PayloadUUID</key>
          <string>C5D6E7F8-A9B0-1234-CDEF-345678901234</string>
          <key>PayloadDisplayName</key>
          <string>Disable Remote Login</string>
          <key>com.apple.access_ssh</key>
          <array/>
        </dict>
      </array>
      <key>PayloadDisplayName</key>
      <string>HTH CIS Disable Remote Login</string>
      <key>PayloadIdentifier</key>
      <string>com.howtoharden.jamf.cis.remotelogin.profile</string>
      <key>PayloadType</key>
      <string>Configuration</string>
      <key>PayloadUUID</key>
      <string>D6E7F8A9-B0C1-2345-DEFA-456789012345</string>
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
