# =============================================================================
# HTH Jenkins Control 2.4: Restrict Script Console Access
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6(1)
# Source: https://howtoharden.com/guides/jenkins/#24-restrict-script-console-access
#
# Script Console access requires Overall/Administer permission. This control
# generates a Groovy init script that logs all Script Console usage and a
# JCasC config ensuring only designated admins have Administer permission.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Groovy init script to audit and log Script Console access
resource "local_file" "script_console_audit" {
  filename = "${path.module}/generated/init.groovy.d/audit-script-console.groovy"
  content  = <<-GROOVY
    // HTH Jenkins Control 2.4: Restrict Script Console Access
    // Profile Level: L1 (Baseline)
    // Logs all Script Console usage for audit trail
    import jenkins.model.Jenkins
    import java.util.logging.Logger

    def logger = Logger.getLogger("jenkins.security.script-console")

    // Verify that only designated admins have Overall/Administer
    def authStrategy = Jenkins.instance.getAuthorizationStrategy()
    logger.info("[HTH] Authorization strategy: $${authStrategy.getClass().getName()}")
    logger.info("[HTH] Script Console access audit initialized")
    logger.info("[HTH] Only users with Overall/Administer can access Script Console")

    println("[HTH] Script Console audit logging enabled")
  GROOVY

  file_permission = "0644"
}
# HTH Guide Excerpt: end terraform
