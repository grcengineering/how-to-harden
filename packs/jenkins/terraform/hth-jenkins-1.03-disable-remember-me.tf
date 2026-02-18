# =============================================================================
# HTH Jenkins Control 1.3: Disable Remember Me
# Profile Level: L2 (Hardened)
# Frameworks: CIS 6.2, NIST AC-12
# Source: https://howtoharden.com/guides/jenkins/#13-disable-remember-me
#
# NOTE: The "Remember Me" toggle is a system-level setting managed via JCasC.
# This file generates the JCasC YAML and a Groovy init script.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# JCasC configuration to disable Remember Me (L2+)
resource "local_file" "disable_remember_me" {
  count = var.profile_level >= 2 ? 1 : 0

  filename = "${path.module}/generated/casc-disable-remember-me.yaml"
  content  = yamlencode({
    jenkins = {
      disableRememberMe = true
    }
  })

  file_permission = "0644"
}

# Groovy init script to disable Remember Me (alternative deployment method)
resource "local_file" "disable_remember_me_groovy" {
  count = var.profile_level >= 2 ? 1 : 0

  filename = "${path.module}/generated/init.groovy.d/disable-remember-me.groovy"
  content  = <<-GROOVY
    // HTH Jenkins Control 1.3: Disable Remember Me
    // Profile Level: L2 (Hardened)
    import jenkins.model.Jenkins

    def instance = Jenkins.instance
    instance.setDisableRememberMe(true)
    instance.save()
    println("[HTH] Remember Me has been disabled")
  GROOVY

  file_permission = "0644"
}
# HTH Guide Excerpt: end terraform
