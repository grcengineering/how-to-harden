# =============================================================================
# HTH JFrog Control 4.1: Configure Xray Policies
# Profile Level: L1 (Baseline)
# Frameworks: NIST RA-5
# Source: https://howtoharden.com/guides/jfrog/#41-configure-xray-policies
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Security policy: block critical CVEs from being downloaded
resource "artifactory_xray_security_policy" "block_critical" {
  name        = "hth-block-critical-cves"
  description = "HTH: Block artifacts with critical vulnerabilities"
  type        = "security"

  rule {
    name     = "critical-cve-block"
    priority = 1

    criteria {
      min_severity = "Critical"
    }

    actions {
      block_download {
        active    = var.xray_block_critical
        unscanned = true
      }
      fail_build = true
    }
  }
}

# L2: Also block high-severity CVEs
resource "artifactory_xray_security_policy" "block_high" {
  count = var.profile_level >= 2 ? 1 : 0

  name        = "hth-block-high-cves"
  description = "HTH: Block artifacts with high vulnerabilities (L2+)"
  type        = "security"

  rule {
    name     = "high-cve-block"
    priority = 1

    criteria {
      min_severity = "High"
    }

    actions {
      block_download {
        active    = true
        unscanned = true
      }
      fail_build = true
    }
  }
}

# Xray watch: monitor production repositories for vulnerabilities
resource "artifactory_xray_watch" "production" {
  name        = "hth-production-watch"
  description = "HTH: Monitor production repositories for security vulnerabilities"
  active      = true

  dynamic "watch_resource" {
    for_each = var.xray_watch_repos
    content {
      type = "repository"
      name = watch_resource.value
    }
  }

  assigned_policy {
    name = artifactory_xray_security_policy.block_critical.name
    type = "security"
  }
}

# L2: Assign high-severity policy to watch as well
resource "artifactory_xray_watch" "production_strict" {
  count = var.profile_level >= 2 ? 1 : 0

  name        = "hth-production-watch-strict"
  description = "HTH: Strict production watch with high CVE blocking (L2+)"
  active      = true

  dynamic "watch_resource" {
    for_each = var.xray_watch_repos
    content {
      type = "repository"
      name = watch_resource.value
    }
  }

  assigned_policy {
    name = artifactory_xray_security_policy.block_critical.name
    type = "security"
  }

  assigned_policy {
    name = artifactory_xray_security_policy.block_high[0].name
    type = "security"
  }
}

# HTH Guide Excerpt: end terraform
