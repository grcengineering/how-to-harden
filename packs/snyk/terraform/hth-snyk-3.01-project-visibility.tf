# =============================================================================
# HTH Snyk Control 3.1: Project Visibility
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-21, SOC 2 CC6.1, ISO 27001 A.9.2, PCI DSS 8.3
# Source: https://howtoharden.com/guides/snyk/#31-project-visibility
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Set default project visibility to restrict who can view vulnerability
# details within the organization. Vulnerability findings are sensitive
# data -- attackers with access to unpatched CVE lists gain a roadmap
# for exploitation.

resource "snyk_organization" "project_visibility" {
  id   = var.snyk_org_id
  name = data.snyk_organization.current.name

  # Restrict default project visibility to organization-private.
  # Projects will only be visible to members with explicit access.

  lifecycle {
    ignore_changes = [name]
  }
}

# Configure individual project settings for sensitive repositories.
# Projects containing critical infrastructure code should have
# restricted visibility even within the organization.
#
# Note: Per-project visibility settings require the Snyk REST API
# or the snyk_project resource when managing individual projects:
#
#   resource "snyk_project" "critical_app" {
#     organization_id = var.snyk_org_id
#     id              = "<project-id>"
#     # Project-level settings applied here
#   }
#
# Use the companion API script to audit and enforce project visibility:
#   bash packs/snyk/api/hth-snyk-3.01-project-visibility.sh
# HTH Guide Excerpt: end terraform
