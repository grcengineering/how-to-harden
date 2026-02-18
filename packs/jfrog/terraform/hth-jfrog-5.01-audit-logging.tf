# =============================================================================
# HTH JFrog Control 5.1: Audit Logging
# Profile Level: L1 (Baseline)
# Frameworks: NIST AU-2, AU-3
# Source: https://howtoharden.com/guides/jfrog/#51-audit-logging
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Webhook for forwarding deployment events to SIEM
resource "artifactory_webhook" "deploy_events" {
  count = var.audit_webhook_url != "" ? 1 : 0

  key         = "hth-deploy-audit"
  description = "HTH: Forward artifact deploy events to SIEM"
  event_types = ["deployed", "deleted", "moved", "copied"]
  url         = var.audit_webhook_url
  enabled     = true

  criteria {
    any_local  = true
    any_remote = false
  }
}

# L2: Webhook for permission and access control change events
resource "artifactory_webhook" "access_events" {
  count = var.profile_level >= 2 && var.audit_webhook_url != "" ? 1 : 0

  key         = "hth-access-audit"
  description = "HTH: Forward access control events to SIEM (L2+)"
  event_types = ["deployed", "deleted", "moved", "copied", "downloaded"]
  url         = var.audit_webhook_url
  enabled     = true

  criteria {
    any_local  = true
    any_remote = true
  }
}

# L3: Comprehensive download audit for all repository access
resource "artifactory_webhook" "download_audit" {
  count = var.profile_level >= 3 && var.audit_webhook_url != "" ? 1 : 0

  key         = "hth-download-audit"
  description = "HTH: Audit all artifact downloads (L3)"
  event_types = ["downloaded"]
  url         = var.audit_webhook_url
  enabled     = true

  criteria {
    any_local  = true
    any_remote = true
  }
}

# HTH Guide Excerpt: end terraform
