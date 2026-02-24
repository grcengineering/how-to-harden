# =============================================================================
# HTH Vercel Control 6.2: Deployment Retention Policy
# Profile Level: L2 (Hardened)
# Frameworks: NIST SI-12
# Source: https://howtoharden.com/guides/vercel/#62-deployment-retention-policy
# =============================================================================

# HTH Guide Excerpt: begin terraform

# --- L2: Configure deployment retention to limit exposure of old deployments ---
resource "vercel_project" "deployment_retention" {
  count = var.profile_level >= 2 ? 1 : 0

  name = data.vercel_project.current.name

  deployment_expiration = {
    deploymentsToKeep           = var.deployments_to_keep
    expirationDays              = var.deployment_expiration_days
    expirationDaysCanceled      = var.deployment_expiration_days_canceled
    expirationDaysErrored       = var.deployment_expiration_days_errored
    expirationDaysProduction    = var.deployment_expiration_days_production
  }
}

# HTH Guide Excerpt: end terraform
