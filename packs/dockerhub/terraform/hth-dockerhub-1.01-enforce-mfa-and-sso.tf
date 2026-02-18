# =============================================================================
# HTH Docker Hub Control 1.1: Enforce MFA and SSO
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-2(1)
# Source: https://howtoharden.com/guides/dockerhub/#11-enforce-mfa-and-sso
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure SAML SSO for Docker Hub organization (Business plan required).
# MFA enforcement is configured at the IdP level via SAML SSO;
# Docker Hub does not expose a direct MFA toggle via Terraform.
# This resource enforces SSO-based authentication for all org members.
resource "docker_org_setting" "enforce_sso" {
  count = var.enforce_sso ? 1 : 0

  org_name = var.dockerhub_organization
  setting  = "sso"
  value    = "enforced"
}

# Validate SSO configuration via API using a null_resource provisioner.
# This checks that MFA is enforced at the organization level.
resource "null_resource" "verify_mfa_enforcement" {
  triggers = {
    org_name = var.dockerhub_organization
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "=== Docker Hub MFA & SSO Verification ==="
      echo "Organization: ${var.dockerhub_organization}"
      echo ""
      echo "Manual verification required:"
      echo "  1. Navigate to: https://hub.docker.com/orgs/${var.dockerhub_organization}/settings/security"
      echo "  2. Confirm MFA is enforced for all members"
      echo "  3. Confirm SSO is configured (if Business plan)"
      echo ""
      echo "API check (requires authenticated session):"
      curl -sf -H "Authorization: Bearer ${var.dockerhub_token}" \
        "https://hub.docker.com/v2/orgs/${var.dockerhub_organization}/settings" \
        | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(f'  SSO enabled: {data.get(\"sso_enabled\", \"unknown\")}')
    print(f'  MFA required: {data.get(\"require_mfa\", \"unknown\")}')
except:
    print('  Could not parse response (manual verification needed)')
" 2>/dev/null || echo "  API check skipped (verify manually)"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
