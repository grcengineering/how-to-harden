# =============================================================================
# HTH Jamf Pro Control 2.2: Configure FileVault Encryption
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.11, NIST SC-28
# Source: https://howtoharden.com/guides/jamf/#22-configure-filevault-encryption
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Disk encryption configuration for FileVault escrow
resource "jamfpro_disk_encryption_configuration" "filevault" {
  name                   = "HTH FileVault Encryption"
  key_type               = "Individual"
  file_vault_enabled_users = "Current or Next User"
}

# FileVault enforcement configuration profile
resource "jamfpro_macos_configuration_profile_plist" "filevault" {
  name                = "HTH FileVault Enforcement"
  description         = "Enforce FileVault full disk encryption per HTH hardening guide"
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
          <string>com.apple.MCX.FileVault2</string>
          <key>PayloadVersion</key>
          <integer>1</integer>
          <key>PayloadIdentifier</key>
          <string>com.howtoharden.jamf.filevault</string>
          <key>PayloadUUID</key>
          <string>C3D4E5F6-A7B8-9012-CDEF-123456789012</string>
          <key>PayloadDisplayName</key>
          <string>FileVault 2</string>
          <key>Enable</key>
          <string>On</string>
          <key>Defer</key>
          <true/>
          <key>ShowRecoveryKey</key>
          <${var.filevault_escrow_enabled ? "false" : "true"}/>
          <key>UseRecoveryKey</key>
          <true/>
          <key>UseKeychain</key>
          <false/>
          <key>DeferForceAtUserLoginMaxBypassAttempts</key>
          <integer>3</integer>
          <key>DeferDontAskAtUserLogout</key>
          <false/>
        </dict>
      </array>
      <key>PayloadDisplayName</key>
      <string>HTH FileVault Enforcement</string>
      <key>PayloadIdentifier</key>
      <string>com.howtoharden.jamf.filevault.profile</string>
      <key>PayloadType</key>
      <string>Configuration</string>
      <key>PayloadUUID</key>
      <string>D4E5F6A7-B8C9-0123-DEFA-234567890123</string>
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

# Smart group to identify computers without FileVault enabled
resource "jamfpro_smart_computer_group" "filevault_not_enabled" {
  name = "HTH - FileVault Not Enabled"

  criteria {
    name        = "FileVault 2 Status"
    search_type = "is not"
    value       = "Encrypted"
    priority    = 0
  }
}
# HTH Guide Excerpt: end terraform
