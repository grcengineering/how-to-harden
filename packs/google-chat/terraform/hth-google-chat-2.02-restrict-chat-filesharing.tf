# =============================================================================
# HTH Google Chat Control 4.4: Restrict Google Chat File Sharing
# Profile Level: L2 (Hardened)
# Frameworks: CIS 3.3, NIST AC-3
# SCuBA: GWS.CHAT.2.1v1 (external file sharing SHALL be disabled)
# Source: https://howtoharden.com/guides/google-chat/#44-restrict-google-chat-file-sharing
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Chat file-sharing limits are configured in:
#   Apps > Google Workspace > Google Chat > Chat file sharing
#     - "External filesharing" dropdown: Allow all files | Images only | No files
#     - "Internal filesharing" dropdown: Allow all files | Images only | No files
#
# The googleworkspace provider does NOT expose these dropdowns, so enforcement is
# ClickOps (SCuBA GWS.CHAT.2.1v1 requires External filesharing = "No files").
# This file creates an OU where the strictest file-sharing policy is applied,
# mirroring the Drive external-sharing pattern in control 4.1.

# OU for highly sensitive teams: configure "External filesharing = No files" and
# "Internal filesharing = Images only" here for the tightest Chat data boundary.
resource "googleworkspace_org_unit" "chat_no_file_sharing" {
  name                 = "Chat No External File Sharing"
  description          = "HTH 4.4 -- External Chat file sharing set to 'No files' for this OU (SCuBA GWS.CHAT.2.1v1)"
  parent_org_unit_path = var.target_org_unit_path
}
# HTH Guide Excerpt: end terraform
