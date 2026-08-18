# =============================================================================
# HTH Buildkite Control 2.5: Manage API Access Token Hygiene — Portals
# Profile Level: L1 (Crawl)
# Frameworks: CIS 5.4 | NIST IA-5, AC-6
# Source: https://howtoharden.com/guides/buildkite/#25-manage-api-access-token-hygiene
#
# Guide Step 3 recommends Portals in one sentence and ships no code. Portals
# exist because, in Buildkite's own words, the GraphQL API "is accessed using an
# authenticated API access token whose scopes cannot be restricted" — so handing
# an integration a GraphQL token hands it the whole organization. A portal
# replaces that token with a stored, fixed GraphQL document behind its own URL.
#
# ⚠️ READ THIS BEFORE CREATING A PORTAL — THE GUIDE OMITS IT ENTIRELY.
# Creating a portal mints a LONG-LIVED SERVICE TOKEN, and Buildkite documents its
# privilege plainly: the token "allows for the execution of these operations with
# administrator-level permissions." The portal narrows WHAT can be done; it does
# not narrow WHO the caller is. Consequences that follow directly:
#   • A portal query wide enough to be reusable is an admin credential. A
#     `mutation { organizationMemberUpdate }` portal grants role changes to
#     anyone holding the token, forever, with no user identity attached.
#   • The token does not expire. There is no rotation attribute on this resource.
#   • Every portal you create is therefore a standing admin-privileged
#     credential — the exact thing control 2.5 exists to stop accumulating.
# Write the narrowest query that satisfies the integration, hard-code every
# argument you can, and prefer a query over a mutation whenever the caller only
# needs to read.
#
# ── TRAP 1: allowed_ip_addresses is a STRING, not a list ─────────────────────
# The provider attribute is a single space-delimited string of CIDRs, not
# list(string). The variable below stays list-shaped for readability and is
# joined on the way in — copy that pattern rather than passing a list directly.
# Vendor default when unset: "all IP addresses are allowed." Silence is failure.
#
# ── TRAP 2: user_invokable = false is NOT the hardening lever ────────────────
# It is tempting to read `user_invokable = false` (the default) as the locked-down
# setting. It is not what it sounds like. The long-lived admin-level service token
# exists either way. Setting user_invokable = true ADDS a second path in which
# members mint short-lived, user-identified tokens that run under THEIR OWN
# permissions — strictly narrower than the service token, and attributable. Leave
# it false to avoid an unused surface; do not treat false as the mitigation. The
# real mitigations are query narrowness, the IP allowlist, and ephemeral portal
# tokens (issued from a console-generated portal secret via the Portals REST API
# `POST .../portals/{slug}/tokens` with grant_type=client_credentials — max two
# secrets per portal so they can be rotated, and no Terraform surface at all).
#
# ── TRAP 3: `token` is returned on creation only ─────────────────────────────
# `token` is computed and sensitive, and Buildkite returns it exactly once. It
# lands in Terraform state — treat that state as a secret store. If you lose it,
# there is no read-back: the only way to obtain a working token again is to
# replace the portal, which invalidates the old one and breaks every caller.
#
# ── TRAP 4: `slug` is required and owns the endpoint ─────────────────────────
# The reconciliation audit omits `slug`; the provider requires it. The slug is
# the last path segment of the live endpoint
# (https://portal.buildkite.com/organizations/{org}/portals/{slug}), so changing
# it moves the URL out from under existing callers.
#
# ── TRAP 5: a tfvars rename is a credential rotation you did not ask for ─────
# `name = each.key`, so the map label is both the resource address and the
# portal's name. Renaming a key — or dropping one — is a destroy-then-create,
# and by TRAP 3 the replacement issues a token you cannot compare with the old
# one because the old one was never readable. `prevent_destroy = true` on the
# resource turns that into a plan-time error instead of a silent break, exactly
# as 3.11 does for registries. Retiring a portal means removing that line in the
# same commit as the map entry.
#
# ── VERIFICATION STATUS: DRIFT-CHECKED-ONLY ─────────────────────────────────
# Authored from the provider v1.38.0 schema (buildkite_portal: name/query/slug
# required; allowed_ip_addresses string; user_invokable optional+computed; token
# computed+sensitive) and the vendor Portals documentation. The INVENTORY half
# was exercised live — `GET /v2/organizations/{org}/portals` returned HTTP 200
# with an empty array, and the buildkite_portals data source read cleanly — but
# no portal was created, because applying this pack mints a real admin-level
# credential in the target organization.
# =============================================================================

# HTH Guide Excerpt: begin declare-portals
# One portal per machine-to-machine operation. Each query should be the smallest
# document that satisfies exactly one integration — never a general-purpose
# document that several callers share, because the token is admin-privileged.
resource "buildkite_portal" "scoped" {
  for_each = var.portals

  name        = each.key
  slug        = each.value.slug
  description = each.value.description

  # The stored GraphQL document. This IS the permission boundary — nothing the
  # document does not name can be executed with this portal's token.
  query = each.value.query

  # The attribute is a space-delimited STRING of CIDRs, not a list. An empty
  # string leaves the portal callable from anywhere, which for an admin-level
  # token means anywhere on the internet with the bearer value.
  allowed_ip_addresses = join(" ", each.value.allowed_cidrs)

  # Leave false unless members genuinely need to invoke this portal as
  # themselves. See TRAP 2 — false is the smaller surface, not the mitigation.
  user_invokable = each.value.user_invokable

  lifecycle {
    # TRAP 5. Destroying a portal is unrecoverable, and the two ways to trigger
    # it do not look destructive in a diff:
    #   * renaming a key in var.portals changes the RESOURCE ADDRESS, which is a
    #     destroy-then-create no matter what the provider marks force-new — and
    #     because name = each.key, renaming the portal and destroying it are the
    #     same edit; and
    #   * dropping an entry from the map destroys it outright.
    # TRAP 3 is the consequence: `token` is returned once, never read back, so
    # the replacement portal issues a NEW token and every caller holding the old
    # one is broken until it is redistributed. This is a long-lived,
    # admin-privileged credential — the same reason 3.11 pins its registries.
    # To retire a portal deliberately, delete this line in the same commit that
    # removes the map entry, so the destroy is a reviewed decision rather than a
    # side effect of a tfvars rename.
    prevent_destroy = true

    # A portal that can WRITE and can be called from any address is the worst
    # combination this resource can express: an unauthenticated-by-network,
    # non-expiring, admin-level mutation endpoint. Refuse to plan it.
    precondition {
      condition = (
        length(regexall("(?im)(^|[};])[[:space:]]*mutation[[:space:]{(]", each.value.query)) == 0
        || length(each.value.allowed_cidrs) > 0
      )
      error_message = format(
        "Portal '%s' executes a mutation but declares no allowed_cidrs. Its token is long-lived and carries administrator-level permissions, so an unrestricted mutation portal is a standing admin credential reachable from any address. Add the egress CIDRs of the caller, or convert the portal to a read-only query.",
        each.key,
      )
    }
  }
}

output "portal_endpoints" {
  description = "Invocation URLs for the declared portals. Safe to share; the token is not."
  value = {
    for k, p in buildkite_portal.scoped :
    k => "https://portal.buildkite.com/organizations/${var.buildkite_organization}/portals/${p.slug}"
  }
}

output "portal_tokens" {
  description = "Long-lived, admin-privileged service tokens — returned on creation only. Move these straight into a secret store; they cannot be read back from Buildkite."
  sensitive   = true
  value       = { for k, p in buildkite_portal.scoped : k => p.token }
}
# HTH Guide Excerpt: end declare-portals

# HTH Guide Excerpt: begin detect-undeclared-portals
# Every portal in the organization, including ones created by hand in the
# console. This is the drift surface that matters for 2.5: a portal nobody
# declared is an admin-privileged credential nobody is rotating or reviewing.
data "buildkite_portals" "all" {}

locals {
  # TRAP 5, found by running this pack rather than reading the schema: on an
  # organization with zero portals the data source returns portals = NULL, not
  # an empty list, and every `for` expression over it aborts the plan with
  # "Iteration over null value". Normalise once, here, and iterate the local.
  discovered_portals = data.buildkite_portals.all.portals == null ? [] : data.buildkite_portals.all.portals

  declared_portal_slugs = toset([for k, v in var.portals : v.slug])

  undeclared_portal_slugs = setsubtract(
    toset([for p in local.discovered_portals : p.slug]),
    local.declared_portal_slugs,
  )

  unrestricted_portal_slugs = [
    for p in local.discovered_portals : p.slug
    if trimspace(coalesce(p.allowed_ip_addresses, "")) == ""
  ]
}

check "no_undeclared_portals" {
  assert {
    condition = length(local.undeclared_portal_slugs) == 0
    error_message = format(
      "Portals exist in this organization that are not declared in var.portals: %s. Each one holds a long-lived, administrator-level service token. Import it into this pack or delete it in Organization Settings > Integrations > Portals.",
      join(", ", local.undeclared_portal_slugs),
    )
  }
}

# Unrestricted portals, declared or not. Reported rather than blocked, because a
# read-only portal behind a caller you cannot pin to fixed egress is a judgement
# call — but it should never be a silent one.
check "portals_are_ip_restricted" {
  assert {
    condition = length(local.unrestricted_portal_slugs) == 0
    error_message = format(
      "Portals callable from any IP address: %s. Buildkite allows all addresses when the allowlist is unset, and portal tokens carry administrator-level permissions.",
      join(", ", local.unrestricted_portal_slugs),
    )
  }
}

output "portal_inventory" {
  description = "Audit view of every portal in the organization — including console-created ones this pack does not manage."
  value = [
    for p in local.discovered_portals : {
      slug              = p.slug
      name              = p.name
      declared_here     = contains(local.declared_portal_slugs, p.slug)
      ip_restricted     = trimspace(coalesce(p.allowed_ip_addresses, "")) != ""
      user_invokable    = p.user_invokable
      performs_mutation = length(regexall("(?im)(^|[};])[[:space:]]*mutation[[:space:]{(]", coalesce(p.query, ""))) > 0
      created_by        = try(p.created_by.email, null)
      created_at        = p.created_at
    }
  ]
}
# HTH Guide Excerpt: end detect-undeclared-portals
