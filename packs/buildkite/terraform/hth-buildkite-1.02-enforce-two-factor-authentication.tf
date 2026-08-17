# =============================================================================
# HTH Buildkite Control 1.2: Enforce Two-Factor Authentication
# Profile Level: L1 (Crawl)
# Frameworks: CIS 6.5 | NIST IA-2(1)
# Source: https://howtoharden.com/guides/buildkite/#12-enforce-two-factor-authentication
#
# PREREQUISITE — plan gate. This resource fails to CREATE on plans without the
# API IP allowlist feature, even though the configuration below never sets
# allowed_api_ip_addresses; the provider touches that field on create anyway.
# Observed against a live organization:
#   Error: Unable to create Organization settings: input: The API IP allowlist
#   feature is not available for your organization. Please upgrade your plan.
# `terraform validate` and `terraform plan` both PASS — this appears only at
# apply. On plans without the feature, use the guide's ClickOps path instead.
#
# SINGLETON CONFLICT. buildkite_organization represents the ONE organization
# object. Pack 4.01 declares a second resource (buildkite_organization
# .api_restrictions) against the same object. Applying both makes two Terraform
# resources manage one remote object, which produces perpetual drift — each plan
# will try to reconcile the other's fields. Adopt ONE of these packs, not both,
# or merge them into a single resource.
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "buildkite_organization" "hardened" {
  enforce_2fa = var.enforce_2fa
}
# HTH Guide Excerpt: end terraform
