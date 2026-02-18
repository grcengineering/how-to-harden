# =============================================================================
# HTH Splunk Control 2.2: Configure Index Access
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.3, NIST AC-3
# Source: https://howtoharden.com/guides/splunk/#22-configure-index-access
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create dedicated indexes for security data with appropriate access controls.
# Restrict sensitive indexes to the security team through role-based access.

# Dedicated security log index
resource "splunk_indexes" "security" {
  name               = var.security_index_name
  datatype           = "event"
  max_hot_buckets    = 10
  max_data_size      = var.security_index_max_data_size
  frozen_time_period_in_secs = var.security_index_frozen_time_period
}

# Audit trail index with extended retention (L1)
resource "splunk_indexes" "audit_trail" {
  name               = var.audit_index_name
  datatype           = "event"
  max_hot_buckets    = 6
  max_data_size      = var.security_index_max_data_size
  frozen_time_period_in_secs = var.audit_index_frozen_time_period
}

# Threat intelligence index (L2+)
resource "splunk_indexes" "threat_intel" {
  count = var.profile_level >= 2 ? 1 : 0

  name               = "threat_intel"
  datatype           = "event"
  max_hot_buckets    = 3
  max_data_size      = "auto"
  frozen_time_period_in_secs = 31536000  # 1 year
}
# HTH Guide Excerpt: end terraform
