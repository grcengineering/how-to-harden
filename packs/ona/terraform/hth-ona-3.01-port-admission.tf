# =============================================================================
# HTH Pack Contract: v1
#   control: ona-3.1
#   guide:   https://howtoharden.com/guides/ona/#31-restrict-port-admission-levels
#   profile: L1
#   mode:    mutating
#   requires: ONA_TOKEN(read-write PAT)
#
# HTH Ona Control 3.1: Restrict Port Admission Levels
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 4.1, 12.2 | NIST 800-53 AC-3, SC-7 | SOC 2 CC6.6
# Source: https://howtoharden.com/guides/ona/#31-restrict-port-admission-levels
#
# PROVIDER BLOCK LIVES IN hth-ona-1.01-configure-sso.tf.
#
# Transcribed from registry docs fetched 2026-08-19:
#   https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/resources/security_policy       (doc 13236811)
#   https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/resources/organization_policies (doc 13236800)
# both for provider-version 105656 = 0.4.0-beta.1.
#
# SINGLETON — merge these attributes into ONE ona_organization_policies resource
# if you adopt more than one pack; two resources managing the same object drift
# forever.
#
# WHY TERRAFORM FOR THIS CONTROL: port admission is enforced by a SecurityPolicy,
# but a SecurityPolicy only enforces once it is assigned as the org default — and
# the separate port-sharing kill switch lives on a different object. Terraform is
# the only surface that holds both halves in one plan.
#
# TRAPS
#  1. THE DEPRECATED ENUM CANNOT BE REACHED FROM HERE, AND THAT IS THE POINT. The
#     vendor's own CreateSecurityPolicy cURL example uses ADMISSION_LEVEL_OWNER_ONLY,
#     which that same page's enum table marks "Deprecated… Use
#     ADMISSION_LEVEL_CREATOR_ONLY instead". Copy that example into a shell pack
#     and you ship a deprecated value. The Terraform provider's enum is only
#     everyone | organization | creator_only — there is no owner_only to get wrong.
#  2. A CREATED POLICY IS INERT UNTIL ASSIGNED. ona_security_policy alone enforces
#     nothing; security_policy_id below is what activates it. See pack 2.01.
#  3. `spec` AND `ports` ARE BLOCKS, NOT ATTRIBUTES. Write `spec { ports { ... } }`
#     with no `=`.
#  4. OMITTING THE ports BLOCK IS NOT "RESTRICTED". Verbatim: "Omit the ports block
#     to leave port admission unrestricted by this security policy." Declaring the
#     block is the control.
#  4b. THE VENDOR'S OWN "ports_only" EXAMPLE DOES NOT VALIDATE. The registry doc
#     for ona_security_policy publishes a `ports_only` example whose spec contains
#     only a `ports` block. Copied verbatim it fails on 0.4.0-beta.1 with
#     Terraform 1.14 (measured, linux/amd64):
#       Error: Missing Configuration for Required Attribute
#       Must set a configuration value for the spec.executables.default_effect
#       attribute as the provider has marked it as required.
#     The doc marks `executables` Optional; the provider's schema marks
#     spec.executables.default_effect Required regardless. A ports-only policy
#     must therefore still carry an executables block. `default_effect = "allow"`
#     below is the no-op choice — it changes no executable posture — but be aware
#     that assigning this policy as the org default does set an executables
#     default. If you also run pack 2.01, MERGE the two into ONE policy rather
#     than letting this "allow" quietly relax a Veto baseline.
#  5. TWO DIFFERENT LEVERS, BOTH NEEDED. max_admission_level caps how widely a port
#     MAY be admitted; port_sharing_disabled removes user-initiated port sharing
#     entirely. Setting only the first still leaves the sharing affordance in
#     place at the capped level.
#  6. THE TERRAFORM SURFACE IS WIDER THAN THE CLI'S. The published CLI/YAML
#     "Veto Exec" contract does not expose ports at all; this schema does. Do not
#     assume the two surfaces are interchangeable.
#  7. IF YOU ALSO ADOPT PACK 2.01, USE ONE ona_security_policy, NOT TWO. A single
#     policy carries both `executables` and `ports` inside one `spec`. Two policies
#     means only the assigned one enforces and the other is decoration.
# =============================================================================

variable "organization_id" {
  description = "Ona organization ID that owns the security policy."
  type        = string
}

variable "port_policy_name" {
  description = "Security policy name shown in Ona. 1-80 characters."
  type        = string
  default     = "hth-port-admission"
}

variable "max_port_admission_level" {
  description = "Ceiling for user-opened port admission. One of everyone, organization, creator_only. There is no owner_only in this provider — it is the deprecated API spelling."
  type        = string
  default     = "creator_only"

  validation {
    condition     = contains(["everyone", "organization", "creator_only"], var.max_port_admission_level)
    error_message = "max_port_admission_level must be one of: everyone, organization, creator_only."
  }
}

variable "port_sharing_disabled" {
  description = "Remove user-initiated port sharing entirely. Independent of the admission ceiling above."
  type        = bool
  default     = true
}

# HTH Guide Excerpt: begin terraform
resource "ona_security_policy" "ports" {
  organization_id = var.organization_id
  name            = var.port_policy_name

  spec {
    # REQUIRED even for a ports-only policy — see TRAP 4b. "allow" is the no-op
    # executable posture; if you run pack 2.01, merge these into one policy so
    # this line cannot relax a Veto baseline.
    executables {
      default_effect = "allow"
    }

    # Omitting this block leaves port admission UNRESTRICTED by this policy.
    ports {
      # creator_only is the tightest level the provider exposes. `owner_only` is
      # the deprecated API-side spelling and is not accepted here.
      max_admission_level = var.max_port_admission_level
    }
  }
}

# SINGLETON: at most one ona_organization_policies per organization (import id "current") —
# merge these attributes with any other ona pack you adopt; two resources drift forever.
resource "ona_organization_policies" "port_admission" {
  # Turns the policy above from a stored definition into enforcement.
  security_policy_id = ona_security_policy.ports.id

  # Separate lever: kills the user-initiated port-sharing affordance outright.
  port_sharing_disabled = var.port_sharing_disabled
}
# HTH Guide Excerpt: end terraform

output "ona_port_admission_ceiling" {
  description = "Effective ceiling for user-opened ports under the assigned policy."
  value       = var.max_port_admission_level
}
