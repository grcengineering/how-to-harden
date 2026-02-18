# =============================================================================
# HTH Splunk Control 2.1: Configure Role-Based Access Control
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6
# Source: https://howtoharden.com/guides/splunk/#21-configure-role-based-access-control
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Implement least-privilege RBAC using custom roles.
# Avoid assigning the built-in admin role directly to users.
# Map roles through SAML for centralized governance.

# Custom security analyst role with restricted capabilities
resource "splunk_authorization_roles" "security_analyst" {
  name = var.custom_analyst_role_name

  # Minimal capabilities for security analysts
  capabilities = [
    "search",
    "schedule_search",
    "list_inputs",
    "get_metadata",
    "get_typeahead",
    "rest_properties_get",
  ]

  # Index access restrictions
  imported_roles    = ["user"]
  default_app       = "search"
  search_indexes_allowed = var.analyst_allowed_indexes
  search_indexes_default = [var.analyst_default_index]
}

# Restricted power user role (L2+) with tighter capabilities
resource "splunk_authorization_roles" "restricted_power" {
  count = var.profile_level >= 2 ? 1 : 0

  name = "hth_restricted_power"

  capabilities = [
    "search",
    "schedule_search",
    "list_inputs",
    "get_metadata",
    "get_typeahead",
    "rest_properties_get",
    "rtsearch",
    "edit_search_schedule_priority",
  ]

  imported_roles    = ["user"]
  default_app       = "search"
  search_indexes_allowed = var.analyst_allowed_indexes
  search_indexes_default = [var.analyst_default_index]
}

# Read-only auditor role (L2+) for compliance reviewers
resource "splunk_authorization_roles" "auditor" {
  count = var.profile_level >= 2 ? 1 : 0

  name = "hth_auditor"

  capabilities = [
    "search",
    "get_metadata",
    "get_typeahead",
    "rest_properties_get",
    "list_settings",
  ]

  imported_roles    = ["user"]
  default_app       = "search"
  search_indexes_allowed = ["_audit", "_internal", var.audit_index_name]
  search_indexes_default = ["_audit"]
}
# HTH Guide Excerpt: end terraform
