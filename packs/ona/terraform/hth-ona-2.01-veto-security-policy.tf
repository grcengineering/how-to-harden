# =============================================================================
# HTH Pack Contract: v1
#   control: ona-2.1
#   guide:   https://howtoharden.com/guides/ona/#21-enforce-an-executable-policy-with-veto
#   profile: L2
#   mode:    mutating
#   requires: ONA_TOKEN(read-write PAT)
#
# HTH Ona Control 2.1: Enforce an Executable Policy with Veto
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 2.5, 2.7 | NIST 800-53 CM-7, SI-3 | NIST AI RMF MANAGE-2.3
# Source: https://howtoharden.com/guides/ona/#21-enforce-an-executable-policy-with-veto
#
# PROVIDER BLOCK LIVES IN hth-ona-1.01-configure-sso.tf.
#
# Transcribed from registry docs fetched 2026-08-19:
#   https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/resources/security_policy        (doc 13236811)
#   https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/resources/organization_policies  (doc 13236800)
#   https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/data-sources/security_policies (doc 13236829)
# all for provider-version 105656 = 0.4.0-beta.1.
#
# SINGLETON — merge these attributes into ONE ona_organization_policies resource
# if you adopt more than one pack; two resources managing the same object drift
# forever.
#
# WHY TERRAFORM FOR THIS CONTROL: Veto is a two-object control — a SecurityPolicy
# definition plus the org-policy assignment that activates it. Terraform is the
# only surface that keeps those two in one plan, so the failure mode below cannot
# hide.
#
# TRAPS
#  1. A CREATED POLICY IS INERT UNTIL ASSIGNED. Verbatim from the API reference:
#     "Creation stores an inactive definition; assigning it as the organization
#     default validates materializability." ona_security_policy on its own
#     enforces NOTHING. The security_policy_id assignment below is the half that
#     turns it on, and applying only the first resource produces a clean plan and
#     zero enforcement.
#  2. THE SAFELIST IS SERVER-OWNED AND INVISIBLE HERE. The API's veto policy
#     carries an output-only, server-populated safelist of executables that
#     "cannot be blocked by the denylist… Ignored on update requests." The
#     Terraform schema does not expose it at all. A rule that blocks a safelisted
#     binary applies cleanly and silently does nothing — test enforcement in an
#     environment, do not infer it from a green apply.
#  3. TWO COEXISTING VETO SURFACES WITH DIFFERENT ENUMS. SecurityPolicy uses
#     allow/block/audit (this pack). The inline organization-policy veto path uses
#     KERNEL_CONTROLS_ACTION_BLOCK/AUDIT. They are different spellings of the same
#     idea; do not mix them or copy enum values between them.
#  4. `spec` IS A BLOCK, NOT AN ATTRIBUTE. Write `spec { executables { ... } }`
#     with no `=`. Attribute syntax (`spec = {}`) fails validation.
#  5. default_effect = "block" IS A DENY-ALL. Everything the environment needs —
#     shells, package managers, language runtimes, the agent's own tooling — must
#     then be listed as an allow rule. Start at "allow" with audit rules, read the
#     audit trail, and only then tighten. Blocking blind breaks every environment
#     at once.
#  6. organization_id IS REQUIRED and changing it REPLACES the policy. Replacing a
#     policy that is currently assigned as the org default means a window with no
#     policy assigned.
#  7. DESTROY IS NOT DELETE for ona_organization_policies: it restores the
#     server-defined policy configuration captured before Terraform took over,
#     which un-assigns this policy.
#  8. `dynamic "rule"` CRASHES THIS PROVIDER AT VALIDATE — RULES MUST BE STATIC.
#     Measured against 0.4.0-beta.1 on Terraform 1.14 (linux/amd64):
#       Error: Value Conversion Error … Received unknown value, however the
#       target type cannot handle unknown values.
#       Path: spec.executables.rule
#       Target Type: []security.ExecutableRuleModel
#       Suggested Type: basetypes.ListValue
#     The provider models the rule list as a plain Go slice that cannot carry an
#     unknown, and a dynamic block is unknown until expansion; Terraform's own
#     message says "This is always an error in the provider." Write literal `rule`
#     blocks, as below. Do not drive them from a variable, a for_each, or a
#     dynamic block on this provider version.
#  9. IF YOU ALSO ADOPT PACK 3.01, USE ONE ona_security_policy, NOT TWO. One
#     policy carries both `executables` and `ports` inside a single `spec`. Two
#     policies means only the assigned one enforces and the other is decoration.
# =============================================================================

variable "organization_id" {
  description = "Ona organization ID that owns the security policy. Get it from OrganizationService/GetAuthenticatedIdentity or the console URL."
  type        = string
}

variable "veto_policy_name" {
  description = "Security policy name shown in Ona. 1-80 characters."
  type        = string
  default     = "hth-veto-baseline"
}

variable "veto_default_effect" {
  description = "Default effect for executables not matched by a rule. One of allow, block, audit. Start at allow."
  type        = string
  default     = "allow"

  validation {
    condition     = contains(["allow", "block", "audit"], var.veto_default_effect)
    error_message = "veto_default_effect must be one of: allow, block, audit."
  }
}

# NOTE: there is deliberately no `veto_rules` variable. Rules must be literal
# blocks — see TRAP 8. Add, remove, or re-effect a rule by editing the resource.

# HTH Guide Excerpt: begin terraform
resource "ona_security_policy" "veto" {
  organization_id = var.organization_id
  name            = var.veto_policy_name

  # `spec` is a BLOCK. No `=`.
  spec {
    executables {
      # Effect applied to anything no rule matches.
      default_effect = var.veto_default_effect

      # `rule` is a repeatable BLOCK, one per executable path, and it must be
      # LITERAL — a dynamic block makes the provider fail with a Value Conversion
      # Error (TRAP 8).
      #
      # Reverse-shell and arbitrary-egress tooling: audit first, then flip these
      # to "block" once the audit trail proves nothing legitimate invokes them.
      rule {
        path   = "/usr/bin/nc"
        effect = "audit"
      }

      rule {
        path   = "/usr/bin/ncat"
        effect = "audit"
      }

      rule {
        path   = "/usr/bin/socat"
        effect = "audit"
      }

      # Credential-adjacent tooling an agent has no reason to invoke.
      rule {
        path   = "/usr/bin/ssh-keygen"
        effect = "audit"
      }
    }
  }
}

# WITHOUT THIS, THE POLICY ABOVE ENFORCES NOTHING. Assigning it as the
# organization default is what materializes it for newly created environments.
# SINGLETON: at most one ona_organization_policies per organization (import id "current") —
# merge these attributes with any other ona pack you adopt; two resources drift forever.
resource "ona_organization_policies" "veto_default" {
  security_policy_id = ona_security_policy.veto.id
}
# HTH Guide Excerpt: end terraform

# HTH Guide Excerpt: begin verify
# Standing inventory of every security policy in the org. Use it to catch a
# second, console-created policy that someone assigned instead of this one.
data "ona_security_policies" "all" {
  organization_id = var.organization_id
}

output "ona_security_policy_names" {
  description = "Every security policy defined in the organization. More than one is fine; only the assigned one enforces."
  value       = [for p in data.ona_security_policies.all.policies : p.name]
}

output "ona_assigned_security_policy_id" {
  description = "The policy ID actually assigned as the organization default. This is the enforcing one."
  value       = ona_organization_policies.veto_default.security_policy_id
}
# HTH Guide Excerpt: end verify
