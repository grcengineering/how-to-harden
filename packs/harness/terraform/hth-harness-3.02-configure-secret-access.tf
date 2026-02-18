# =============================================================================
# HTH Harness Control 3.2: Configure Secret Access
# Profile Level: L2 (Hardened)
# Frameworks: CIS 3.11, NIST SC-12
# Source: https://howtoharden.com/guides/harness/#32-configure-secret-access
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Resource group scoped to secret management resources (L2+)
resource "harness_platform_resource_group" "secrets" {
  count = var.profile_level >= 2 ? 1 : 0

  identifier  = "hth_secret_resources"
  name        = var.secret_resource_group_name
  description = "Resource group limiting access to secret management resources (HTH Control 3.2)"
  account_id  = var.harness_account_id

  included_scopes {
    filter = "INCLUDING_CHILD_SCOPES"
  }

  resource_filter {
    include_all_resources = false

    resources {
      resource_type = "SECRET"
    }

    resources {
      resource_type = "CONNECTOR"
      attribute_filter {
        attribute_name   = "category"
        attribute_values = ["SECRET_MANAGER"]
      }
    }
  }
}

# Role restricting secret operations to approved personnel (L2+)
resource "harness_platform_roles" "secret_operator" {
  count = var.profile_level >= 2 ? 1 : 0

  identifier         = "hth_secret_operator"
  name               = var.secret_manager_role_name
  description        = "Role for managing secrets without broader platform access (HTH Control 3.2)"
  permissions        = [
    "core_secret_view",
    "core_secret_edit",
    "core_secret_delete",
    "core_connector_view"
  ]
  allowed_scope_levels = ["account", "organization", "project"]
}

# User group for secret management personnel (L2+)
resource "harness_platform_usergroup" "secret_managers" {
  count = var.profile_level >= 2 ? 1 : 0

  identifier  = "hth_secret_managers"
  name        = "Secret Managers"
  description = "User group with scoped access to secret management resources (HTH Control 3.2)"

  notification_configs {
    type              = "EMAIL"
    send_email_to_all = true
  }
}

# Bind secret operator role to the secret managers group (L2+)
resource "harness_platform_role_assignments" "secret_binding" {
  count = var.profile_level >= 2 ? 1 : 0

  identifier = "hth_secret_binding"

  resource_group_identifier = harness_platform_resource_group.secrets[0].id
  role_identifier           = harness_platform_roles.secret_operator[0].id
  principal {
    identifier = harness_platform_usergroup.secret_managers[0].id
    type       = "USER_GROUP"
  }
  disabled   = false
  managed    = false
}
# HTH Guide Excerpt: end terraform
