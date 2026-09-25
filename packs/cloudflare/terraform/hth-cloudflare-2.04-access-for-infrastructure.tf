# =============================================================================
# HTH Cloudflare Control 2.4: Replace Long-Lived SSH Keys with Access for Infrastructure
# Profile Level: L2 (Walk)
# Frameworks: NIST AC-17, IA-5(2), AU-14 | CIS 6.4, 8.5
# Source: https://howtoharden.com/guides/cloudflare/#24-replace-long-lived-ssh-keys-with-access-for-infrastructure
#
# Registers one SSH target reachable through a tunnel's virtual network and
# protects it with an infrastructure application whose policy allows one IdP
# group to log in as named Unix users only (never root by default).
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "cloudflare_zero_trust_access_infrastructure_target" "ssh_server" {
  account_id = var.cloudflare_account_id
  hostname   = var.ssh_target_hostname

  ip = {
    ipv4 = {
      ip_addr            = var.ssh_target_ip
      virtual_network_id = var.ssh_target_virtual_network_id
    }
  }
}

resource "cloudflare_zero_trust_access_application" "ssh_infrastructure" {
  account_id = var.cloudflare_account_id
  name       = "SSH infrastructure"
  type       = "infrastructure"

  target_criteria = [{
    port     = 22
    protocol = "SSH"
    target_attributes = {
      hostname = [var.ssh_target_hostname]
    }
  }]

  # Connection rules (allowed Unix usernames) are only accepted on a policy
  # defined inline on the infrastructure application
  policies = [{
    name       = "SSH - platform engineering"
    decision   = "allow"
    precedence = 1
    include = [{
      group = {
        id = var.ssh_allowed_group_id
      }
    }]
    connection_rules = {
      ssh = {
        usernames = var.ssh_allowed_usernames
      }
    }
  }]
}
# HTH Guide Excerpt: end terraform
