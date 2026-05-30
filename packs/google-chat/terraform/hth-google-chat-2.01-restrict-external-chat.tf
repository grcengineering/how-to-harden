# =============================================================================
# HTH Google Chat Control 4.3: Restrict External Google Chat & Spaces
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.3, NIST AC-3
# SCuBA: GWS.CHAT.4.1v1 (external chat restricted to allowlisted domains)
# Source: https://howtoharden.com/guides/google-chat/#43-restrict-external-google-chat--spaces
# =============================================================================

# HTH Guide Excerpt: begin terraform
# External Google Chat is governed by Admin Console settings the googleworkspace
# provider does NOT expose directly:
#
#   Apps > Google Workspace > Google Chat > External chat settings
#     - "Allow users to send messages outside your organization" (On/Off)
#     - "Only allow this for allowlisted domains"
#     - "Auto-accept chat invites from familiar contacts"  (disable for L2+)
#   Apps > Google Workspace > Google Chat > External spaces
#     - "Allow users to create & join spaces with people outside their organization"
#     - "Only allow users to add people from allowlisted domains"
#
# The allowlist itself is the SHARED Workspace trusted-domains allowlist
# (Account > Domains > Allowlisted domains) -- the same allowlist used by Drive,
# Sites, Classroom, Chat, and Looker Studio.
#
# This file builds the supporting OU/group structure so external-chat access is
# an explicit, auditable exception rather than an org-wide default.

# Default OU: members are internal-only (configure "Chat externally = Off" here).
resource "googleworkspace_org_unit" "chat_internal_only" {
  name                 = "Chat Internal Only"
  description          = "HTH 4.3 -- External Chat and external spaces are OFF for this OU (organization default)"
  parent_org_unit_path = var.target_org_unit_path
}

# Exception OU: members may chat externally, but ONLY with allowlisted domains.
resource "googleworkspace_org_unit" "chat_external_allowlisted" {
  name                 = "Chat External Allowlisted"
  description          = "HTH 4.3 -- External Chat = On with 'Only allow this for allowlisted domains' for this OU"
  parent_org_unit_path = var.target_org_unit_path
}

# Group that approves which OUs/users receive the external-chat exception.
resource "googleworkspace_group" "chat_external_approvers" {
  email       = "chat-external-approvers@${var.primary_domain}"
  name        = "Chat External Approvers"
  description = "HTH 4.3 -- Members approve external Chat exceptions and curate the shared allowlisted-domains list"
}
# HTH Guide Excerpt: end terraform
