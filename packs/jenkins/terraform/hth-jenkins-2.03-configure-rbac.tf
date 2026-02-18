# =============================================================================
# HTH Jenkins Control 2.3: Configure Role-Based Access Control
# Profile Level: L2 (Hardened)
# Frameworks: CIS 5.4, NIST AC-6(1)
# Source: https://howtoharden.com/guides/jenkins/#23-configure-role-based-access-control
#
# NOTE: The Role-Based Authorization Strategy Plugin is not directly supported
# by the Terraform provider. This file generates JCasC YAML for RBAC
# configuration. Requires the Role-based Authorization Strategy Plugin.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# JCasC configuration for role-based authorization strategy (L2+)
resource "local_file" "rbac_configuration" {
  count = var.profile_level >= 2 && var.enable_rbac ? 1 : 0

  filename = "${path.module}/generated/casc-rbac.yaml"
  content  = yamlencode({
    jenkins = {
      authorizationStrategy = {
        roleBased = {
          roles = {
            global = [
              {
                name        = "admin"
                description = "Full administrative access"
                permissions = [
                  "Overall/Administer",
                ]
                entries = [
                  for user in var.admin_users : { user = user }
                ]
              },
              {
                name        = "developer"
                description = "Build and read permissions for all jobs"
                permissions = [
                  "Overall/Read",
                  "Job/Build",
                  "Job/Read",
                  "Job/Workspace",
                  "Run/Replay",
                  "Run/Update",
                ]
                entries = [
                  for user in var.developer_users : { user = user }
                ]
              },
              {
                name        = "viewer"
                description = "Read-only access to jobs and builds"
                permissions = [
                  "Overall/Read",
                  "Job/Read",
                ]
                entries = [
                  for user in var.viewer_users : { user = user }
                ]
              },
            ]
            items = [
              for role in var.rbac_item_roles : {
                name        = role.name
                description = role.description
                pattern     = role.pattern
                permissions = role.permissions
                entries     = [for user in role.users : { user = user }]
              }
            ]
          }
        }
      }
    }
  })

  file_permission = "0644"
}
# HTH Guide Excerpt: end terraform
