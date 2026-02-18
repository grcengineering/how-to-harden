# =============================================================================
# HTH Docker Hub Control 1.2: Implement Access Tokens
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5
# Source: https://howtoharden.com/guides/dockerhub/#12-implement-access-tokens
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create a scoped read-only access token for CI/CD pipeline pulls.
# Access tokens replace password-based authentication for automation.
resource "docker_hub_access_token" "ci_cd_readonly" {
  token_label = var.ci_cd_token_description
  scopes      = var.ci_cd_token_scopes
  is_active   = true
}

# Create a scoped read/write access token for build pipelines.
# This token should be rotated monthly per the hardening guide.
resource "docker_hub_access_token" "build_readwrite" {
  token_label = var.build_token_description
  scopes      = var.build_token_scopes
  is_active   = true
}

# Reminder for token rotation policy enforcement.
# Docker Hub does not support automatic token expiration via API;
# rotation must be enforced through operational procedures.
resource "null_resource" "token_rotation_reminder" {
  triggers = {
    quarterly_check = formatdate("YYYY-QQ", timestamp())
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "=== Docker Hub Access Token Rotation Reminder ==="
      echo ""
      echo "Token rotation schedule:"
      echo "  CI/CD pull tokens:  Rotate quarterly"
      echo "  Build/push tokens:  Rotate monthly"
      echo ""
      echo "Steps to rotate:"
      echo "  1. Create new token at: Account Settings > Security > Access Tokens"
      echo "  2. Update CI/CD pipeline secrets with new token value"
      echo "  3. Verify pipelines work with new token"
      echo "  4. Revoke the old token"
      echo ""
      echo "API endpoint for token management:"
      echo "  POST https://hub.docker.com/v2/access-tokens"
      echo "  DELETE https://hub.docker.com/v2/access-tokens/{uuid}"
    EOT
  }

  lifecycle {
    ignore_changes = [triggers]
  }
}
# HTH Guide Excerpt: end terraform
