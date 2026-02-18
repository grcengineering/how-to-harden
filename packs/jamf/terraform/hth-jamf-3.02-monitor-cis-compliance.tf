# =============================================================================
# HTH Jamf Pro Control 3.2: Monitor CIS Compliance
# Profile Level: L2 (Hardened)
# Frameworks: CIS 4.1, NIST CA-7
# Source: https://howtoharden.com/guides/jamf/#32-monitor-cis-compliance
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Extension attribute to track CIS compliance status via script (L2+)
resource "jamfpro_computer_extension_attribute" "cis_compliance" {
  count = var.profile_level >= 2 ? 1 : 0

  name             = "HTH CIS Compliance Status"
  description      = "Reports CIS macOS Benchmark compliance status"
  data_type        = "String"
  enabled          = true
  input_type       = "SCRIPT"
  inventory_display_type = "EXTENSION_ATTRIBUTES"

  script_contents = var.cis_compliance_ea_script != "" ? var.cis_compliance_ea_script : <<-BASH
    #!/bin/bash
    # HTH CIS Compliance Check Extension Attribute
    # Reports: Compliant, Non-Compliant, or Partial

    ISSUES=0
    CHECKS=0

    # Check FileVault (CIS 2.1.1)
    CHECKS=$((CHECKS + 1))
    FV_STATUS=$(fdesetup status 2>/dev/null)
    if [[ "$FV_STATUS" != *"FileVault is On"* ]]; then
      ISSUES=$((ISSUES + 1))
    fi

    # Check Firewall (CIS 2.5.1)
    CHECKS=$((CHECKS + 1))
    FW_STATUS=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null)
    if [[ "$FW_STATUS" != *"enabled"* ]]; then
      ISSUES=$((ISSUES + 1))
    fi

    # Check Gatekeeper (CIS 2.1.2)
    CHECKS=$((CHECKS + 1))
    GK_STATUS=$(spctl --status 2>/dev/null)
    if [[ "$GK_STATUS" != *"assessments enabled"* ]]; then
      ISSUES=$((ISSUES + 1))
    fi

    # Check Remote Login disabled (CIS 3.3)
    CHECKS=$((CHECKS + 1))
    SSH_STATUS=$(systemsetup -getremotelogin 2>/dev/null)
    if [[ "$SSH_STATUS" == *"On"* ]]; then
      ISSUES=$((ISSUES + 1))
    fi

    # Report result
    if [ $ISSUES -eq 0 ]; then
      echo "<result>Compliant</result>"
    elif [ $ISSUES -lt $CHECKS ]; then
      echo "<result>Partial ($((CHECKS - ISSUES))/$CHECKS passed)</result>"
    else
      echo "<result>Non-Compliant</result>"
    fi
  BASH
}

# Smart group: CIS non-compliant computers (L2+)
resource "jamfpro_smart_computer_group" "cis_non_compliant" {
  count = var.profile_level >= 2 ? 1 : 0

  name = "HTH - CIS Non-Compliant"

  criteria {
    name        = "HTH CIS Compliance Status"
    search_type = "is not"
    value       = "Compliant"
    priority    = 0
  }
}

# Smart group: FileVault not enabled (L2+)
resource "jamfpro_smart_computer_group" "cis_filevault_missing" {
  count = var.profile_level >= 2 ? 1 : 0

  name = "HTH - CIS FileVault Not Enabled"

  criteria {
    name        = "FileVault 2 Status"
    search_type = "is not"
    value       = "Encrypted"
    priority    = 0
  }
}

# Smart group: OS not updated (L2+)
resource "jamfpro_smart_computer_group" "cis_os_outdated" {
  count = var.profile_level >= 2 ? 1 : 0

  name = "HTH - CIS OS Not Updated"

  criteria {
    name        = "Number of Available Updates"
    search_type = "more than"
    value       = "0"
    priority    = 0
  }
}
# HTH Guide Excerpt: end terraform
