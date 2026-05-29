# =============================================================================
# HTH Google Chat Control 3.3: Restrict & Allowlist Google Chat Apps
# Profile Level: L1 (Baseline)
# Frameworks: CIS 2.5, NIST AC-3/CM-7
# Source: https://howtoharden.com/guides/google-chat/#33-restrict--allowlist-google-chat-apps
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Google Chat app installation is governed by two Admin Console settings that
# the googleworkspace provider does NOT expose directly:
#
#   1. Apps > Google Workspace > Google Chat > Chat apps
#      - "Allow users to install Chat apps" (On/Off)
#      - "Allow users to add and use incoming webhooks" (On/Off)
#   2. Apps > Google Workspace Marketplace apps > Apps list >
#      Google Workspace Marketplace allowlist  ("Add app to allowlist")
#
# This file creates the governance infrastructure that supports an allowlist
# workflow: a group whose members review and approve Chat app requests.

# Group that owns the Chat app review/approval workflow.
resource "googleworkspace_group" "chat_app_approvers" {
  email       = "chat-app-approvers@${var.primary_domain}"
  name        = "Chat App Approvers"
  description = "HTH 3.3 -- Members review and approve Google Chat app + webhook requests before they are added to the Marketplace allowlist"
}

# OU for users permitted to add incoming webhooks (L2: restrict webhooks to a
# small, audited population rather than the whole organization).
resource "googleworkspace_org_unit" "chat_webhooks_allowed" {
  count = var.profile_level >= 2 ? 1 : 0

  name                 = "Chat Webhooks Allowed"
  description          = "HTH 3.3 L2 -- Only users in this OU may add incoming webhooks in Chat; disable webhooks for the parent OU"
  parent_org_unit_path = var.target_org_unit_path
}
# HTH Guide Excerpt: end terraform
