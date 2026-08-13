# =============================================================================
# HTH Google Chat Control 2.2: Restrict Google Chat File Sharing
# Profile Level: L2 (Walk)
# Frameworks: CIS 3.3, NIST AC-3
# SCuBA: GWS.CHAT.2.1v1 (external file sharing SHALL be disabled)
# Source: https://howtoharden.com/guides/google-chat/#22-restrict-google-chat-file-sharing
# =============================================================================

# HTH Guide Excerpt: begin terraform
#
# ⚠ PROVIDER STATUS (verified 2026-08-12): the hashicorp/googleworkspace provider
#   was ARCHIVED by HashiCorp on 2025-06-30 and is read-only — "New releases will
#   not be published." Existing binaries remain downloadable from the registry, so
#   this configuration still applies, but it receives no fixes or API updates.
#   Pin the version you validated, and treat a fork or a migration to API-based
#   automation as a planned action rather than an emergency one.
#   https://github.com/hashicorp/terraform-provider-googleworkspace
#
#   The provider has never offered ANY Chat-specific resource (its full resource
#   set is: chrome_policy, domain, domain_alias, gmail_send_as_alias, group,
#   group_member, group_members, group_settings, org_unit, role, role_assignment,
#   schema, user), which is why the blocks below build supporting structure only.
#
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
  description          = "HTH 2.2 -- External Chat file sharing set to 'No files' for this OU (SCuBA GWS.CHAT.2.1v1)"
  parent_org_unit_path = var.target_org_unit_path
}
# HTH Guide Excerpt: end terraform
