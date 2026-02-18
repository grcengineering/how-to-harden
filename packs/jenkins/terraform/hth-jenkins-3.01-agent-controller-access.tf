# =============================================================================
# HTH Jenkins Control 3.1: Enable Agent to Controller Access Control
# Profile Level: L1 (Baseline)
# Frameworks: CIS 13.5, NIST AC-4
# Source: https://howtoharden.com/guides/jenkins/#31-enable-agent-to-controller-access-control
#
# NOTE: Agent-to-Controller access control is a system-level setting managed
# via JCasC. This generates the configuration to restrict agent commands and
# file path access on the controller.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# JCasC configuration to enable Agent-to-Controller access control
resource "local_file" "agent_controller_access" {
  filename = "${path.module}/generated/casc-agent-controller-access.yaml"
  content  = yamlencode({
    jenkins = {
      remotingSecurity = {
        enabled = true
      }
    }
    security = {
      apiToken = {
        creationOfLegacyToken = false
        tokenGenerationOnCreationEnabled = false
        usageStatisticsEnabled = true
      }
    }
  })

  file_permission = "0644"
}

# Groovy init script to verify and enforce agent-controller security
resource "local_file" "agent_controller_access_groovy" {
  filename = "${path.module}/generated/init.groovy.d/agent-controller-access.groovy"
  content  = <<-GROOVY
    // HTH Jenkins Control 3.1: Enable Agent to Controller Access Control
    // Profile Level: L1 (Baseline)
    import jenkins.model.Jenkins
    import jenkins.security.s2m.AdminWhitelistRule

    def rule = Jenkins.instance.getInjector().getInstance(AdminWhitelistRule.class)
    rule.setMasterKillSwitch(false)
    Jenkins.instance.save()
    println("[HTH] Agent-to-Controller access control enabled")
  GROOVY

  file_permission = "0644"
}
# HTH Guide Excerpt: end terraform
