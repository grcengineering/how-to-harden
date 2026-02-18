# =============================================================================
# HTH Harness Control 4.2: Configure Audit Trail
# Profile Level: L1 (Baseline)
# Frameworks: CIS 8.2, NIST AU-2
# Source: https://howtoharden.com/guides/harness/#42-configure-audit-trail
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Note: Harness audit trail is enabled by default for all accounts.
# This configuration creates a service account and role for audit access,
# and optionally configures streaming destinations for log retention.

# Dedicated audit viewer role for compliance and security teams
resource "harness_platform_roles" "audit_viewer" {
  identifier         = "hth_audit_viewer"
  name               = "Audit Trail Viewer"
  description        = "Read-only role for accessing audit trail data (HTH Control 4.2)"
  permissions        = [
    "core_audit_view"
  ]
  allowed_scope_levels = ["account"]
}

# User group for audit/compliance personnel
resource "harness_platform_usergroup" "auditors" {
  identifier  = "hth_auditors"
  name        = "Audit & Compliance Team"
  description = "User group with read-only access to audit trail (HTH Control 4.2)"

  notification_configs {
    type              = "EMAIL"
    send_email_to_all = true
  }
}

# Resource group scoped to audit resources
resource "harness_platform_resource_group" "audit_resources" {
  identifier  = "hth_audit_resources"
  name        = "Audit Trail Resources"
  description = "Resource group for audit trail access (HTH Control 4.2)"
  account_id  = var.harness_account_id

  included_scopes {
    filter = "INCLUDING_CHILD_SCOPES"
  }

  resource_filter {
    include_all_resources = false

    resources {
      resource_type = "AUDIT"
    }
  }
}

# Bind audit viewer role to auditors group
resource "harness_platform_role_assignments" "audit_binding" {
  identifier = "hth_audit_binding"

  resource_group_identifier = harness_platform_resource_group.audit_resources.id
  role_identifier           = harness_platform_roles.audit_viewer.id
  principal {
    identifier = harness_platform_usergroup.auditors.id
    type       = "USER_GROUP"
  }
  disabled   = false
  managed    = false
}

# Service account for automated audit log retrieval
resource "harness_platform_service_account" "audit_exporter" {
  count = var.profile_level >= 2 ? 1 : 0

  identifier  = "hth_audit_exporter"
  name        = "Audit Log Exporter"
  description = "Service account for automated audit log retrieval and streaming (HTH Control 4.2)"
  email       = "audit-exporter@harness.local"
  account_id  = var.harness_account_id
}

# API key for the audit exporter service account (L2+)
resource "harness_platform_apikey" "audit_exporter_key" {
  count = var.profile_level >= 2 ? 1 : 0

  identifier  = "hth_audit_exporter_key"
  name        = "Audit Exporter API Key"
  apikey_type = "SERVICE_ACCOUNT"
  parent_id   = harness_platform_service_account.audit_exporter[0].id
  account_id  = var.harness_account_id
}

# Token for the audit exporter API key (L2+)
resource "harness_platform_token" "audit_exporter_token" {
  count = var.profile_level >= 2 ? 1 : 0

  identifier  = "hth_audit_exporter_token"
  name        = "Audit Exporter Token"
  apikey_id   = harness_platform_apikey.audit_exporter_key[0].id
  apikey_type = "SERVICE_ACCOUNT"
  parent_id   = harness_platform_service_account.audit_exporter[0].id
  account_id  = var.harness_account_id
}
# HTH Guide Excerpt: end terraform
