# =============================================================================
# HTH Sentry Control 3.1: Configure Data Scrubbing
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.1, NIST SI-12
# Source: https://howtoharden.com/guides/sentry/#31-configure-data-scrubbing
#
# NOTE: Server-side data scrubbing is configured per-project via the
# sentry_project resource's built-in settings. The sensitive_fields and
# safe_fields are passed to the Sentry API via project settings.
# For L2+, projects are created with hardened scrubbing defaults.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# ---------------------------------------------------------------------------
# Data scrubbing is applied at two levels:
#
# 1. Server-side (Sentry platform):
#    Configured via project settings. When projects are managed by
#    Control 2.2 (sentry_project.projects), scrubbing is enabled by
#    default on the Sentry platform. Custom sensitive fields are
#    configured via the Sentry API:
#
#    PUT /api/0/projects/{org_slug}/{project_slug}/
#      {
#        "dataScrubber": true,
#        "dataScrubberDefaults": true,
#        "sensitiveFields": ["password", "secret", "api_key", "token",
#                            "authorization", "credit_card", "ssn"],
#        "safeFields": [],
#        "scrubIPAddresses": true,
#        "scrapeJavaScript": false
#      }
#
# 2. Client-side (SDK beforeSend hooks):
#    Filter PII before transmission to Sentry. This must be implemented
#    in application code using the SDK's beforeSend callback.
#
# For L3 (Maximum Security), additionally disable JavaScript scraping
# and enable IP address scrubbing on all projects.
# ---------------------------------------------------------------------------
# HTH Guide Excerpt: end terraform
