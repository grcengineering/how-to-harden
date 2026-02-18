# =============================================================================
# HTH Jenkins Control 4.2: Secure Credentials Management
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.11, NIST SC-12
# Source: https://howtoharden.com/guides/jenkins/#42-secure-credentials-management
#
# Creates scoped credential folders to isolate secrets by domain (production,
# testing, third-party). Uses the jenkins_folder resource with restricted
# permissions so only jobs within each folder can access its credentials.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Credential domain folders for scoped secret management
resource "jenkins_folder" "credential_domain" {
  for_each = var.credential_domains

  name         = each.key
  display_name = replace(title(replace(each.key, "-", " ")), " ", " ")
  description  = each.value.description

  security {
    # Non-inheriting permissions: only folder members access folder credentials
    inheritance_strategy = "org.jenkinsci.plugins.matrixauth.inheritance.NonInheritingStrategy"
    permissions = concat(
      # Admins get full access
      [for user in var.admin_users : "hudson.model.Item.Build:${user}"],
      [for user in var.admin_users : "hudson.model.Item.Read:${user}"],
      [for user in var.admin_users : "hudson.model.Item.Configure:${user}"],
      [for user in var.admin_users : "com.cloudbees.plugins.credentials.CredentialsProvider.View:${user}"],
      [for user in var.admin_users : "com.cloudbees.plugins.credentials.CredentialsProvider.Create:${user}"],
      [for user in var.admin_users : "com.cloudbees.plugins.credentials.CredentialsProvider.Update:${user}"],
    )
  }
}
# HTH Guide Excerpt: end terraform
