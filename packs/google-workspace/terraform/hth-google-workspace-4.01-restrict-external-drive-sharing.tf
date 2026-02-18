# =============================================================================
# HTH Google Workspace Control 4.1: Configure External Drive Sharing Restrictions
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.3, NIST AC-3/AC-22, CIS Google Workspace 3.1
# Source: https://howtoharden.com/guides/google-workspace/#41-configure-external-drive-sharing-restrictions
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Restrict external sharing of Google Drive files.  The googleworkspace
# provider does not directly manage Drive sharing settings (those are
# configured in Admin Console > Apps > Drive and Docs > Sharing settings).
#
# This control creates the organizational infrastructure to support
# sharing restrictions:
#
# 1. An OU for teams that need external collaboration (override at OU level)
# 2. Groups for managing allowed external domains
# 3. Audit tracking for files shared externally

# OU for teams that require external Drive sharing (e.g., Sales, Partnerships)
# These teams get slightly relaxed sharing settings while the rest of the
# organization defaults to internal-only.
resource "googleworkspace_org_unit" "external_sharing_allowed" {
  name                 = "External Sharing Allowed"
  description          = "HTH 4.1 -- Users in this OU may share Drive files with approved external domains"
  parent_org_unit_path = var.target_org_unit_path
}

# OU for highly sensitive teams with no external sharing whatsoever
resource "googleworkspace_org_unit" "no_external_sharing" {
  count = var.profile_level >= 2 ? 1 : 0

  name                 = "No External Sharing"
  description          = "HTH 4.1 L2 -- Users in this OU cannot share Drive files externally under any circumstances"
  parent_org_unit_path = var.target_org_unit_path
}

# Group for tracking external sharing exceptions and approvals
resource "googleworkspace_group" "external_sharing_approvers" {
  email       = "external-sharing-approvers@${var.primary_domain}"
  name        = "External Sharing Approvers"
  description = "HTH 4.1 -- Members can approve external Drive sharing requests"
}

# Group for collecting external sharing audit notifications
resource "googleworkspace_group" "external_sharing_audit" {
  email       = "external-sharing-audit@${var.primary_domain}"
  name        = "External Sharing Audit"
  description = "HTH 4.1 -- Receives notifications about external file sharing activity"
}
# HTH Guide Excerpt: end terraform
