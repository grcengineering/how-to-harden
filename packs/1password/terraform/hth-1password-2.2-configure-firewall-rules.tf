# =============================================================================
# HTH 1Password Control 2.2: Configure Firewall Rules
# Profile Level: L2 (Hardened)
# Source: https://howtoharden.com/guides/1password/#22-configure-firewall-rules
# =============================================================================
#
# 1Password firewall rules restrict access by country and IP address. These
# are account-level admin settings configured via Admin Console > Security >
# Firewall. The Terraform provider does not manage firewall rules directly.
#
# This control documents firewall configuration and verifies expected state
# using the 1Password CLI where available.
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Document and verify firewall rule configuration (L2+ only).
resource "null_resource" "verify_firewall_rules" {
  count = var.profile_level >= 2 ? 1 : 0

  triggers = {
    profile_level     = var.profile_level
    allowed_countries = join(",", var.allowed_countries)
    denied_countries  = join(",", var.denied_countries)
    allowed_ips       = join(",", var.allowed_ip_cidrs)
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "======================================================="
      echo "HTH 1Password Control 2.2: Firewall Rules"
      echo "======================================================="
      echo ""
      echo "Profile Level: ${var.profile_level}"
      echo ""
      echo "Navigate to: Admin Console > Security > Firewall"
      echo ""
      echo "Required firewall rules (in priority order):"
      echo ""
      echo "  Rule 1 - Allow Countries: ${join(", ", var.allowed_countries)}"
      echo "  Rule 2 - Deny Countries:  ${join(", ", var.denied_countries)}"
      %{if var.profile_level >= 3~}
      echo ""
      echo "  L3 Additional Rules:"
      echo "  Rule 3 - Allow IPs: ${join(", ", var.allowed_ip_cidrs)}"
      echo "  Rule 4 - Deny all other countries"
      %{endif~}
      echo ""
      echo "WARNING: Test firewall rules thoroughly before enforcing."
      echo "Lockout risk: ensure admin IPs are always allowed."
    EOT
  }
}

# Store firewall configuration audit record (L2+ only).
resource "onepassword_item" "firewall_rules_audit" {
  count = var.profile_level >= 2 ? 1 : 0

  vault    = data.onepassword_vault.infrastructure.uuid
  title    = "HTH Firewall Rules Configuration"
  category = "secure_note"

  section {
    label = "Firewall Settings"

    field {
      label = "Profile Level"
      value = tostring(var.profile_level)
      type  = "STRING"
    }

    field {
      label = "Allowed Countries"
      value = join(", ", var.allowed_countries)
      type  = "STRING"
    }

    field {
      label = "Denied Countries"
      value = join(", ", var.denied_countries)
      type  = "STRING"
    }

    field {
      label = "IP Allowlist"
      value = length(var.allowed_ip_cidrs) > 0 ? join(", ", var.allowed_ip_cidrs) : "Not configured"
      type  = "STRING"
    }
  }

  tags = ["hth-hardening", "firewall", "network-security"]
}

# HTH Guide Excerpt: end terraform
