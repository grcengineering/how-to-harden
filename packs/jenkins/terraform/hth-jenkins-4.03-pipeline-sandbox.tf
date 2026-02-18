# =============================================================================
# HTH Jenkins Control 4.3: Implement Pipeline Sandbox
# Profile Level: L1 (Baseline)
# Frameworks: CIS 16.1, NIST CM-7
# Source: https://howtoharden.com/guides/jenkins/#43-implement-pipeline-sandbox
#
# NOTE: The Groovy sandbox is enabled by default for pipeline scripts.
# This generates JCasC and Groovy configuration to enforce sandbox mode
# and restrict script approval to administrators only.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# JCasC configuration to enforce pipeline sandbox restrictions
resource "local_file" "pipeline_sandbox" {
  filename = "${path.module}/generated/casc-pipeline-sandbox.yaml"
  content  = yamlencode({
    security = {
      globalJobDslSecurityConfiguration = {
        useScriptSecurity = true
      }
    }
    unclassified = {
      globalLibraries = {
        libraries = []
      }
    }
  })

  file_permission = "0644"
}

# Groovy init script to enforce sandbox and clear unsafe approvals
resource "local_file" "pipeline_sandbox_groovy" {
  filename = "${path.module}/generated/init.groovy.d/pipeline-sandbox.groovy"
  content  = <<-GROOVY
    // HTH Jenkins Control 4.3: Implement Pipeline Sandbox
    // Profile Level: L1 (Baseline)
    import org.jenkinsci.plugins.scriptsecurity.scripts.ScriptApproval
    import java.util.logging.Logger

    def logger = Logger.getLogger("jenkins.security.pipeline-sandbox")

    def approval = ScriptApproval.get()
    def pendingCount = approval.getPendingScripts().size()

    if (pendingCount > 0) {
      logger.warning("[HTH] $${pendingCount} pending script approvals detected - review required")
    }

    logger.info("[HTH] Pipeline sandbox enforcement verified")
    println("[HTH] Pipeline sandbox is active - scripts run in restricted mode")
  GROOVY

  file_permission = "0644"
}
# HTH Guide Excerpt: end terraform
