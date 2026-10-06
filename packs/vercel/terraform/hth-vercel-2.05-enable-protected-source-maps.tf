# =============================================================================
# HTH Vercel Control 2.5: Enable Protected Source Maps
# Profile Level: L1 (Crawl)
# Frameworks: NIST AC-3, SC-28, CM-6
# Source: https://howtoharden.com/guides/vercel/#25-enable-protected-source-maps
# Reference: https://vercel.com/docs/deployment-protection/protected-source-maps
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Applied through vercel_project.hardened (hth-vercel-2.01): .map requests
# must pass Deployment Protection; everyone else receives a 404.
locals {
  protected_sourcemaps = true
}

# HTH Guide Excerpt: end terraform
