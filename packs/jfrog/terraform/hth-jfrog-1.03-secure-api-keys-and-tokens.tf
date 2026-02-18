# =============================================================================
# HTH JFrog Control 1.3: Secure API Keys and Tokens
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5
# Source: https://howtoharden.com/guides/jfrog/#13-secure-api-keys-and-tokens
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Create a scoped access token for CI/CD pipelines with limited expiry
resource "artifactory_scoped_token" "ci_cd_token" {
  scopes      = ["applied-permissions/groups:${var.ci_cd_group}"]
  expires_in  = var.token_expiry_seconds
  description = "HTH: Scoped CI/CD token with ${var.token_expiry_seconds / 86400}-day expiry"
}

# L2: Create a shorter-lived admin token with tighter rotation
resource "artifactory_scoped_token" "admin_token" {
  count = var.profile_level >= 2 ? 1 : 0

  scopes      = ["applied-permissions/admin"]
  expires_in  = 2592000 # 30 days
  description = "HTH: Short-lived admin token (30-day expiry, L2+)"
}

# HTH Guide Excerpt: end terraform
