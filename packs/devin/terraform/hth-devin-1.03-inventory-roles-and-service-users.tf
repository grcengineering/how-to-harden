# HTH Pack Contract: v1
#   control: devin-1.3
#   guide: https://howtoharden.com/guides/devin/#13-minimize-roles-and-service-users
#   profile: L1
#   mode: read-only
#   requires: DEVIN_TOKEN(enterprise service user with View Account Membership)
# NIST 800-53 AC-6. Source schema verified 2026-10-29:
# https://github.com/CognitionAI/terraform-provider-devin/blob/v0.5.0/docs/data-sources/roles.md
# https://github.com/CognitionAI/terraform-provider-devin/blob/v0.5.0/docs/data-sources/service_users.md
# Copy providers.tf and this file only. Run terraform plan; no apply required.
# Protect state/plans: these data sources include names and identifiers.
# HTH Guide Excerpt: begin role-inventory
data "devin_roles" "hth_roles" {}
data "devin_service_users" "hth_service_users" {}
output "hth_identity_inventory_counts" {
  value = {
    enterprise_roles = length([
      for role in data.devin_roles.hth_roles.roles : role.role_id
      if role.role_type == "enterprise"
    ])
    org_roles     = length([for role in data.devin_roles.hth_roles.roles : role.role_id if role.role_type == "org"])
    service_users = length(data.devin_service_users.hth_service_users.service_users)
    enterprise_service_user_assignments = sum(concat([0], [
      for su in data.devin_service_users.hth_service_users.service_users : length([
        for assignment in su.role_assignments : assignment.role_id if assignment.org_id == null
      ])
    ]))
  }
}
# Role names/IDs alone do not expose permission definitions: inspect the Roles tab.
# HTH Guide Excerpt: end role-inventory
