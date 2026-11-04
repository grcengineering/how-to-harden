# HTH Pack Contract: v1
#   control: tailscale-1.2
#   guide: https://howtoharden.com/guides/tailscale/#12-govern-membership-roles-and-offboarding
#   profile: L1
#   mode: read-only
#   requires: official provider credentials(users:read), TAILSCALE_TAILNET, collect_inventory=true
# HTH Tailscale 1.2 — Govern Membership, Roles and Offboarding; NIST AC-2, AC-6; SOC 2 CC6.2
# Source: https://github.com/tailscale/terraform-provider-tailscale/blob/main/docs/data-sources/users.md (available; 2026-11-04)
# HTH Guide Excerpt: begin read-users
data "tailscale_users" "review" {
  count = var.collect_inventory ? 1 : 0
}

output "users_for_review" {
  value     = data.tailscale_users.review
  sensitive = true
}
# HTH Guide Excerpt: end read-users
