# =============================================================================
# HTH Splunk Control 3.1: Configure Search Security
# Profile Level: L1 (Baseline), enhanced at L2
# Frameworks: CIS 3.3, NIST AC-3
# Source: https://howtoharden.com/guides/splunk/#31-configure-search-security
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Control what data users can search and enforce search quotas.
# Prevents resource abuse and limits data exposure.

# Search quota limits for standard users via limits.conf
resource "splunk_configs_conf" "search_limits_standard" {
  name = "limits/restapi"

  variables = {
    "maxresultrows" = "50000"
  }
}

# Configure search concurrency limits
resource "splunk_configs_conf" "search_scheduler_limits" {
  name = "limits/scheduler"

  variables = {
    "max_searches_perc"         = "50"
    "auto_summary_perc"         = "50"
    "max_action_results"        = "50000"
  }
}

# L2: Tighter search time window restrictions
resource "splunk_configs_conf" "search_limits_hardened" {
  count = var.profile_level >= 2 ? 1 : 0

  name = "limits/search"

  variables = {
    "max_searches_per_cpu"        = "1"
    "search_process_mode"         = "auto"
    "max_rt_search_multiplier"    = "1"
    "dispatch_dir_warning_size"   = "500"
  }
}

# L3: Maximum search restrictions
resource "splunk_configs_conf" "search_limits_maximum" {
  count = var.profile_level >= 3 ? 1 : 0

  name = "limits/searchresults"

  variables = {
    "maxresultrows"               = "10000"
    "max_count"                   = "10000"
    "compress_rawdata"            = "true"
  }
}
# HTH Guide Excerpt: end terraform
