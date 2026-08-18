# =============================================================================
# HTH Buildkite Control 3.11: Govern Inbound OIDC Trust
# Profile Level: L3 (Run)
# Frameworks: CIS 5.4 | NIST AC-3 (Access Enforcement), IA-9 (Service
#             Identification and Authentication), SR-3 (Supply Chain Controls)
# Source: https://howtoharden.com/guides/buildkite/#311-govern-inbound-oidc-trust
#
# THE OTHER DIRECTION OF TRUST. Control 3.6 governs Buildkite authenticating
# OUTWARD: a pipeline presents an OIDC token to AWS or GCP and receives cloud
# credentials. This governs the INBOUND leg - which pipelines may present a token
# TO Buildkite's own products and receive publish authority over a package
# registry or upload authority over a test suite. Opposite directions, opposite
# blast radii. A bad outbound policy leaks your cloud; a bad inbound policy lets
# an arbitrary build publish the artifact your consumers install. Only the second
# is a supply-chain event, and the issuer trusted here is your own agent fleet,
# not your IdP - pointing `iss` at Okta is the conceptual error this pack exists
# to prevent.
#
# WHY terraform/. Both surfaces are provider resources whose oidc_policy is a
# plain string holding YAML, so the policy is diffable, reviewable and revertable
# in the same plan as the resource it protects. The alternative is a textarea in
# Settings > OIDC Policy with no history and no review.
#
# -- TRAP 1: THE REQUIRED ARGUMENTS --------------------------------------------
# Neither resource is "a name plus an oidc_policy". Verified against
# buildkite/buildkite v1.38.0 (`tofu providers schema -json`):
#   buildkite_registry    REQUIRED  name . ecosystem . team_ids (list of string)
#   buildkite_test_suite  REQUIRED  name . default_branch . team_owner_id
# HCL missing any of them does not plan.
#
# -- TRAP 2: team_ids ARE UUIDs, team_owner_id IS A GRAPHQL ID -----------------
# Two sibling resources, two identifier namespaces, no error that says so.
# Provider docs: registry team_ids is "The team UUIDs that have access to the
# registry"; test_suite team_owner_id is "The GraphQL ID of the team to mark as
# the owner/admin". buildkite_team exposes BOTH `uuid` and `id`, so the wrong one
# is always within reach - and pack 2.1's `team_ids` output emits GraphQL IDs,
# which are correct for team_owner_id and wrong for a registry. The variable is
# named team_uuids so the distinction survives being copied into tfvars.
#
# -- TRAP 3: OMITTING oidc_policy IS NOT "NO POLICY" ---------------------------
# The two attributes have different schema shapes and therefore different
# omission semantics:
#   buildkite_test_suite.oidc_policy  Optional + COMPUTED. Provider docs: "If
#     omitted, the policy is left unmanaged by Terraform; set it to an empty
#     string to remove an existing policy." A policy typed into the console
#     SURVIVES an apply that does not mention it, and no drift is reported.
#   buildkite_registry.oidc_policy    Optional, NOT computed.
# So you cannot prove "this suite trusts nobody" by reading the HCL. Both
# resources below always assert oidc_policy - a policy, or "" for an empty
# statement list - so absence is a declaration rather than an omission.
#
# -- TRAP 4: THE TWO PRODUCTS DO NOT SHARE A SCOPE VOCABULARY ------------------
# A policy copied from a registry to a suite is valid YAML, plans cleanly, and
# authorises nothing. Per vendor docs the sets are disjoint:
#   Registry     read_packages . write_packages . delete_packages
#                ("the only scopes supported by Registry OIDC policies")
#   Test suite   read_suites . write_uploads  (+ read_test_plan / write_test_plan,
#                needed only when using the bktec CLI)
# Each variable validates its own vocabulary; the resources below re-assert it so
# the failure names the registry or suite rather than the variable.
#
# -- TRAP 5: FIRST MATCH WINS, SO STATEMENT ORDER IS A SECURITY CONTROL --------
# Vendor docs: "the token is accepted by the first matching statement in the
# policy, and no further statements are evaluated. This affects the use of
# scopes, as only the scopes defined in the first matching statement are
# granted." A broad read-only statement placed FIRST silently caps a narrower
# write statement after it: the release pipeline matches statement 1, is granted
# read_packages, and its publish fails with a permission error pointing at the
# wrong statement. List order in tfvars IS policy order; enforced below.
#
# -- TRAP 6: organization_slug IS NOT A CONSTRAINT ----------------------------
# Every pipeline in your organization asserts the same organization_slug, so a
# statement claiming only organization_slug trusts your entire build fleet. Only
# pipeline_slug (Buildkite agent) or repository (GitHub Actions) identifies the
# caller. A write grant without one of those is a standing publish authority over
# your artifacts for any build in the org, and the plan refuses it.
#
# -- TRAP 7: THE MATCHERS ARE GLOBS, NOT REGEXES, AND CAN BE UNSATISFIABLE ----
# Vendor-documented matcher semantics, all five supported by var.*_oidc_policies:
#   equals / not_equals  scalar exact comparison
#   any_of / none_of     wire names `in` / `not_in`; renamed in the variable
#                        because `in` collides with HCL's for-expression keyword
#   matches              "List of glob strings OR a single glob string ... only
#                        applied when the claim value is a string, and is ignored
#                        otherwise" - glob (* and ?), NOT a regular expression
# All matchers in one rule are ANDed, which the docs warn makes some combinations
# permanently unsatisfiable (equals: main together with not_equals: main rejects
# every token). Terraform cannot detect that; the exact-vs-negation contradiction
# is checked below, but a contradictory glob pair is on you.
# Also documented: "if a claim rule in its entirety is a scalar, it is treated as
# if it were a rule with the equals matcher" - this pack always emits explicit
# matcher form instead, which is valid in every position.
#
# -- TRAP 8: ONLY THREE ISSUERS EXIST, AND A TYPO PLANS CLEANLY ----------------
# iss is a free string to Terraform and to YAML. It is not free to Buildkite -
# vendor docs list exactly three supported issuers:
#   https://agent.buildkite.com                   (Buildkite agent)
#   https://token.actions.githubusercontent.com   (GitHub Actions)
#   https://oidc.circleci.com/org/$ORG            (CircleCI, per-organization)
# Anything else rejects every token at runtime behind a green plan. The variable
# only checks the issuer is non-empty; the allowlist is enforced here.
#
# -- TRAP 9: ecosystem AND team_ids ARE FORCE-NEW ------------------------------
# Provider docs, both attributes: "This value cannot be changed after creation."
# Editing either in tfvars is a destroy-and-recreate of the registry, which takes
# the published packages with it. prevent_destroy turns that into a refused plan
# instead of a deleted artifact store.
#
# -- TRAP 10: api_token IS THE CREDENTIAL, AND OIDC DOES NOT REMOVE IT ---------
# buildkite_test_suite.api_token is Computed + Sensitive - the long-lived suite
# token an OIDC policy exists to displace. Adopting OIDC ADDS an authentication
# path; it does not close the old one. There is no provider attribute to rotate
# or revoke api_token, and Terraform reads it into state either way. The check
# below keeps every unrotated suite visible until it is recorded in
# var.suite_api_tokens_rotated.
#
# -- TRAP 11: THE AUDIENCE IS NOT IN TERRAFORM, AND THE FORMATS DIFFER ---------
# The policy governs the token; the audience binds it - and that half lives in
# the pipeline, is never validated at plan time, and has a different URL shape
# per product:
#   Registry     https://packages.buildkite.com/{org.slug}/{registry.slug}
#   Test suite   https://buildkite.com/organizations/{org}/analytics/suites/{suite.slug}
# A registry token is additionally capped: exp minus iat "cannot be greater than
# 5 minutes". The outputs below emit the exact audience and the ready-to-paste
# buildkite-agent command per resource, built from the COMPUTED slug, so no
# pipeline hand-assembles a URL that fails as an opaque 401.
#
# -- TRAP 12: YOU CANNOT ENUMERATE REGISTRIES OR SUITES IN TERRAFORM ----------
# The provider ships data.buildkite_registry and data.buildkite_test_suite, both
# keyed on a REQUIRED slug, and no plural data source for either - unlike
# buildkite_clusters / buildkite_teams / buildkite_portals. The drift audit can
# therefore only see slugs it is told about; a registry created in the console is
# invisible to it. Reconciling var.audited_registry_slugs against the Package
# Registries page is a manual control, and the audit output says so rather than
# implying completeness.
#
# -- TRAP 13: SIMPLE YAML ONLY -------------------------------------------------
# Vendor docs: "only simple YAML syntax is accepted - that is, YAML containing
# only scalar values, maps, and lists. Complex YAML syntax and features, such as
# anchors, aliases, and tagged values are not supported." A hand-written heredoc
# is exactly where an anchor gets introduced to avoid repeating a claim block.
# This pack builds the policy with yamlencode() from typed HCL, which cannot emit
# an anchor and cannot drift out of step with the resource it sits on. Unset
# matchers are dropped rather than serialised as null, because a null matcher is
# not a documented rule shape.
#
# Verification: provider schema introspected live (buildkite/buildkite v1.38.0) -
# registry {name R, ecosystem R, team_ids R list(string), oidc_policy O,
# slug/uuid/public/registry_type C} and test_suite {name R, default_branch R,
# team_owner_id R, oidc_policy O+C, api_token C+S}; both singular data sources
# confirmed to expose a computed oidc_policy keyed on a required slug, and the
# absence of a plural data source confirmed against the provider's full
# 16-data-source list. Policy grammar, scope vocabularies, issuer list, matcher
# semantics, first-match ordering, the 5-minute registry token cap and both
# audience formats are taken verbatim from the vendor's OIDC documentation for
# Package Registries and for Test Engine test collection.
#
# -- VERIFICATION STATUS -------------------------------------------------------
#   HCL + policy encoder     VERIFIED-LIVE. `tofu init` + `tofu validate` Success
#     and `tofu fmt -check` clean against provider v1.38.0. The encoder was
#     executed and its output parsed: an empty statement list encodes to "" (the
#     documented no-trust assertion); a two-statement policy round-trips to a
#     list of {iss, scopes, claims} in AUTHORED ORDER, which is what makes TRAP 5
#     reviewable; any_of / none_of are restored to the wire names in / not_in;
#     unset matchers are dropped rather than serialised as null; and the emitted
#     document carries no anchor, alias or tag (TRAP 13).
#   Preconditions            VERIFIED-LIVE. Every guard was driven to failure
#     through `tofu plan` against the live provider - a non-Buildkite issuer, a
#     write scope with no identifying claim, and a broad statement preceding a
#     narrow one were each refused, and a suite scope inside a registry policy
#     was refused one layer earlier by the variable validation. A valid
#     configuration plans with zero precondition failures.
#   Resource creation        DRIFT-CHECKED-ONLY. The authoring tenant holds zero
#     registries and zero test suites and nothing was applied, so the provider's
#     create/update behaviour for oidc_policy, the force-new blast radius of
#     ecosystem / team_ids, and the two audit data sources are schema- and
#     doc-verified rather than tenant-exercised.
# =============================================================================

# HTH Guide Excerpt: begin govern-registry-oidc
locals {
  # TRAP 8. The complete supported issuer set. CircleCI's is per-organization
  # (https://oidc.circleci.com/org/$ORG), so it is matched by prefix.
  hth_oidc_exact_issuers   = ["https://agent.buildkite.com", "https://token.actions.githubusercontent.com"]
  hth_oidc_circleci_prefix = "https://oidc.circleci.com/org/"

  # TRAP 4. Per-product scope vocabularies. Disjoint on purpose.
  hth_registry_scopes = ["read_packages", "write_packages", "delete_packages"]
  hth_suite_scopes    = ["read_suites", "write_uploads", "read_test_plan", "write_test_plan"]

  # Scopes that mutate. A statement holding one of these and not naming the
  # caller is a standing publish grant for the whole organization.
  hth_registry_write_scopes = ["write_packages", "delete_packages"]
  hth_suite_write_scopes    = ["write_uploads", "write_test_plan"]

  # TRAP 6. Claims that actually identify WHO is calling. organization_slug is
  # deliberately absent: every pipeline in the org asserts it.
  hth_identifying_claims = ["pipeline_slug", "repository"]

  # TRAP 13 / TRAP 7. One encoder for both products. Emits the documented
  # statement list - { iss, scopes, claims } - as simple YAML, translating the
  # variable's any_of / none_of back to the wire names `in` / `not_in` and
  # dropping every matcher the caller left unset.
  hth_registry_policy_yaml = {
    for rk, r in var.registry_oidc_policies : rk => length(r.statements) == 0 ? "" : yamlencode([
      for st in r.statements : {
        "iss"    = st.issuer
        "scopes" = st.scopes
        "claims" = {
          for cn, rule in st.claims : cn => {
            for matcher, value in {
              "equals"     = rule.equals
              "not_equals" = rule.not_equals
              "in"         = rule.any_of
              "not_in"     = rule.none_of
              "matches"    = rule.matches
            } : matcher => value if value != null
          }
        }
      }
    ])
  }

  hth_suite_policy_yaml = {
    for sk, s in var.test_suite_oidc_policies : sk => length(s.statements) == 0 ? "" : yamlencode([
      for st in s.statements : {
        "iss"    = st.issuer
        "scopes" = st.scopes
        "claims" = {
          for cn, rule in st.claims : cn => {
            for matcher, value in {
              "equals"     = rule.equals
              "not_equals" = rule.not_equals
              "in"         = rule.any_of
              "not_in"     = rule.none_of
              "matches"    = rule.matches
            } : matcher => value if value != null
          }
        }
      }
    ])
  }
}

# Publish authority expressed as policy rather than as possession of a token.
resource "buildkite_registry" "inbound_oidc" {
  for_each = var.registry_oidc_policies

  name      = each.key
  ecosystem = each.value.ecosystem

  # TRAP 2. UUIDs here - buildkite_team.<name>.uuid, never .id.
  team_ids = each.value.team_uuids

  description = each.value.description
  emoji       = each.value.emoji
  color       = each.value.color

  # TRAP 3. Always explicit; "" is the documented way to assert no trust.
  oidc_policy = local.hth_registry_policy_yaml[each.key]

  lifecycle {
    # TRAP 9. ecosystem and team_ids are force-new; a tfvars edit would destroy
    # the registry and every package published to it.
    prevent_destroy = true

    # TRAP 8. A typo'd issuer plans green and rejects every token at runtime.
    precondition {
      condition = alltrue([
        for st in each.value.statements :
        contains(local.hth_oidc_exact_issuers, st.issuer) || startswith(st.issuer, local.hth_oidc_circleci_prefix)
      ])
      error_message = format("Registry '%s': issuer must be https://agent.buildkite.com, https://token.actions.githubusercontent.com, or https://oidc.circleci.com/org/<ORG> - the only issuers Buildkite supports. Any other value is accepted by Terraform and rejects every token at build time.", each.key)
    }

    # TRAP 4, restated at the resource so the message names the registry.
    precondition {
      condition = alltrue([
        for st in each.value.statements :
        length(setsubtract(toset(st.scopes), toset(local.hth_registry_scopes))) == 0
      ])
      error_message = format("Registry '%s': registry OIDC policies support only read_packages, write_packages and delete_packages. Test-suite scopes are valid YAML here and authorise nothing - this is what a policy copied from a test suite looks like.", each.key)
    }

    # TRAP 6. A write grant that does not name the caller is org-wide publish.
    precondition {
      condition = alltrue([
        for st in each.value.statements :
        length(setintersection(toset(st.scopes), toset(local.hth_registry_write_scopes))) == 0
        || length(setintersection(toset(keys(st.claims)), toset(local.hth_identifying_claims))) > 0
      ])
      error_message = format("Registry '%s': a statement grants write_packages or delete_packages without constraining pipeline_slug or repository. organization_slug does not narrow anything - every pipeline in the organization asserts it - so this grants publish authority over your artifacts to any build in the org.", each.key)
    }

    # TRAP 5. Order is evaluation order: a statement matching everything from its
    # issuer makes every later statement unreachable, including a write grant.
    precondition {
      condition = alltrue([
        for idx, st in each.value.statements :
        idx == length(each.value.statements) - 1 ||
        length(setintersection(toset(keys(st.claims)), toset(local.hth_identifying_claims))) > 0
      ])
      error_message = format("Registry '%s': a statement with no pipeline_slug or repository claim appears before another statement. Buildkite stops at the first match and grants only that statement's scopes, so everything after it is dead code. Move the broad statement last.", each.key)
    }

    # TRAP 7. equals and not_equals on the same value can never both hold.
    precondition {
      condition = alltrue(flatten([
        for st in each.value.statements : [
          for cn, rule in st.claims :
          rule.equals == null || rule.not_equals == null || rule.equals != rule.not_equals
        ]
      ]))
      error_message = format("Registry '%s': a claim sets equals and not_equals to the same value. All matchers in a rule are ANDed, so the rule can never match and the statement is permanently dead.", each.key)
    }
  }
}

# TRAP 11. Audience and agent command assembled from the computed slug.
output "registry_oidc_audiences" {
  description = "Per-registry OIDC audience and the buildkite-agent command that mints a token for it. Registry tokens are capped at 300s - exp minus iat cannot exceed 5 minutes."
  value = {
    for k, r in buildkite_registry.inbound_oidc : k => {
      registry_slug  = r.slug
      audience       = "https://packages.buildkite.com/${var.buildkite_organization}/${r.slug}"
      max_lifetime_s = 300
      agent_command  = "buildkite-agent oidc request-token --audience \"https://packages.buildkite.com/${var.buildkite_organization}/${r.slug}\" --lifetime 300"
      docker_login   = "docker login packages.buildkite.com/${var.buildkite_organization}/${r.slug} --username buildkite --password-stdin"
      statements     = length(var.registry_oidc_policies[k].statements)
      trust_declared = length(var.registry_oidc_policies[k].statements) > 0
    }
  }
}
# HTH Guide Excerpt: end govern-registry-oidc

# HTH Guide Excerpt: begin govern-test-suite-oidc
# Same control, different scope vocabulary (TRAP 4), different id namespace
# (TRAP 2), and a standing credential OIDC displaces but does not remove (TRAP 10).
resource "buildkite_test_suite" "inbound_oidc" {
  for_each = var.test_suite_oidc_policies

  name           = each.key
  default_branch = each.value.default_branch

  # TRAP 2. GraphQL ID here - the opposite of buildkite_registry.team_ids.
  team_owner_id = each.value.team_owner_id

  application_name = each.value.application_name
  emoji            = each.value.emoji
  color            = each.value.color

  # TRAP 3. Optional + COMPUTED on this resource: omit it and a console-authored
  # policy survives silently with no drift reported. Always assert a value.
  oidc_policy = local.hth_suite_policy_yaml[each.key]

  lifecycle {
    precondition {
      condition = alltrue([
        for st in each.value.statements :
        contains(local.hth_oidc_exact_issuers, st.issuer) || startswith(st.issuer, local.hth_oidc_circleci_prefix)
      ])
      error_message = format("Test suite '%s': issuer must be one of Buildkite's three supported issuers. Any other value plans cleanly and rejects every token at build time.", each.key)
    }

    # TRAP 4, in the other direction: registry scopes are dead here.
    precondition {
      condition = alltrue([
        for st in each.value.statements :
        length(setsubtract(toset(st.scopes), toset(local.hth_suite_scopes))) == 0
      ])
      error_message = format("Test suite '%s': suite OIDC policies support only read_suites, write_uploads, read_test_plan and write_test_plan. Registry scopes are a disjoint vocabulary and authorise nothing here.", each.key)
    }

    precondition {
      condition = alltrue([
        for st in each.value.statements :
        length(setintersection(toset(st.scopes), toset(local.hth_suite_write_scopes))) == 0
        || length(setintersection(toset(keys(st.claims)), toset(local.hth_identifying_claims))) > 0
      ])
      error_message = format("Test suite '%s': a statement grants write_uploads or write_test_plan without constraining pipeline_slug or repository, so any pipeline in the organization can write results into this suite and the suite stops being evidence of anything.", each.key)
    }

    precondition {
      condition = alltrue([
        for idx, st in each.value.statements :
        idx == length(each.value.statements) - 1 ||
        length(setintersection(toset(keys(st.claims)), toset(local.hth_identifying_claims))) > 0
      ])
      error_message = format("Test suite '%s': a statement matching every token from its issuer precedes another statement, making it unreachable - first match wins.", each.key)
    }

    precondition {
      condition = alltrue(flatten([
        for st in each.value.statements : [
          for cn, rule in st.claims :
          rule.equals == null || rule.not_equals == null || rule.equals != rule.not_equals
        ]
      ]))
      error_message = format("Test suite '%s': a claim sets equals and not_equals to the same value, so the rule can never match.", each.key)
    }
  }
}

# TRAP 10, surfaced rather than assumed. Reports every plan; does not block.
check "suite_static_tokens_still_outstanding" {
  assert {
    condition = length([
      for k, v in var.test_suite_oidc_policies : k
      if length(v.statements) > 0 && !contains(var.suite_api_tokens_rotated, k)
    ]) == 0
    error_message = format(
      "Test suite(s) %s now accept OIDC but their static api_token has not been recorded as rotated. OIDC ADDS an authentication path; it does not close the old one, and the provider exposes no attribute to revoke or rotate api_token. Rotate it in the console, remove it from the pipeline that read it, then list the suite in var.suite_api_tokens_rotated.",
      jsonencode([for k, v in var.test_suite_oidc_policies : k if length(v.statements) > 0 && !contains(var.suite_api_tokens_rotated, k)]),
    )
  }
}

output "test_suite_oidc_audiences" {
  description = "Per-suite OIDC audience and token command. The audience shape differs from a registry's - buildkite.com/organizations/... not packages.buildkite.com/... - and the collector reads the token from BUILDKITE_ANALYTICS_TOKEN."
  value = {
    for k, s in buildkite_test_suite.inbound_oidc : k => {
      suite_slug       = s.slug
      audience         = "https://buildkite.com/organizations/${var.buildkite_organization}/analytics/suites/${s.slug}"
      agent_command    = "BUILDKITE_ANALYTICS_TOKEN=$(buildkite-agent oidc request-token --audience \"https://buildkite.com/organizations/${var.buildkite_organization}/analytics/suites/${s.slug}\" --lifetime 300)"
      statements       = length(var.test_suite_oidc_policies[k].statements)
      static_api_token = contains(var.suite_api_tokens_rotated, k) ? "recorded as rotated" : "STILL OUTSTANDING - api_token remains a valid credential for this suite"
    }
  }
}
# HTH Guide Excerpt: end govern-test-suite-oidc

# HTH Guide Excerpt: begin audit-inbound-oidc
# TRAP 12. The resources above govern only what Terraform declares. A registry or
# suite created in the console is where an ungoverned publish path lives, and the
# provider offers no plural data source to find one - so the audit runs over an
# explicitly maintained slug list, and the output says so rather than implying
# completeness.
data "buildkite_registry" "audited" {
  for_each = toset(var.audited_registry_slugs)

  slug = each.value
}

data "buildkite_test_suite" "audited" {
  for_each = toset(var.audited_test_suite_slugs)

  slug = each.value
}

locals {
  # An empty live policy means the resource accepts no OIDC token at all - so
  # anything publishing to it is doing so with a static credential.
  hth_registries_without_policy = [
    for slug, r in data.buildkite_registry.audited : slug
    if trimspace(coalesce(r.oidc_policy, "")) == ""
  ]

  hth_suites_without_policy = [
    for slug, s in data.buildkite_test_suite.audited : slug
    if trimspace(coalesce(s.oidc_policy, "")) == ""
  ]

  # Live posture next to whether this configuration authored it. Policy SIZE is
  # reported rather than policy text: the console round-trips YAML, so a byte
  # delta is a review signal without printing trust rules into plan output.
  hth_inbound_oidc_live = merge(
    {
      for slug, r in data.buildkite_registry.audited : "registry/${slug}" => {
        terraform_managed = contains(keys(var.registry_oidc_policies), r.name)
        policy_present    = trimspace(coalesce(r.oidc_policy, "")) != ""
        policy_bytes      = length(coalesce(r.oidc_policy, ""))
      }
    },
    {
      for slug, s in data.buildkite_test_suite.audited : "test_suite/${slug}" => {
        terraform_managed = contains(keys(var.test_suite_oidc_policies), s.name)
        policy_present    = trimspace(coalesce(s.oidc_policy, "")) != ""
        policy_bytes      = length(coalesce(s.oidc_policy, ""))
      }
    },
  )
}

# Reports every plan and apply; does not block. An ungoverned publish path is a
# review finding about who can put artifacts in front of your consumers, not a
# reason to fail an unrelated deploy at 2am.
check "no_registry_publishes_without_an_oidc_policy" {
  assert {
    condition = length(local.hth_registries_without_policy) == 0
    error_message = format(
      "Registry/registries %s have no OIDC policy, so every publish to them is authenticated by a long-lived static credential and the registry cannot tell a release pipeline from a pull-request build. Declare them in var.registry_oidc_policies, or record why a static credential is acceptable.",
      jsonencode(local.hth_registries_without_policy),
    )
  }
}

check "no_test_suite_uploads_without_an_oidc_policy" {
  assert {
    condition = length(local.hth_suites_without_policy) == 0
    error_message = format(
      "Test suite(s) %s have no OIDC policy and accept uploads on the strength of the suite api_token alone, so any pipeline holding that token can write results into them.",
      jsonencode(local.hth_suites_without_policy),
    )
  }
}

output "inbound_oidc_audit" {
  description = "Live inbound-OIDC posture for every audited slug, plus the honest caveat about what the audit cannot see."
  value = {
    registries_without_policy = local.hth_registries_without_policy
    suites_without_policy     = local.hth_suites_without_policy
    live_state                = local.hth_inbound_oidc_live
    coverage_caveat           = "data.buildkite_registry and data.buildkite_test_suite are keyed on a required slug and the provider ships no plural data source for either. Anything absent from var.audited_registry_slugs / var.audited_test_suite_slugs is invisible here; reconciling those lists against the console is a manual control."
  }
}
# HTH Guide Excerpt: end audit-inbound-oidc
