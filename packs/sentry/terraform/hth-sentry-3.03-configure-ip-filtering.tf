# =============================================================================
# HTH Sentry Control 3.3: Configure IP Filtering
# Profile Level: L2 (Hardened)
# Frameworks: CIS 13.5, NIST AC-17
# Source: https://howtoharden.com/guides/sentry/#33-configure-ip-filtering
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Enable inbound data filters on managed projects (L2+ only).
# These filters reduce noise and block events from known non-production
# sources such as browser extensions, localhost, and web crawlers.
resource "sentry_project_inbound_data_filter" "filters" {
  for_each = var.profile_level >= 2 ? toset([
    for pair in setproduct(keys(var.projects), var.inbound_data_filters) :
    "${pair[0]}:${pair[1]}"
  ]) : toset([])

  organization = var.sentry_organization
  project      = split(":", each.value)[0]
  filter_id    = split(":", each.value)[1]
  active       = true

  depends_on = [sentry_project.projects]
}

# Filter legacy browser events to reduce noise from unsupported clients (L2+)
resource "sentry_project_inbound_data_filter" "legacy_browsers" {
  for_each = var.profile_level >= 2 ? toset(keys(var.projects)) : toset([])

  organization = var.sentry_organization
  project      = each.value
  filter_id    = "legacy-browsers"
  subfilters   = var.legacy_browser_subfilters

  depends_on = [sentry_project.projects]
}
# HTH Guide Excerpt: end terraform
