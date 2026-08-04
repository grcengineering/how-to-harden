# =============================================================================
# HTH GitHub Control 5.10: Configure Repository Custom Properties
# Profile Level: L2 (Hardened)
# Frameworks: NIST RA-2, SC-16, CM-8
# Source: https://howtoharden.com/guides/github/#56-configure-repository-custom-properties-for-security-classification
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_organization_custom_property" "security_tier" {
  key          = "security-tier"
  value_type   = "single_select"
  required     = true
  default_value = "standard"
  description  = "Security classification tier for the repository"

  allowed_values = [
    "critical",
    "high",
    "standard",
    "low",
  ]
}

resource "github_organization_custom_property" "data_classification" {
  key          = "data-classification"
  value_type   = "single_select"
  required     = true
  default_value = "internal"
  description  = "Data classification level"

  allowed_values = [
    "public",
    "internal",
    "confidential",
    "restricted",
  ]
}
# HTH Guide Excerpt: end terraform
