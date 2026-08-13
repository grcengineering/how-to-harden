# =============================================================================
# HTH Google Chat Control 1.1: Restrict & Allowlist Google Chat Apps
# Profile Level: L1 (Crawl)
# Frameworks: CIS 2.5, NIST AC-3/CM-7
# Source: https://howtoharden.com/guides/google-chat/#11-restrict--allowlist-google-chat-apps
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
  description = "HTH 1.1 -- Members review and approve Google Chat app + webhook requests before they are added to the Marketplace allowlist"
}

# OU for users permitted to add incoming webhooks (L2: restrict webhooks to a
# small, audited population rather than the whole organization).
resource "googleworkspace_org_unit" "chat_webhooks_allowed" {
  count = var.profile_level >= 2 ? 1 : 0

  name                 = "Chat Webhooks Allowed"
  description          = "HTH 1.1 L2 -- Only users in this OU may add incoming webhooks in Chat; disable webhooks for the parent OU"
  parent_org_unit_path = var.target_org_unit_path
}
# HTH Guide Excerpt: end terraform
