# =============================================================================
# HTH Jenkins Control 1.1: Enable Authentication
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.3, NIST IA-2
# Source: https://howtoharden.com/guides/jenkins/#11-enable-authentication
#
# NOTE: Jenkins authentication (security realm) is a system-level setting
# configured via Jenkins Configuration as Code (JCasC) or Groovy init scripts,
# not through the Terraform provider. This file provides the JCasC YAML as a
# local_file resource for deployment into $JENKINS_HOME/casc_configs/.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# JCasC configuration to enable authentication and disable anonymous access
resource "local_file" "enable_authentication" {
  filename = "${path.module}/generated/casc-enable-authentication.yaml"
  content  = yamlencode({
    jenkins = {
      securityRealm = {
        local = {
          allowsSignup = false
          users = [
            for user in var.admin_users : {
              id       = user
              password = "CHANGE_ME_ON_FIRST_LOGIN"
            }
          ]
        }
      }
      authorizationStrategy = {
        globalMatrix = {
          permissions = [
            "Overall/Administer:admin",
            "Overall/Read:authenticated",
          ]
        }
      }
    }
  })

  file_permission = "0644"
}
# HTH Guide Excerpt: end terraform
