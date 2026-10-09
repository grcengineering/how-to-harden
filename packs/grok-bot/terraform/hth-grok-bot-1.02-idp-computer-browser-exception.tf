# =============================================================================
# HTH Pack Contract: v1
#   control: grok-bot-1.2
#   guide:   https://howtoharden.com/guides/grok-bot/#12-scope-the-idp-sign-in-exception-for-the-bots-computer-browser
#   profile: L2
#   mode:    mutating
#   requires: idp="okta": OKTA_ORG_NAME, OKTA_BASE_URL and either OAuth 2.0 (OKTA_API_CLIENT_ID,
#             OKTA_API_PRIVATE_KEY_ID, OKTA_API_PRIVATE_KEY, and
#             OKTA_API_SCOPES=okta.policies.manage,okta.policies.read,okta.apps.read,okta.groups.read;
#             Okta recommends it) or legacy OKTA_API_TOKEN, against an Identity Engine org.
#             Scopes are from the Okta Management API spec 2026.09.2 for the routes these
#             resources and data sources call; confirm them against a plan run.
#             idp="entra": ARM_TENANT_ID, ARM_CLIENT_ID and a credential (ARM_CLIENT_SECRET,
#             ARM_USE_OIDC or ARM_USE_CLI) holding Policy.ReadWrite.ConditionalAccess and
#             Policy.Read.All (service principal) or Conditional Access Administrator (user).
#
# HTH Grok Bot Control 1.2: Scope the IdP Sign-In Exception for the Bot's Computer Browser
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls v8 6.3 | NIST 800-53 IA-2, AC-17, AC-20 | SOC 2 CC6.1 |
#   ISO 27001:2022 A.5.17, A.8.5 | CISA SCuBA MS.AAD.3.1v1, MS.AAD.3.7v1 (labeled
#   compatibility exception, see TRAP 1)
#
# WHAT THIS DOES: Grok Bot's hosted computer runs Linux, is not MDM-enrolled and
# cannot run Okta FastPass, so device-trust rules block members from signing in to
# IdP-provisioned apps from the Bot's browser. xAI's fix is a narrowly scoped
# exception in the IdP. This file encodes that exception for ONE IdP per root
# module (var.idp): an Okta app sign-in policy rule, or an Entra Conditional
# Access policy that starts in report-only. The Cursor and xAI admin planes expose
# no Terraform for this (cursor/cursor 0.8.0 has no Grok Bot resources and the xai
# registry namespace is empty, both checked 2026-10-08); the work is in the IdP.
#
# SOURCES (all fetched 2026-10-08; every argument below appears in these schemas
# and was cross-checked against `terraform providers schema -json` from the pinned
# provider binaries):
#   xAI, Configure identity and access (the steps this file encodes):
#     https://docs.x.ai/grok-bot/identity-and-access
#   okta/okta 7.0.0 resource okta_app_signon_policy_rule (registry v2 provider-doc 13337260):
#     https://registry.terraform.io/providers/okta/okta/7.0.0/docs/resources/app_signon_policy_rule
#   okta/okta 7.0.0 data source okta_app_signon_policy (provider-doc 13337141):
#     https://registry.terraform.io/providers/okta/okta/7.0.0/docs/data-sources/app_signon_policy
#   okta/okta 7.0.0 data source okta_app_sign_on_policy_rule (provider-doc 13337140):
#     https://registry.terraform.io/providers/okta/okta/7.0.0/docs/data-sources/app_sign_on_policy_rule
#   okta/okta 7.0.0 data source okta_everyone_group (provider-doc 13337178, fetched 2026-10-09):
#     https://registry.terraform.io/providers/okta/okta/7.0.0/docs/data-sources/everyone_group
#   Terraform checks ("reports a warning and continues") and custom conditions
#   (a failed postcondition "stops the current operation"), fetched 2026-10-09:
#     https://developer.hashicorp.com/terraform/language/checks
#     https://developer.hashicorp.com/terraform/language/expressions/custom-conditions
#   okta/okta 7.0.0 provider configuration (provider-doc 13337127):
#     https://registry.terraform.io/providers/okta/okta/7.0.0/docs
#   hashicorp/azuread 3.10.0 resource azuread_conditional_access_policy (provider-doc 13798576):
#     https://registry.terraform.io/providers/hashicorp/azuread/3.10.0/docs/resources/conditional_access_policy
#   hashicorp/azuread 3.10.0 provider configuration (provider-doc 13798536):
#     https://registry.terraform.io/providers/hashicorp/azuread/3.10.0/docs
#   Microsoft Learn, Building a Conditional Access policy (how policies combine):
#     https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-conditional-access-policies
#   Microsoft Learn, Conditional Access conditions (device platform warning):
#     https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-conditional-access-conditions
#   Microsoft Learn, report-only mode:
#     https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-conditional-access-report-only
#   Okta Developer, Policies concept (rule evaluation order):
#     https://developer.okta.com/docs/concepts/policies/
#   Okta Admin Management API spec 2026.09.2 (PolicyRule.priority, OS-type enum):
#     https://github.com/okta/okta-management-openapi-spec/blob/master/dist/current/management-minimal.yaml
#
# TRAPS
#  1. THIS RELAXES DEVICE TRUST ON PURPOSE. It admits an unmanaged Linux browser
#     with password plus a second factor. Microsoft, of Entra's device platform
#     condition: it uses "information provided by the device, such as user agent
#     strings" and "Because user agent strings can be modified, this information
#     isn't verified." So in Entra, anyone in the scoped group who holds a phished
#     password and a non-phishing-resistant factor can claim to be that browser.
#     The Okta pages fetched here do not say how Okta detects Other Desktop; treat
#     it as equally claimable until Okta documents otherwise. This conflicts with SCuBA MS.AAD.3.1v1 ("Phishing-resistant MFA SHALL be
#     enforced for all users.") and MS.AAD.3.7v1 ("Managed devices SHOULD be
#     required for authentication."). Record it as a labeled exception, start with
#     a pilot subset of the Cursor-assigned group, and list only the apps Bots open.
#  2. NOT A GROK BOT SIGN-IN CONTROL. xAI: "Only the first change controls Grok
#     Bot sign-in. The second never blocks it, and it does not apply to plugin
#     sign-in". Never list the Cursor app here. A device-aware sign-in policy on
#     the Cursor app still works and gates the member's own device, not the hosted
#     computer (xAI; okta guide 1.12).
#  3. ENTRA HAS NO POLICY PRIORITY, SO THIS POLICY ALONE UNBLOCKS NOTHING. xAI
#     step 3 says "Add a higher-priority policy". Microsoft: "Multiple Conditional
#     Access policies can apply to an individual user at any time. In this case,
#     all applicable policies must be satisfied." An existing compliant-device
#     policy covering these apps still blocks the Bot's browser. What lifts the
#     block is xAI step 8, "On existing compliant-device policies, exclude the
#     group or exclude Linux", and this file does not edit those policies. The two
#     choices widen differently: excluding the group drops the compliant-device
#     grant for those members on every platform, laptops included; excluding Linux
#     drops it for every user whose browser claims to be Linux (see TRAP 1). The
#     same applies to every blocking grant xAI lists (compliant device, hybrid
#     joined device, a phishing-resistant authentication strength, approved client
#     app or app protection). Guide 1.2 Step 2a splits each blocking policy into
#     two copies so the lift covers exactly the group, Linux-claiming clients and
#     the named apps; do that in the console or in your own azuread code.
#  4. THE OKTA RULE IS LIVE ON APPLY. okta_app_signon_policy_rule has no
#     report-only argument (azuread's enabledForReportingButNotEnforced, which the
#     Entra region defaults to, has no Okta equivalent in this resource). Put a
#     pilot group in okta_group_ids first.
#  5. A SHARED OKTA POLICY MEANS EVERY APP ON IT. xAI: "If several apps share one
#     FastPass-on-managed-devices policy, add the Linux rule to the shared policy
#     and scope it by group, or give those apps their own policy." The
#     okta_app_signon_policy data source returns only the policy id and name, so
#     Terraform cannot list the other apps on a policy. This file writes one rule
#     per distinct policy and warns when two listed apps resolve to the same one;
#     it cannot see unlisted apps sharing it. Review the okta_resolved_policies
#     output in the console before apply. The shared-policy test is a Terraform
#     `check`, so it prints a warning and plan/apply still exit 0: xAI permits a
#     shared policy scoped by group, so blocking it would refuse a configuration
#     the vendor sanctions.
#  6. OKTA PRIORITY DIRECTION IS NOT DOCUMENTED IN THE SOURCES ABOVE. The provider
#     doc and the Okta API spec define priority only as "Priority of the rule".
#     Okta's policies concept page says rules are "considered in the order that the
#     rules appear in the rules list" and that the default rule is "always the last
#     rule in the priority order". okta_rule_priority therefore has no default:
#     read the existing rules on each resolved policy, choose a value that puts
#     this rule above the FastPass, managed-device and deny catch-all rules, and
#     confirm the order in the console (xAI step 6). Policies with different rule
#     layouts can need different values: okta_rule_priority_by_policy overrides
#     the value per policy id. The read-back cannot prove the position (it would
#     need every other rule on the policy), so the okta_rule_priorities output
#     reports each rule's priority as Okta stored it, for the console check. The provider doc also warns
#     that concurrent rule writes can hit Okta API concurrency issues and advises
#     explicit depends_on between rules; add it if your root module manages other
#     rules on the same policy.
#  7. "OTHER DESKTOP", NOT LINUX, IN OKTA. xAI: "the computer matches the Other
#     Desktop device platform; there is no Linux checkbox." Okta's own help page
#     does not show that label; os_type OTHER with type DESKTOP comes from the
#     provider doc's examples. Okta's Admin Management API spec 2026.09.2 does list
#     LINUX as an operating-system type. This file uses the value xAI documents.
#     Whether a LINUX condition matches the Bot's browser is undocumented and
#     untested here: check in the Okta System Log during the pilot which platform
#     the Bot's sign-in reports, and whether the console now offers Linux.
#  8. OKTA FACTOR IS "PASSWORD + ANOTHER FACTOR", NOTHING STRONGER. It is encoded
#     with the provider doc's Example 1 (a knowledge constraint of type password,
#     which the doc renders as 'Password + Another factor'). xAI: "Do not require
#     phishing-resistant or hardware-protection factors." Adding possession
#     constraints is stricter than the vendor guidance and untested by the vendor.
#     Device state Any means device_is_registered, device_is_managed and
#     device_assurances_included stay unset (xAI step 4: "Do not require
#     Registered, Managed, or a device assurance policy that depends on FastPass").
#  9. THE ENTRA PASSKEY STRENGTH IS OPTIONAL AND HAS A PREREQUISITE. xAI (Entra
#     only): "use an authentication strength a synced passkey can satisfy, and test
#     sign-in from the computer before enforcing it." The passkey reaches the
#     computer through a Team Setup script, and "Team Setup is Enterprise only".
#     Setting entra_authentication_strength_object_id replaces the "mfa" grant with
#     that strength, prefixed /policies/authenticationStrengthPolicies/ as the
#     azuread doc requires for a hard-coded ID.
# 10. client_app_types IS REQUIRED BY THE SCHEMA AND xAI DOES NOT NAME ONE.
#     Microsoft: "By default, all newly created Conditional Access policies apply to
#     all client app types even if the client apps condition isn't configured."
#     This file sets ["browser"], an HTH narrowing to the computer browser xAI
#     describes. Non-browser clients on the computer do not match this exception
#     and stay under your other policies.
# 11. "All" IS REFUSED. entra_application_ids must be application IDs (GUIDs); the
#     keywords the schema also accepts (All, None, Office365) are rejected. This is
#     an HTH value, stricter than xAI's "Select All resources only if you accept
#     that scope". Okta takes explicit app IDs the same way.
# 12. DELETE THE OTHER IdP's PROVIDER. var.idp gates resources, not providers:
#     Terraform configures every declared provider on every run. Measured
#     2026-10-08 with Terraform 1.16.4: a plan with idp = "entra" and no Okta
#     credentials fails on provider "okta" with "no Okta credentials provided".
#     In your root module keep only your IdP's required_providers entry and
#     provider block, plus that IdP's region. A module may hold only one
#     required_providers block, which is why both share the providers region.
# 13. THE READ SIDE IS PARTIAL, AND IT FAILS THE RUN. Okta: the
#     okta_app_sign_on_policy_rule data source reads a rule back by ID with its
#     people, platform and device conditions and its access, but NOT its factor
#     mode or constraints. On a rule made in the console, confirm "Password +
#     Another factor" in the console. The narrowness asserts are data-source
#     POSTCONDITIONS, not `check` blocks: HashiCorp says a failed check "reports a
#     warning and continues", so a CI job reading the exit code would record a
#     wide rule as a pass, while a failed postcondition is an error that "stops
#     the current operation" (measured 2026-10-09 on Terraform 1.16.5: a failing
#     check leaves apply at exit 0, a failing postcondition exits 1). Timing: a rule fed through
#     okta_verify_rules is read at plan time, so a non-narrow one fails
#     `terraform plan`. A rule this file creates has no ID until apply, so it is
#     read back during apply and a non-narrow one fails the apply AFTER Okta has
#     written it; fix or destroy the rule, then re-run. Entra: azuread 3.10.0 has
#     no Conditional Access data source, so verification is terraform plan drift
#     plus the Entra sign-in logs. In report-only, Microsoft: "the system
#     evaluates policies in report-only mode but doesn't enforce them."
# 14. "SCOPED TO A GROUP" MEANS A NAMED GROUP, NOT EVERYONE. A rule whose only
#     group is Okta's built-in Everyone group has a group condition and still
#     reaches every user. HTH requires the Cursor-assigned group or a pilot subset
#     of it (xAI: "The Cursor-assigned group works if you do not want the rule
#     company-wide"). The okta_everyone_group data source supplies the Everyone
#     ID: a precondition refuses it in okta_group_ids, and the read-back fails any
#     rule that includes it or a group outside okta_approved_group_ids (default:
#     okta_group_ids). Listing individual users under people.users narrows a rule
#     (Okta's IF conditions are ANDed), so it is not refused.
# =============================================================================

variable "idp" {
  description = "The identity provider this root module manages: \"okta\" or \"entra\". Each region below is gated on it."
  type        = string

  validation {
    condition     = contains(["okta", "entra"], var.idp)
    error_message = "idp must be \"okta\" or \"entra\"."
  }
}

# ── Okta inputs ─────────────────────────────────────────────────────────────

variable "okta_app_ids" {
  description = "Okta app IDs of the IdP-provisioned apps the Bot opens in its computer browser. Never the Cursor app: this rule does not gate Grok Bot sign-in (TRAP 2)."
  type        = set(string)
  default     = []

  validation {
    condition     = var.idp != "okta" || length(var.okta_app_ids) > 0
    error_message = "List at least one Okta app ID when idp = \"okta\"."
  }
}

variable "okta_group_ids" {
  description = "Okta group IDs for the rule's IF condition: the Cursor-assigned group, or a pilot subset of it while you roll out (TRAP 4)."
  type        = set(string)
  default     = []

  validation {
    condition     = var.idp != "okta" || length(var.okta_group_ids) > 0
    error_message = "Scope the rule to at least one group when idp = \"okta\". xAI scopes it to the Cursor-assigned group so it is not company-wide."
  }
}

variable "okta_approved_group_ids" {
  description = "Groups a Grok Bot computer rule may include, checked on every rule read back (TRAP 14). Defaults to okta_group_ids."
  type        = set(string)
  default     = null
}

variable "okta_rule_priority" {
  description = "Rule priority. No default on purpose: choose a value that places this rule above the FastPass, managed-device and deny catch-all rules on each resolved policy, then confirm the order in the console (TRAP 6)."
  type        = number
  default     = null

  validation {
    condition     = var.idp != "okta" || var.okta_rule_priority != null
    error_message = "Set okta_rule_priority when idp = \"okta\" (TRAP 6)."
  }
}

variable "okta_rule_priority_by_policy" {
  description = "Per-policy overrides of okta_rule_priority, keyed by policy ID, for policies whose rule layouts differ (TRAP 6)."
  type        = map(number)
  default     = {}
}

variable "okta_rule_name" {
  description = "Rule name. The default is the example name xAI uses, so the rule is easy to find later."
  type        = string
  default     = "Grok Bot computer (Linux)"
}

variable "okta_verify_rules" {
  description = "Extra rules to read back and check, such as one created in the console: { label = { policy_id = \"...\", rule_id = \"...\" } }."
  type = map(object({
    policy_id = string
    rule_id   = string
  }))
  default = {}
}

# ── Entra inputs ────────────────────────────────────────────────────────────

variable "entra_group_object_ids" {
  description = "Object IDs of the groups the policy targets: the Cursor-assigned group, or a pilot subset of it."
  type        = set(string)
  default     = []

  validation {
    condition     = var.idp != "entra" || length(var.entra_group_object_ids) > 0
    error_message = "List at least one group object ID when idp = \"entra\"."
  }
}

variable "entra_application_ids" {
  description = "Application IDs of the apps the Bot must open in its computer browser. Never All (TRAP 11) and never the Cursor app (TRAP 2)."
  type        = set(string)
  default     = []

  validation {
    condition     = var.idp != "entra" || length(var.entra_application_ids) > 0
    error_message = "List at least one application ID when idp = \"entra\"."
  }

  validation {
    condition = alltrue([
      for a in var.entra_application_ids :
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", a))
    ])
    error_message = "entra_application_ids must be application IDs (GUIDs). Keywords such as All or Office365 widen the exception beyond the apps the Bot opens (TRAP 11)."
  }
}

variable "entra_policy_display_name" {
  description = "Display name of the Conditional Access policy."
  type        = string
  default     = "HTH: Grok Bot computer browser (Linux) exception"
}

variable "entra_policy_state" {
  description = "enabledForReportingButNotEnforced (report-only, the default) until sign-in logs show the policy matching only Bot sessions; then enabled."
  type        = string
  default     = "enabledForReportingButNotEnforced"

  validation {
    condition     = contains(["enabled", "disabled", "enabledForReportingButNotEnforced"], var.entra_policy_state)
    error_message = "entra_policy_state must be enabled, disabled or enabledForReportingButNotEnforced."
  }
}

variable "entra_authentication_strength_object_id" {
  description = "Optional object ID (GUID) of an authentication strength that a synced passkey can satisfy. When set it replaces the mfa grant (TRAP 9)."
  type        = string
  default     = null

  validation {
    condition = (
      var.entra_authentication_strength_object_id == null ||
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.entra_authentication_strength_object_id))
    )
    error_message = "entra_authentication_strength_object_id must be a GUID; the /policies/authenticationStrengthPolicies/ prefix is added for you."
  }
}

# HTH Guide Excerpt: begin providers
# Both IdPs are declared here because a module may hold only one
# required_providers block. Delete the entry and provider block your root module
# does not use: Terraform configures every declared provider even when var.idp
# leaves it no resources (TRAP 12).
terraform {
  # check blocks and cross-variable validation need Terraform 1.9 or later.
  required_version = ">= 1.9"

  required_providers {
    okta = {
      source = "okta/okta"
      # Arguments transcribed from 7.0.0. Review the schema before raising the pin.
      version = "7.0.0"
    }
    azuread = {
      source = "hashicorp/azuread"
      # Arguments transcribed from 3.10.0. Review the schema before raising the pin.
      version = "3.10.0"
    }
  }
}

# Reads OKTA_ORG_NAME, OKTA_BASE_URL and the OAuth 2.0 or API-token credential
# from the environment. Identity Engine only.
provider "okta" {}

# Reads ARM_TENANT_ID, ARM_CLIENT_ID and a credential from the environment.
provider "azuread" {}
# HTH Guide Excerpt: end providers

# HTH Guide Excerpt: begin okta-computer-browser-rule
# Resolve the app sign-in (authentication) policy behind each app the Bot opens.
# xAI: "open the policy attached to the app".
data "okta_app_signon_policy" "bot_app" {
  for_each = var.idp == "okta" ? var.okta_app_ids : toset([])
  app_id   = each.value
}

# The built-in Everyone group, which a "narrow" rule must never include (TRAP 14).
data "okta_everyone_group" "this" {
  count = var.idp == "okta" ? 1 : 0
}

locals {
  # One rule per distinct policy. Apps that share a policy share its rules (TRAP 5).
  okta_policy_ids        = toset([for p in data.okta_app_signon_policy.bot_app : p.id])
  okta_everyone_group_id = one(data.okta_everyone_group.this[*].id)
  okta_approved_groups   = coalesce(var.okta_approved_group_ids, var.okta_group_ids)
}

resource "okta_app_signon_policy_rule" "grok_bot_computer" {
  for_each  = local.okta_policy_ids
  policy_id = each.value
  name      = var.okta_rule_name

  # Above the FastPass, managed-device and deny catch-all rules (TRAP 6).
  priority = lookup(var.okta_rule_priority_by_policy, each.value, var.okta_rule_priority)

  lifecycle {
    precondition {
      condition     = !contains(var.okta_group_ids, local.okta_everyone_group_id)
      error_message = "okta_group_ids includes Okta's Everyone group, which makes the exception company-wide. Use the Cursor-assigned group or a pilot subset (TRAP 14)."
    }
  }

  # IF: the Cursor-assigned group, or a pilot subset of it ...
  groups_included = var.okta_group_ids

  # ... on Device platform = Other Desktop ...
  platform_include {
    os_type = "OTHER"
    type    = "DESKTOP"
  }

  # ... with Device state = Any: device_is_registered, device_is_managed and
  # device_assurances_included are deliberately unset (TRAP 8).

  # THEN: Allowed after successful authentication, with Password + Another factor.
  # No phishing-resistant or hardware-protection constraint (xAI step 5).
  access      = "ALLOW"
  type        = "ASSURANCE"
  factor_mode = "2FA"
  constraints = [
    jsonencode({
      knowledge = {
        types = ["password"]
      }
    })
  ]
}
# HTH Guide Excerpt: end okta-computer-browser-rule

# HTH Guide Excerpt: begin okta-verify-computer-browser-rule
# Read each rule back from Okta: the rules this file manages, plus any rule an
# admin made in the console (var.okta_verify_rules). The data source returns
# conditions and access, not factor mode or constraints (TRAP 13). The
# narrowness asserts are postconditions, so a wide rule FAILS plan or apply; a
# `check` block would only warn.
locals {
  okta_rules_to_verify = var.idp != "okta" ? {} : merge(
    {
      for pid, r in okta_app_signon_policy_rule.grok_bot_computer :
      "managed-${pid}" => { policy_id = r.policy_id, rule_id = r.id }
    },
    var.okta_verify_rules,
  )
}

data "okta_app_sign_on_policy_rule" "grok_bot_computer" {
  for_each  = local.okta_rules_to_verify
  id        = each.value.rule_id
  policy_id = each.value.policy_id

  lifecycle {
    # A named group, never Everyone, and only approved groups (TRAP 14).
    postcondition {
      condition = (
        length(try(self.conditions.people.groups.include, [])) > 0 &&
        !contains(try(self.conditions.people.groups.include, []), local.okta_everyone_group_id) &&
        alltrue([
          for g in try(self.conditions.people.groups.include, []) :
          contains(local.okta_approved_groups, g)
        ])
      )
      error_message = "A Grok Bot computer rule has no group condition, includes the Everyone group, or includes a group outside okta_approved_group_ids, so it is wider than the Cursor-assigned group (TRAP 14)."
    }

    postcondition {
      condition = length(try(self.conditions.platform.include, [])) > 0 && alltrue([
        for p in try(self.conditions.platform.include, []) :
        p.type == "DESKTOP" && try(p.os.type, "") == "OTHER"
      ])
      error_message = "A Grok Bot computer rule matches a platform other than Other Desktop, or carries no platform condition at all."
    }

    postcondition {
      condition = (
        !coalesce(try(self.conditions.device.registered, null), false) &&
        !coalesce(try(self.conditions.device.managed, null), false) &&
        length(coalesce(try(self.conditions.device.assurance.include, null), [])) == 0
      )
      error_message = "A Grok Bot computer rule requires a registered or managed device or a device assurance policy, which the Bot's computer cannot satisfy (xAI step 4)."
    }

    postcondition {
      condition = (
        try(self.actions.app_sign_on.access, "") == "ALLOW" &&
        try(self.actions.app_sign_on.verification_method.type, "") == "ASSURANCE"
      )
      error_message = "A Grok Bot computer rule is not 'Allowed after successful authentication' with an assurance verification method. Check its factor setting in the console (TRAP 13)."
    }
  }
}

# A warning only: xAI permits a shared policy scoped by group (TRAP 5).
check "okta_listed_apps_do_not_share_a_policy" {
  assert {
    condition     = length(local.okta_policy_ids) == length(data.okta_app_signon_policy.bot_app)
    error_message = "Two or more apps in okta_app_ids share one app sign-in policy, so the rule covers every app on that policy. Give the Bot's apps their own policy if that is wider than intended (TRAP 5)."
  }
}
# HTH Guide Excerpt: end okta-verify-computer-browser-rule

# HTH Guide Excerpt: begin entra-computer-browser-policy
# This policy only states what the Bot's browser must satisfy. Entra applies
# every matching policy, so your existing compliant-device, hybrid-join,
# phishing-resistant-strength and approved-client policies still block it until
# you lift them for exactly the group, Linux and these apps (guide 1.2 Step 2a;
# xAI step 8; TRAP 3). This file does not edit those policies.
resource "azuread_conditional_access_policy" "grok_bot_computer_browser" {
  count        = var.idp == "entra" ? 1 : 0
  display_name = var.entra_policy_display_name

  # Report-only by default (xAI step 7). Switch to "enabled" after review.
  state = var.entra_policy_state

  conditions {
    # HTH narrowing to the computer browser (TRAP 10).
    client_app_types = ["browser"]

    # Users: the Cursor-assigned group, or a pilot subset of it.
    users {
      included_groups = sort(tolist(var.entra_group_object_ids))
    }

    # Target resources: only the apps the Bot must open, never All (TRAP 11).
    applications {
      included_applications = sort(tolist(var.entra_application_ids))
    }

    # Device platforms: include Linux, exclude Windows and macOS (xAI step 5).
    platforms {
      included_platforms = ["linux"]
      excluded_platforms = ["windows", "macOS"]
    }
  }

  # Grant: Require multifactor authentication only (xAI step 6), or the
  # passkey-capable authentication strength xAI suggests for Entra (TRAP 9).
  grant_controls {
    operator          = "OR"
    built_in_controls = var.entra_authentication_strength_object_id == null ? ["mfa"] : null
    authentication_strength_policy_id = (
      var.entra_authentication_strength_object_id == null ? null :
      "/policies/authenticationStrengthPolicies/${var.entra_authentication_strength_object_id}"
    )
  }
}
# HTH Guide Excerpt: end entra-computer-browser-policy

output "okta_resolved_policies" {
  description = "Each listed Okta app's sign-in policy. Two apps on one policy share the rule; so does every unlisted app on it (TRAP 5)."
  value = {
    for app_id, p in data.okta_app_signon_policy.bot_app :
    app_id => { policy_id = p.id, policy_name = p.name }
  }
}

output "okta_rule_ids" {
  description = "Rule ID per policy. Feed a console-made rule to okta_verify_rules to check it the same way."
  value       = { for pid, r in okta_app_signon_policy_rule.grok_bot_computer : pid => r.id }
}

output "okta_rule_priorities" {
  description = "Each read-back rule's priority as Okta stored it. Confirm in the console that it sits above the FastPass, managed-device and deny catch-all rules (TRAP 6)."
  value       = { for k, r in data.okta_app_sign_on_policy_rule.grok_bot_computer : k => r.priority }
}

output "entra_policy_id" {
  description = "ID of the Conditional Access policy, for reviewing its report-only results in the sign-in logs."
  value       = one(azuread_conditional_access_policy.grok_bot_computer_browser[*].id)
}
