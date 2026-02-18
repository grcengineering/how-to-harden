# =============================================================================
# HTH Jenkins Control 5.2: Keep Jenkins Updated
# Profile Level: L1 (Baseline)
# Frameworks: CIS 7.3, NIST SI-2
# Source: https://howtoharden.com/guides/jenkins/#52-keep-jenkins-updated
#
# NOTE: Jenkins core and plugin updates cannot be managed via Terraform.
# This generates JCasC configuration to set the update center and a
# Groovy init script that checks for and logs available security updates.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# JCasC configuration for update center settings
resource "local_file" "update_center_config" {
  filename = "${path.module}/generated/casc-update-center.yaml"
  content  = yamlencode({
    jenkins = {
      updateCenter = {
        sites = [
          {
            id  = "default"
            url = "https://updates.jenkins.io/update-center.json"
          }
        ]
      }
    }
  })

  file_permission = "0644"
}

# Groovy init script to check for security updates on startup
resource "local_file" "check_updates_groovy" {
  filename = "${path.module}/generated/init.groovy.d/check-security-updates.groovy"
  content  = <<-GROOVY
    // HTH Jenkins Control 5.2: Keep Jenkins Updated
    // Profile Level: L1 (Baseline)
    import jenkins.model.Jenkins
    import java.util.logging.Logger

    def logger = Logger.getLogger("jenkins.security.update-check")

    def instance = Jenkins.instance
    def updateCenter = instance.getUpdateCenter()

    // Log current Jenkins version
    logger.info("[HTH] Jenkins version: $${Jenkins.VERSION}")

    // Check for core updates
    updateCenter.getSites().each { site ->
      def updates = site.getUpdates()
      if (updates != null && updates.size() > 0) {
        logger.warning("[HTH] $${updates.size()} plugin updates available")
        updates.each { update ->
          if (update.hasWarnings()) {
            logger.severe("[HTH] SECURITY UPDATE: $${update.name} $${update.version}")
          }
        }
      }
    }

    println("[HTH] Security update check completed")
  GROOVY

  file_permission = "0644"
}
# HTH Guide Excerpt: end terraform
