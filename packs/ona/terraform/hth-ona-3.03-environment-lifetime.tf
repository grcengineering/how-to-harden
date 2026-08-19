# =============================================================================
# HTH Pack Contract: v1
#   control: ona-3.3
#   guide:   https://howtoharden.com/guides/ona/#33-enforce-environment-lifetime-timeout-and-retention
#   profile: L2
#   mode:    mutating
#   requires: ONA_TOKEN(read-write PAT)
#
# HTH Ona Control 3.3: Enforce Environment Lifetime, Timeout, and Retention
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 4.1 | NIST 800-53 CM-6, AC-12
# Source: https://howtoharden.com/guides/ona/#33-enforce-environment-lifetime-timeout-and-retention
#
# PROVIDER BLOCK LIVES IN hth-ona-1.01-configure-sso.tf.
#
# Transcribed from https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/resources/organization_policies
# (registry v2 provider-doc 13236800, provider-version 105656 = 0.4.0-beta.1).
# Every duration format and bound quoted below is verbatim from that schema.
#
# SINGLETON — merge these attributes into ONE ona_organization_policies resource
# if you adopt more than one pack; two resources managing the same object drift
# forever.
#
# WHY TERRAFORM FOR THIS CONTROL: four coupled durations with three different
# unit rules and an inverted zero. Getting them right once and keeping them right
# is a version-control problem, not a console problem.
#
# TRAPS
#  1. ZERO MEANS NO LIMIT — THE INVERSION THAT BREAKS HARDENING SCRIPTS.
#       maximum_environment_lifetime       = "0s"  -> NO MAXIMUM (weaker)
#       maximum_environment_timeout        = "0s"  -> NO LIMIT   (weaker)
#       delete_archived_environments_after = "0s"  -> NEVER DELETE (weaker)
#     A script that "zeroes out" these fields to be safe WEAKENS the organization.
#     None of the defaults below is "0s" for that reason.
#  2. VALUES ARE GO DURATION STRINGS, NOT SECONDS AND NOT MINUTES-AS-NUMBERS.
#     Write "30m", "24h", "720h". A bare number fails.
#  3. archive_environments_after IS WHOLE DAYS ONLY. Verbatim: "Must be a whole
#     number of days between 24h and 720h." The API enforces a CEL constraint
#     (int(this) % int(duration('86400s')) == 0), so 168h is accepted and
#     100000s is rejected. Express it as a multiple of 24h.
#  4. BOUNDS, VERBATIM FROM THE SCHEMA:
#       maximum_environment_lifetime       max 4320h; "0s" = no maximum
#       maximum_environment_timeout        non-zero values must be >= "30m"; "0s" = no limit
#       archive_environments_after         whole days, 24h..720h
#       delete_archived_environments_after max 672h; "0s" = no automatic deletion
#  5. THE STRICT-ENFORCEMENT TOGGLE IS NOT IN THIS PROVIDER. The API carries
#     maximumEnvironmentLifetimeStrict ("controls whether environments past their
#     lockdown_at may be restarted"), but provider 0.4.0-beta.1 exposes NO
#     corresponding attribute — grep the schema and it is absent. Without strict
#     enforcement the lifetime policy is a WARNING and expired environments can be
#     restarted indefinitely, which is the exact failure the control names. Set it
#     via the console (Settings -> Organization -> Policies) or the
#     UpdateOrganizationPolicies API and re-check it after every provider upgrade.
#  6. archive_environments_after IS ENTERPRISE-ONLY per the API reference. On a
#     non-enterprise plan the apply fails with a failed_precondition rather than a
#     schema error; that is a plan gate, not a bug in this pack.
#  7. DELETION IS IRREVERSIBLE. delete_archived_environments_after destroys the
#     environment and everything in it. Shorten it deliberately, with the team's
#     agreement, not as a default tightening pass.
# =============================================================================

variable "maximum_environment_lifetime" {
  description = "How long environments may be reused. Go duration string; max 4320h. '0s' MEANS NO MAXIMUM (weaker), so do not use it to 'reset'."
  type        = string
  default     = "168h"
}

variable "maximum_environment_timeout" {
  description = "Ceiling on the auto-stop timeout. Go duration string; non-zero values must be >= 30m. '0s' MEANS NO LIMIT (weaker)."
  type        = string
  default     = "30m"
}

variable "archive_environments_after" {
  description = "How long a stopped environment stays inactive before archival. WHOLE DAYS ONLY, between 24h and 720h. Enterprise-only on the API side."
  type        = string
  default     = "168h"

  validation {
    condition     = can(regex("^(24|48|72|96|120|144|168|192|216|240|264|288|312|336|360|384|408|432|456|480|504|528|552|576|600|624|648|672|696|720)h$", var.archive_environments_after))
    error_message = "archive_environments_after must be a whole number of days expressed in hours between 24h and 720h (a multiple of 24h)."
  }
}

variable "delete_archived_environments_after" {
  description = "How long archived environments are kept before automatic deletion. Max 672h. '0s' DISABLES automatic deletion (weaker). Deletion is irreversible."
  type        = string
  default     = "672h"
}

# HTH Guide Excerpt: begin terraform
# SINGLETON: at most one ona_organization_policies per organization (import id "current") —
# merge these attributes with any other ona pack you adopt; two resources drift forever.
resource "ona_organization_policies" "environment_lifetime" {
  # Bound how long an environment may be reused at all. Not "0s" — that is the
  # no-maximum value.
  maximum_environment_lifetime = var.maximum_environment_lifetime

  # Ceiling on idle credentialed compute. Non-zero values must be at least 30m.
  maximum_environment_timeout = var.maximum_environment_timeout

  # Whole days only, 24h-720h. Enterprise-only on the API side.
  archive_environments_after = var.archive_environments_after

  # Irreversible once it fires. Max 672h; "0s" would mean never delete.
  delete_archived_environments_after = var.delete_archived_environments_after

  # NOT AVAILABLE HERE: the strict-enforcement flag
  # (maximumEnvironmentLifetimeStrict in the API) has no attribute in provider
  # 0.4.0-beta.1. Without it the lifetime above is advisory. Set it in the console
  # or via UpdateOrganizationPolicies and re-verify after each provider upgrade.
}
# HTH Guide Excerpt: end terraform

output "ona_environment_time_bounds" {
  description = "The four time bounds actually in force. Any '0s' here means that bound is OFF."
  value = {
    maximum_environment_lifetime       = ona_organization_policies.environment_lifetime.maximum_environment_lifetime
    maximum_environment_timeout        = ona_organization_policies.environment_lifetime.maximum_environment_timeout
    archive_environments_after         = ona_organization_policies.environment_lifetime.archive_environments_after
    delete_archived_environments_after = ona_organization_policies.environment_lifetime.delete_archived_environments_after
  }
}
