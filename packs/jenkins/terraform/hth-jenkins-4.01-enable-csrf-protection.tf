# =============================================================================
# HTH Jenkins Control 4.1: Enable CSRF Protection
# Profile Level: L1 (Baseline)
# Frameworks: CIS 16.13, NIST SC-8
# Source: https://howtoharden.com/guides/jenkins/#41-enable-csrf-protection
#
# NOTE: CSRF protection is a system-level setting managed via JCasC.
# This generates the configuration to enable the Default Crumb Issuer
# with proxy compatibility for reverse-proxy deployments.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# JCasC configuration to enable CSRF protection
resource "local_file" "enable_csrf_protection" {
  filename = "${path.module}/generated/casc-csrf-protection.yaml"
  content  = yamlencode({
    security = {
      crumbIssuer = {
        standard = {
          excludeClientIPFromCrumb = var.csrf_proxy_compatibility
        }
      }
    }
    jenkins = {
      # Disable CLI remoting to reduce attack surface
      disableRememberMe = false
    }
  })

  file_permission = "0644"
}

# Groovy init script to verify CSRF protection is enabled
resource "local_file" "csrf_protection_groovy" {
  filename = "${path.module}/generated/init.groovy.d/csrf-protection.groovy"
  content  = <<-GROOVY
    // HTH Jenkins Control 4.1: Enable CSRF Protection
    // Profile Level: L1 (Baseline)
    import jenkins.model.Jenkins
    import hudson.security.csrf.DefaultCrumbIssuer

    def instance = Jenkins.instance

    // Enable Default Crumb Issuer with proxy compatibility
    instance.setCrumbIssuer(new DefaultCrumbIssuer(${var.csrf_proxy_compatibility}))
    instance.save()
    println("[HTH] CSRF protection enabled (proxy compatibility: ${var.csrf_proxy_compatibility})")
  GROOVY

  file_permission = "0644"
}
# HTH Guide Excerpt: end terraform
