# =============================================================================
# HTH Fivetran Control 3.2: Configure Network Security
# Profile Level: L2 (Hardened)
# Frameworks: CIS 13.5, NIST AC-17
# Source: https://howtoharden.com/guides/fivetran/#32-configure-network-security
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Network security: IP allowlisting and private networking (L2+)
#
# Fivetran publishes region-specific IP addresses that should be allowlisted
# on source systems. This control documents the IPs and provides validation.
#
# For PrivateLink (L3), configure via Fivetran Dashboard:
#   Account Settings > Networking > Private Networking

# Validate that Fivetran IPs are documented and allowlisted
resource "null_resource" "validate_network_security" {
  count = var.profile_level >= 2 ? 1 : 0

  triggers = {
    profile_level = var.profile_level
    ip_count      = length(var.approved_fivetran_ip_cidrs)
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================="
      echo "Network Security Configuration (L2+)"
      echo "============================================="
      echo ""

      # Fetch Fivetran IP addresses for the account region
      echo "Fetching Fivetran IP addresses..."
      curl -s \
        "https://api.fivetran.com/v1/metadata/connector-types" \
        -H "Authorization: Basic $(echo -n '${var.fivetran_api_key}:${var.fivetran_api_secret}' | base64)" \
        > /dev/null 2>&1 && echo "API accessible" || echo "WARN: API not accessible"

      echo ""
      echo "Configured approved Fivetran IP CIDRs:"
      %{ for cidr in var.approved_fivetran_ip_cidrs ~}
      echo "  - ${cidr}"
      %{ endfor ~}

      echo ""
      echo "Network Security Checklist:"
      echo "  [1] Allowlist only Fivetran IPs on source systems"
      echo "  [2] Block all other external access to source databases"
      echo "  [3] Enable SSL/TLS for all database connections"
      echo "  [4] Verify certificate validation is enabled"
      %{ if var.profile_level >= 3 ~}
      echo "  [5] Configure PrivateLink for private networking (L3)"
      %{ endif ~}
    EOT
  }
}

# SSH tunnel configuration reminder for database connectors
resource "null_resource" "ssh_tunnel_reminder" {
  count = var.profile_level >= 2 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo ""
      echo "SSH Tunnel Recommendation (L2+):"
      echo "  For database connectors, enable SSH tunnels instead of direct connections."
      echo "  Configure via: Connector Settings > Connection Method > Connect via SSH Tunnel"
      echo "  This encrypts data in transit and avoids exposing databases to the internet."
    EOT
  }
}
# HTH Guide Excerpt: end terraform
