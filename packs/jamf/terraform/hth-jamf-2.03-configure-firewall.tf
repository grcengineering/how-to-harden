# =============================================================================
# HTH Jamf Pro Control 2.3: Configure Firewall
# Profile Level: L1 (Baseline)
# Frameworks: CIS 4.4, NIST SC-7
# Source: https://howtoharden.com/guides/jamf/#23-configure-firewall
# =============================================================================

# HTH Guide Excerpt: begin terraform
# macOS firewall configuration profile
resource "jamfpro_macos_configuration_profile_plist" "firewall" {
  name                = "HTH Firewall Policy (L${var.profile_level})"
  description         = "Enable and configure macOS firewall per HTH hardening guide"
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
          <string>com.apple.security.firewall</string>
          <key>PayloadVersion</key>
          <integer>1</integer>
          <key>PayloadIdentifier</key>
          <string>com.howtoharden.jamf.firewall</string>
          <key>PayloadUUID</key>
          <string>E5F6A7B8-C9D0-1234-EFAB-345678901234</string>
          <key>PayloadDisplayName</key>
          <string>Firewall</string>
          <key>EnableFirewall</key>
          <true/>
          <key>BlockAllIncoming</key>
          <${var.firewall_block_all_incoming || var.profile_level >= 3 ? "true" : "false"}/>
          <key>EnableStealthMode</key>
          <${var.firewall_stealth_mode ? "true" : "false"}/>
          <key>AllowSigned</key>
          <${var.profile_level >= 3 ? "false" : "true"}/>
          <key>AllowSignedApp</key>
          <${var.profile_level >= 3 ? "false" : "true"}/>
        </dict>
      </array>
      <key>PayloadDisplayName</key>
      <string>HTH Firewall Policy</string>
      <key>PayloadIdentifier</key>
      <string>com.howtoharden.jamf.firewall.profile</string>
      <key>PayloadType</key>
      <string>Configuration</string>
      <key>PayloadUUID</key>
      <string>F6A7B8C9-D0E1-2345-FABC-456789012345</string>
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

# Smart group to identify computers with firewall disabled
resource "jamfpro_smart_computer_group" "firewall_disabled" {
  name = "HTH - Firewall Disabled"

  criteria {
    name        = "Firewall Status"
    search_type = "is not"
    value       = "On"
    priority    = 0
  }
}
# HTH Guide Excerpt: end terraform
