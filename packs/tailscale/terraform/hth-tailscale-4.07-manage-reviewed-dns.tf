# HTH Pack Contract: v1
#   control: tailscale-4.7
#   guide: https://howtoharden.com/guides/tailscale/#47-govern-dns-resolvers-and-certificate-name-disclosure
#   profile: L2
#   mode: mutating
#   requires: Terraform 1.7+, tailscale/tailscale 0.29.3, existing imported DNS configuration, protected state
# HTH Tailscale 4.7 — Govern DNS Resolvers and Certificate Name Disclosure; NIST SC-20, SC-21; SOC 2 CC6.6
# Source: https://github.com/tailscale/terraform-provider-tailscale/blob/v0.29.3/docs/resources/dns_configuration.md (available; 2026-11-05)
# Owns ALL DNS configuration. Do not combine with the provider's individual DNS
# resources. Import existing state and inspect the full plan before management.

# HTH Guide Excerpt: begin manage-reviewed-dns
variable "reviewed_dns_configuration" {
  type = object({
    nameservers = list(object({
      address            = string
      use_with_exit_node = bool
    }))
    split_dns = map(list(object({
      address            = string
      use_with_exit_node = bool
    })))
    search_paths       = list(string)
    override_local_dns = bool
    magic_dns          = bool
  })
  default  = null
  nullable = true
  validation {
    condition = var.reviewed_dns_configuration == null ? true : alltrue([
      for server in concat(var.reviewed_dns_configuration.nameservers, flatten(values(var.reviewed_dns_configuration.split_dns))) :
      can(cidrhost("${server.address}/32", 0)) || can(cidrhost("${server.address}/128", 0))
    ])
    error_message = "Each reviewed resolver must be an IPv4 or IPv6 address."
  }
  validation {
    condition = var.reviewed_dns_configuration == null ? true : alltrue([
      for domain in concat(keys(var.reviewed_dns_configuration.split_dns), var.reviewed_dns_configuration.search_paths) :
      length(trimspace(domain)) > 0 && can(regex("^[A-Za-z0-9][A-Za-z0-9.-]*$", domain))
    ])
    error_message = "Supply explicit nonempty DNS domains without whitespace or URL syntax."
  }
}

variable "dns_clients_support_exit_node_resolvers" {
  type        = bool
  default     = false
  description = "Acknowledge verified Tailscale 1.88.1+ client support before using use_with_exit_node. This is not an API check."
}

resource "tailscale_dns_configuration" "reviewed" {
  for_each = var.reviewed_dns_configuration == null ? {} : { dns = var.reviewed_dns_configuration }

  magic_dns          = each.value.magic_dns
  override_local_dns = each.value.override_local_dns
  search_paths       = each.value.search_paths
  dynamic "nameservers" {
    for_each = each.value.nameservers
    content {
      address            = nameservers.value.address
      use_with_exit_node = nameservers.value.use_with_exit_node
    }
  }
  dynamic "split_dns" {
    for_each = each.value.split_dns
    content {
      domain = split_dns.key
      dynamic "nameservers" {
        for_each = split_dns.value
        content {
          address            = nameservers.value.address
          use_with_exit_node = nameservers.value.use_with_exit_node
        }
      }
    }
  }

  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = var.hth_profile_level >= 2
      error_message = "Reviewed complete DNS management requires profile L2+."
    }
    precondition {
      condition = var.dns_clients_support_exit_node_resolvers || alltrue([
        for server in concat(each.value.nameservers, flatten(values(each.value.split_dns))) : !server.use_with_exit_node
      ])
      error_message = "Verify client support before configuring exit-node DNS resolvers."
    }
  }
}
# HTH Guide Excerpt: end manage-reviewed-dns
