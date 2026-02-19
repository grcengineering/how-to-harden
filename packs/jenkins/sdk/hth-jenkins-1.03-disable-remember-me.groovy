// =============================================================================
// HTH Jenkins Control 1.3: Disable Remember Me
// Profile: L2 | Section: 1.3
// =============================================================================

// HTH Guide Excerpt: begin disable-remember-me
// In init.groovy.d/disable-remember-me.groovy
import jenkins.model.Jenkins
Jenkins.instance.setDisableRememberMe(true)
Jenkins.instance.save()
// HTH Guide Excerpt: end disable-remember-me
