# HTH Pack Contract: v1
#   control: tailscale-3.3
#   guide: https://howtoharden.com/guides/tailscale/#33-review-subnet-and-exit-node-routes
#   profile: L2
#   mode: mutating
#   requires: official provider credentials(devices:routes), TAILSCALE_TAILNET, reviewed_subnet_routes
# HTH Tailscale 3.3 — Review Subnet and Exit-Node Routes; NIST SC-7, AC-4; SOC 2 CC6.6
# Source: https://github.com/tailscale/terraform-provider-tailscale/blob/main/docs/resources/device_subnet_routes.md (available; 2026-11-04)
# Complete enabled-route set per device; does not advertise routes or grant access.
# HTH Guide Excerpt: begin reviewed-subnet-routes
variable "reviewed_subnet_routes" {
  description = "Stable node ID to complete approved CIDR set. Empty means no changes. Default routes are deliberately excluded."
  type        = map(set(string))
  default     = {}
  validation {
    condition = alltrue(flatten([
      for id, routes in var.reviewed_subnet_routes : [
        can(regex("^[A-Za-z0-9]+$", id)),
        alltrue([for route in routes : can(cidrhost(route, 0)) && !can(regex("/0$", route))])
      ]
    ]))
    error_message = "Use stable node IDs and valid subnet CIDRs; this pack does not approve exit-node default routes."
  }
}

resource "tailscale_device_subnet_routes" "reviewed" {
  for_each  = var.reviewed_subnet_routes
  device_id = each.key
  routes    = each.value
  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = var.hth_profile_level >= 2
      error_message = "Route management requires L2 and an independently verified recovery path."
    }
  }
}
# HTH Guide Excerpt: end reviewed-subnet-routes
