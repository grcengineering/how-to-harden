# =============================================================================
# HTH Orca Control 2.2: Configure Account Scope
# Profile Level: L2 (Hardened)
# Frameworks: CIS 5.4, NIST AC-6
# Source: https://howtoharden.com/guides/orca/#22-configure-account-scope
#
# Creates business units to scope user visibility to specific cloud accounts.
# Separates production from non-production and applies business unit boundaries.
# Only deployed at profile level 2+.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Business unit for scoped access -- limits visibility to specific cloud accounts
resource "orcasecurity_business_unit" "scoped_environment" {
  count = var.profile_level >= 2 ? 1 : 0

  name          = var.business_unit_name
  global_filter = false

  filter_data = {
    cloud_providers = var.business_unit_cloud_providers
    cloud_tags      = length(var.business_unit_cloud_tags) > 0 ? var.business_unit_cloud_tags : null
  }
}

# Restricted production business unit (L3) -- strictest scoping for regulated environments
resource "orcasecurity_business_unit" "restricted_production" {
  count = var.profile_level >= 3 ? 1 : 0

  name          = var.restricted_business_unit_name
  global_filter = false

  filter_data = {
    cloud_tags = var.restricted_cloud_tags
  }
}
# HTH Guide Excerpt: end terraform
