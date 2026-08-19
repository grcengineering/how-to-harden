# =============================================================================
# HTH Pack Contract: v1
#   control: ona-1.3
#   guide:   https://howtoharden.com/guides/ona/#13-apply-least-privilege-organization-roles-and-groups
#   profile: L1
#   mode:    mutating
#   requires: ONA_TOKEN(read-write PAT)
#
# HTH Ona Control 1.3: Apply Least-Privilege Organization Roles and Groups
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 5.4, 6.8 | NIST 800-53 AC-6(1) | SOC 2 CC6.3
# Source: https://howtoharden.com/guides/ona/#13-apply-least-privilege-organization-roles-and-groups
#
# PROVIDER BLOCK LIVES IN hth-ona-1.01-configure-sso.tf.
#
# Transcribed from registry docs fetched 2026-08-19:
#   https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/resources/group                        (doc 13236795)
#   https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/resources/group_membership             (doc 13236796)
#   https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/resources/organization_role_assignment (doc 13236801)
#   https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/data-sources/user                    (doc 13236831)
#   https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/data-sources/users                   (doc 13236832)
# all for provider-version 105656 = 0.4.0-beta.1.
#
# WHY TERRAFORM FOR THIS CONTROL: delegated roles are granted to GROUPS, not to
# users, and group permissions are a union with highest-level-wins. Reviewing who
# is admin of what is a diff problem, and this is the only surface that renders
# the whole group -> membership -> role graph as one reviewable artifact.
#
# TRAPS
#  1. ROLES ATTACH TO GROUPS, NOT USERS. ona_organization_role_assignment takes a
#     group_id and nothing else. There is no per-user role resource, and the
#     underlying API's SetRole verb only accepts full admin/member — the seven
#     delegated roles are resource-role assignments made to a group. Create a
#     group even for a single person.
#  2. ROLE ENUM IS PROVIDER-SPELLED, NOT API-SPELLED. Use exactly:
#     organization_admin, runners_admin, projects_admin, automations_admin,
#     groups_admin, environments_reader, insights_viewer, audit_log_reader,
#     billing_viewer. Do NOT write the API's RESOURCE_ROLE_ORG_* constants here.
#  3. HIGHEST LEVEL WINS ACROSS GROUPS. A user in a narrow group and a broad group
#     gets the broad group's rights. A least-privilege group is only least-
#     privilege if the same people are not also in a wider one — audit membership,
#     not just role names.
#  4. USER LOOKUP NEEDS email + login_provider TOGETHER. data.ona_user matches an
#     exact email paired with a login_provider of github, google, or custom (SSO).
#     The same human federated through two providers is two distinct Ona users.
#  5. CHANGING group_id, user_id, service_account_id OR role REPLACES the
#     membership/assignment. Terraform destroys access before recreating it —
#     expect a brief window, and never let that race a break-glass path.
#  6. ROLE CHANGES ARE NOT SELF-VERIFYING on the API (the write returns an empty
#     message). Terraform re-reads on refresh, which is precisely why this belongs
#     in Terraform rather than a one-shot script.
# =============================================================================

variable "runner_admins" {
  description = "Humans who administer runners. login_provider is one of github, google, or custom (SSO)."
  type = map(object({
    email          = string
    login_provider = string
  }))
  default = {}
}

variable "audit_log_readers" {
  description = "Humans who may READ audit logs and nothing else."
  type = map(object({
    email          = string
    login_provider = string
  }))
  default = {}
}

variable "user_search_domain" {
  description = "Substring used by the verification data source to inventory org members (typically your email domain)."
  type        = string
  default     = "example.com"
}

# HTH Guide Excerpt: begin terraform
# One group per duty. Delegated roles attach to groups, never to individual users.
resource "ona_group" "runner_admins" {
  name        = "Runner Admins"
  description = "Administers runners only. No identity, policy, or secret rights."
}

resource "ona_group" "audit_log_readers" {
  name        = "Audit Log Readers"
  description = "Read-only oversight. Can read audit logs, cannot change configuration."
}

# Resolve each human to a stable user_id. email alone is not enough — the same
# address under a different login_provider is a different Ona user.
data "ona_user" "runner_admins" {
  for_each = var.runner_admins

  email          = each.value.email
  login_provider = each.value.login_provider
}

data "ona_user" "audit_log_readers" {
  for_each = var.audit_log_readers

  email          = each.value.email
  login_provider = each.value.login_provider
}

resource "ona_group_membership" "runner_admins" {
  for_each = data.ona_user.runner_admins

  group_id = ona_group.runner_admins.id
  user_id  = each.value.user_id
}

resource "ona_group_membership" "audit_log_readers" {
  for_each = data.ona_user.audit_log_readers

  group_id = ona_group.audit_log_readers.id
  user_id  = each.value.user_id
}

# The narrowest admin role that covers the duty — NOT organization_admin.
resource "ona_organization_role_assignment" "runner_admins" {
  group_id = ona_group.runner_admins.id
  role     = "runners_admin"
}

# Read-only oversight: sees the audit trail, cannot alter configuration.
resource "ona_organization_role_assignment" "audit_log_readers" {
  group_id = ona_group.audit_log_readers.id
  role     = "audit_log_reader"
}
# HTH Guide Excerpt: end terraform

# HTH Guide Excerpt: begin verify
# Standing evidence for the "keep full organization admin to a small named set"
# half of the control. This lists org ADMINS, so a review reads the count and the
# names rather than trusting that nobody was promoted in the console.
data "ona_users" "org_admins" {
  search   = var.user_search_domain
  statuses = ["active"]
  roles    = ["admin"]
}

output "ona_active_org_admin_count" {
  description = "Number of active full organization admins. Investigate any growth."
  value       = length(data.ona_users.org_admins.users)
}
# HTH Guide Excerpt: end verify
