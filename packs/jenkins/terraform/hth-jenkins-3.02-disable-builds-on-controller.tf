# =============================================================================
# HTH Jenkins Control 3.2: Disable Builds on Controller
# Profile Level: L1 (Baseline)
# Frameworks: CIS 4.1, NIST CM-7
# Source: https://howtoharden.com/guides/jenkins/#32-disable-builds-on-controller
#
# NOTE: The number of executors on the built-in node is a system-level setting.
# This generates JCasC YAML and a Groovy init script to set controller
# executors to 0 and apply a restrictive label.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# JCasC configuration to disable builds on the controller node
resource "local_file" "disable_builds_on_controller" {
  filename = "${path.module}/generated/casc-disable-controller-builds.yaml"
  content  = yamlencode({
    jenkins = {
      numExecutors = var.controller_executors
      labelString  = var.controller_label
      mode         = "EXCLUSIVE"
    }
  })

  file_permission = "0644"
}

# Groovy init script to set controller executors to 0
resource "local_file" "disable_controller_builds_groovy" {
  filename = "${path.module}/generated/init.groovy.d/disable-controller-builds.groovy"
  content  = <<-GROOVY
    // HTH Jenkins Control 3.2: Disable Builds on Controller
    // Profile Level: L1 (Baseline)
    import jenkins.model.Jenkins
    import hudson.model.Node

    def instance = Jenkins.instance
    instance.setNumExecutors(${var.controller_executors})
    instance.setLabelString("${var.controller_label}")
    instance.setMode(Node.Mode.EXCLUSIVE)
    instance.save()
    println("[HTH] Controller executors set to ${var.controller_executors}, label: ${var.controller_label}")
  GROOVY

  file_permission = "0644"
}
# HTH Guide Excerpt: end terraform
