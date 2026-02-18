# =============================================================================
# HTH Sentry Control 3.2: Configure DSN Security
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.11, NIST SC-12
# Source: https://howtoharden.com/guides/sentry/#32-configure-dsn-security
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create rate-limited client keys (DSNs) for each managed project.
# Rate limiting prevents DSN abuse and controls event volume.
resource "sentry_key" "rate_limited" {
  for_each = var.profile_level >= 2 ? var.projects : {}

  organization = var.sentry_organization
  project      = each.key
  name         = "${each.value.name} - Rate Limited Key"

  rate_limit_window = var.dsn_rate_limit_window
  rate_limit_count  = var.dsn_rate_limit_count

  depends_on = [sentry_project.projects]
}
# HTH Guide Excerpt: end terraform
