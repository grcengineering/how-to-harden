# HTH Pack Contract: v1
#   control: devin-1.2
#   guide: https://howtoharden.com/guides/devin/#12-automate-deprovisioning-with-scim
#   profile: L2
#   mode: read-only
#   requires: DEVIN_TOKEN(enterprise service user with View Account Membership)
# NIST 800-53 AC-2. Verification inventory, NOT a SCIM configuration or completeness assertion.
# Source: https://github.com/CognitionAI/terraform-provider-devin/blob/v0.5.0/docs/data-sources/users.md
# Source: https://github.com/CognitionAI/terraform-provider-devin/blob/v0.5.0/docs/data-sources/idp_groups.md
# Requires providers.tf in an otherwise empty directory. Run terraform plan, not apply.
# Data sources contain identities in state/plan even though outputs are aggregate only.
# HTH Guide Excerpt: begin provisioning-inventory
data "devin_users" "hth_members" {}
data "devin_idp_groups" "hth_groups" {}
output "hth_provisioning_inventory" {
  value = {
    direct_members = length(data.devin_users.hth_members.users)
    idp_groups     = length(data.devin_idp_groups.hth_groups.idp_groups)
  }
}
# Compare direct members AND IdP-derived members with the IdP in the console.
# Registered group names and direct memberships do not prove SCIM is enabled,
# JIT is disabled, or that the last deprovisioning succeeded.
# HTH Guide Excerpt: end provisioning-inventory
