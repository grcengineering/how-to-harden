# =============================================================================
# HTH 1Password Control 4.1: Enable Audit Logging
# Profile Level: L1 (Baseline)
# Source: https://howtoharden.com/guides/1password/#41-enable-audit-logging
# =============================================================================
#
# 1Password Business/Enterprise provides activity logging and Events API for
# SIEM integration. Activity logs are available in Admin Console > Reports.
# The Events API enables streaming to Splunk, Azure Sentinel, or webhooks.
#
# This control verifies Events API connectivity and stores SIEM integration
# configuration for audit purposes.
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Verify Events API / SIEM integration connectivity.
resource "null_resource" "verify_audit_logging" {
  triggers = {
    profile_level = var.profile_level
    siem_endpoint = var.siem_endpoint
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "======================================================="
      echo "HTH 1Password Control 4.1: Audit Logging"
      echo "======================================================="
      echo ""
      echo "Profile Level: ${var.profile_level}"
      echo ""
      echo "Activity Log (built-in):"
      echo "  Navigate to: Admin Console > Reports > Activity Log"
      echo "  Logged events include:"
      echo "    - Sign-in events"
      echo "    - Vault access"
      echo "    - Item changes"
      echo "    - Admin actions"
      echo ""
      if [ -n "${var.siem_endpoint}" ]; then
        echo "SIEM Integration:"
        echo "  Endpoint: ${var.siem_endpoint}"
        echo ""
        echo "  Verifying SIEM endpoint connectivity..."
        RESPONSE=$(curl -sf -o /dev/null -w "%%{http_code}" "${var.siem_endpoint}" 2>/dev/null)
        if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "401" ] || [ "$RESPONSE" = "403" ]; then
          echo "  SIEM endpoint reachable (HTTP $RESPONSE)"
        else
          echo "  WARNING: SIEM endpoint may be unreachable (HTTP $RESPONSE)"
        fi
      else
        echo "SIEM Integration: Not configured"
        echo "  To enable, set var.siem_endpoint and var.events_api_token"
        echo ""
        echo "  Supported SIEM platforms:"
        echo "    - Splunk (via Events API)"
        echo "    - Azure Sentinel"
        echo "    - Generic webhook"
      fi
      echo ""
      echo "Events API configuration:"
      echo "  Navigate to: Integrations > Events"
      echo "  Configure event streaming to your SIEM"
      echo "  Select events to stream based on profile level:"
      echo "    L1: Sign-in events, admin actions"
      echo "    L2: All L1 + vault access, item changes"
      echo "    L3: All L2 + all available event types"
    EOT
  }
}

# Store SIEM integration configuration reference.
resource "onepassword_item" "siem_integration_config" {
  count = var.siem_endpoint != "" ? 1 : 0

  vault    = data.onepassword_vault.infrastructure.uuid
  title    = "HTH SIEM Integration Configuration"
  category = "secure_note"

  section {
    label = "SIEM Settings"

    field {
      label = "SIEM Endpoint"
      value = var.siem_endpoint
      type  = "STRING"
    }

    field {
      label = "Events API Token"
      value = "Stored separately -- see 1Password admin"
      type  = "STRING"
    }

    field {
      label = "Event Types"
      value = var.profile_level >= 3 ? "All events" : var.profile_level >= 2 ? "Sign-ins, admin actions, vault access, item changes" : "Sign-ins, admin actions"
      type  = "STRING"
    }

    field {
      label = "Profile Level"
      value = tostring(var.profile_level)
      type  = "STRING"
    }
  }

  tags = ["hth-hardening", "audit-logging", "siem"]
}

# HTH Guide Excerpt: end terraform
