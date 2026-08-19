# =============================================================================
# HTH Pack Contract: v1
#   control: ona-3.4
#   guide:   https://howtoharden.com/guides/ona/#34-restrict-environment-creation
#   profile: L2
#   mode:    mutating
#   requires: ONA_TOKEN(read-write PAT)
#
# HTH Ona Control 3.4: Restrict Environment Creation
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 4.1 | NIST 800-53 CM-7, AC-6
# Source: https://howtoharden.com/guides/ona/#34-restrict-environment-creation
#
# PROVIDER BLOCK LIVES IN hth-ona-1.01-configure-sso.tf.
#
# Transcribed from https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/resources/organization_policies
# (registry v2 provider-doc 13236800, provider-version 105656 = 0.4.0-beta.1).
#
# SINGLETON — merge these attributes into ONE ona_organization_policies resource
# if you adopt more than one pack; two resources managing the same object drift
# forever.
#
# WHY TERRAFORM FOR THIS CONTROL: the console presents "Only admins can start
# from scratch" as one switch, but the effective posture is the interaction of
# three fields. Declaring all three together is what makes "restricted" mean the
# same thing next quarter.
#
# TRAPS
#  1. THREE FIELDS, ONE POSTURE. disable_from_scratch blocks blank environments.
#     members_require_projects forces non-admins to start FROM a project.
#     members_create_projects decides whether those same members can just create
#     the project they need. Set the first two and leave the third true and a
#     member simply creates a throwaway project — the restriction is cosmetic.
#     The schema itself says members_create_projects and members_require_projects
#     must be "configure[d] together".
#  2. THIS ONLY BINDS NON-ADMINS. Every one of these fields is about members.
#     Admins keep from-scratch creation, so this control is only as strong as your
#     admin count — see pack 1.03 and keep full organization admin to a small
#     named set.
#  3. OMITTING AN ATTRIBUTE LEAVES IT UNMANAGED, not false. Verbatim on
#     disable_from_scratch: "Omit to leave the remote setting unmanaged."
#  4. PROTO3 OMITS DEFAULTS. Absent disable_from_scratch on the API read path
#     means FALSE — from-scratch creation is ALLOWED. A missing key is the
#     insecure value, never "compliant".
#  5. TURNING members_create_projects OFF HAS A WORKFLOW COST. Members can no
#     longer self-serve a new project; an admin or projects_admin must create it.
#     Grant projects_admin to a small group (pack 1.03) before flipping this, or
#     the control gets reverted the first busy Monday.
#  6. DESTROY IS NOT DELETE for ona_organization_policies — it restores the
#     pre-Terraform server-defined policy.
# =============================================================================

variable "disable_from_scratch" {
  description = "Block non-admin users from creating blank environments with no Git or URL initializer."
  type        = bool
  default     = true
}

variable "members_require_projects" {
  description = "Force non-admin users to create environments only from projects. Configure together with members_create_projects."
  type        = bool
  default     = true
}

variable "members_create_projects" {
  description = "Whether ordinary members can create projects. Leaving this true lets a member route around members_require_projects by creating a throwaway project."
  type        = bool
  default     = false
}

# HTH Guide Excerpt: begin terraform
# SINGLETON: at most one ona_organization_policies per organization (import id "current") —
# merge these attributes with any other ona pack you adopt; two resources drift forever.
resource "ona_organization_policies" "environment_creation" {
  # "Only admins can start from scratch".
  disable_from_scratch = var.disable_from_scratch

  # Channel members into reviewed project configurations...
  members_require_projects = var.members_require_projects

  # ...and close the escape hatch of creating a project to satisfy the rule.
  # These two are documented as fields to configure together.
  members_create_projects = var.members_create_projects
}
# HTH Guide Excerpt: end terraform

output "ona_environment_creation_posture" {
  description = "All three fields together. Restriction is only real when from-scratch is off, projects are required, AND members cannot create projects."
  value = {
    disable_from_scratch     = ona_organization_policies.environment_creation.disable_from_scratch
    members_require_projects = ona_organization_policies.environment_creation.members_require_projects
    members_create_projects  = ona_organization_policies.environment_creation.members_create_projects
  }
}
