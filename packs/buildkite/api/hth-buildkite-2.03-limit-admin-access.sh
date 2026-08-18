#!/usr/bin/env bash
# =============================================================================
# HTH Buildkite Control 2.3: Limit Admin Access
# Profile Level: L1 (Crawl)
# Frameworks: CIS 5.4 | NIST AC-6(1)
# Source: https://howtoharden.com/guides/buildkite/#23-limit-admin-access
#
# WHY THIS IS AN api/ PACK AND NOT terraform/.
# The sibling pack hth-buildkite-2.03-limit-admin-access.tf is a VERIFICATION
# pack and says so honestly: the buildkite_organization_members data source
# returns email/id/name/uuid and NOT the member's organization role, so
# Terraform alone cannot tell you who your admins are. There is also no
# provider resource that grants or revokes org-level admin. Organization role
# lives only in GraphQL: OrganizationMember.role, read through
# Organization.members and mutated by organizationMemberUpdate /
# organizationMemberDelete. This pack is the half Terraform cannot do.
#
# -----------------------------------------------------------------------------
# TRAP 1 — the role filter exists, and you still should not census with it.
# Earlier HTH material recorded that Organization.members "takes only first /
# search / inactiveSince" and that a role filter was fabricated. Live
# introspection of the field's argument list disproves that: members accepts
# first, after, last, before, search, email, team, role, security, sso, order
# and inactiveSince. `role` is typed [OrganizationMemberRole!] — a LIST, not a
# scalar — and both `role: ADMIN` and `role: [ADMIN]` execute successfully.
#
# The correction matters, but the conclusion does not change: a security census
# must not be built on a server-side filter, because a filter that returns
# nothing is indistinguishable from an org that has no admins. "0 admins" then
# reads as a pass, which is fail-OPEN — the exact failure mode a bounded-admin
# gate exists to prevent. This pack enumerates the FULL roster, classifies
# client-side with jq, and uses the server-side filtered count only as an
# independent cross-check that must agree. Disagreement fails the run.
#
# TRAP 2 — REST's member `id` is the USER uuid, not the member uuid.
# GET /v2/organizations/{org}/members returns `role` (lowercased) and is a fine
# read surface, but its `id` field is the user's uuid. Verified against the same
# live account: REST reported id 01a0061c-44ee-486d-af5d-1a94840c8077 while that
# person's OrganizationMember uuid is 01a0061c-e078-4304-b235-b1d48fd1306e.
# Feeding a REST id into organizationMemberUpdate addresses a different object.
# Never carry an identifier across the two surfaces.
#
# TRAP 3 — mutations take the relay ID, not the uuid.
# organizationMemberUpdate/Delete take `id: ID!`, which is the base64 relay id,
# not the raw uuid. It decodes to the literal string "OrganizationMember---"
# followed by the uuid. That prefix is exactly 21 bytes, which is 7 whole base64
# groups, so its encoding "T3JnYW5pemF0aW9uTWVtYmVyLS0t" never shifts no matter
# what follows — which is why the guard below can check it without base64(1).
# Take ids from this script's own census output; never hand-assemble one.
#
# TRAP 4 — truncation must fail, not silently shrink the census.
# OrganizationMemberConnection DOES expose `count` (unlike
# OrganizationAPIAccessTokenConnection, which rejects it). This script paginates
# on pageInfo.hasNextPage and then asserts collected == count. A partial page
# that quietly stopped early would otherwise under-report admins and pass.
#
# TRAP 5 — machine and bot accounts hold real admin authority.
# User exposes `bot` and `machineUser`. A headless account with role ADMIN is a
# full-authority org credential that never surfaces in a "who are our people"
# review. They are counted toward the bound and flagged separately.
#
# TRAP 6 — demotion is a lockout risk.
# Demoting yourself, or the last remaining admin, can strand the organization.
# Mutations live behind explicit subcommands, require a typed confirmation, and
# refuse to target the calling identity (resolved via `viewer`) or to reduce the
# admin population to zero.
#
# Requires: curl, jq, BUILDKITE_TOKEN (GraphQL-enabled API access token),
#           BUILDKITE_ORG_SLUG.
# Tuning:   BUILDKITE_MAX_ADMINS (default 3, per the guide's "2-3 users"),
#           BUILDKITE_REQUIRE_ADMIN_2FA (default true),
#           BUILDKITE_REQUIRE_ADMIN_SSO (default false — SSO enforcement is
#           control 1.1's job; enable once a provider is live).
# Exit codes: 0 pass · 1 assertion failed · 2 usage · 3 API/consistency error.
# =============================================================================

set -euo pipefail

: "${BUILDKITE_TOKEN:?set BUILDKITE_TOKEN (GraphQL-enabled API access token)}"
: "${BUILDKITE_ORG_SLUG:?set BUILDKITE_ORG_SLUG}"

MAX_ADMINS="${BUILDKITE_MAX_ADMINS:-3}"
REQUIRE_ADMIN_2FA="${BUILDKITE_REQUIRE_ADMIN_2FA:-true}"
REQUIRE_ADMIN_SSO="${BUILDKITE_REQUIRE_ADMIN_SSO:-false}"
PAGE_SIZE="${BUILDKITE_PAGE_SIZE:-100}"

GQL="https://graphql.buildkite.com/v1"
MEMBER_ID_PREFIX="T3JnYW5pemF0aW9uTWVtYmVyLS0t"   # base64("OrganizationMember---")

gql() {
  curl -sS -X POST "${GQL}" \
    -H "Authorization: Bearer ${BUILDKITE_TOKEN}" \
    -H "Content-Type: application/json" \
    --data @-
}

# GraphQL returns HTTP 200 on error, so every response is inspected for .errors.
gql_checked() {
  local body
  body="$(gql)"
  if [ "$(jq '(.errors // []) | length' <<<"${body}")" -ne 0 ]; then
    jq -r '.errors[].message' <<<"${body}" >&2
    return 3
  fi
  printf '%s' "${body}"
}

# HTH Guide Excerpt: begin admin-census
# Full-roster enumeration. Every member is fetched and classified locally; the
# server-side role filter is used only as an independent cross-check, because a
# filtered query that returns nothing looks identical to an org with no admins.
# shellcheck disable=SC2016  # GraphQL $variables must stay literal, not shell-expanded
ROSTER_QUERY='query($slug:ID!,$first:Int!,$after:String){
  organization(slug:$slug){
    id
    slug
    members(first:$first, after:$after, order:NAME){
      count
      pageInfo{ hasNextPage endCursor }
      edges{ node{
        id
        uuid
        role
        createdAt
        lastSeenAt
        security{ twoFactorEnabled passwordProtected }
        sso{ mode }
        user{ uuid name email bot machineUser }
      } }
    }
  }
}'

# Independent count of admins computed by the server. Must equal the count this
# script derives locally; if it does not, one of the two views is wrong and the
# census is not trustworthy.
# shellcheck disable=SC2016  # GraphQL $variables must stay literal, not shell-expanded
ADMIN_COUNT_QUERY='query($slug:ID!){
  organization(slug:$slug){ members(first:1, role:[ADMIN]){ count } }
}'

fetch_roster() {
  local after=null nodes='[]' declared='' page

  while :; do
    page="$(jq -n \
      --arg q "${ROSTER_QUERY}" \
      --arg slug "${BUILDKITE_ORG_SLUG}" \
      --argjson first "${PAGE_SIZE}" \
      --argjson after "${after}" \
      '{query:$q, variables:{slug:$slug, first:$first, after:$after}}' | gql_checked)"

    if [ "$(jq -r '.data.organization // "null"' <<<"${page}")" = "null" ]; then
      echo "organization '${BUILDKITE_ORG_SLUG}' not visible to this token" >&2
      return 3
    fi

    declared="$(jq -r '.data.organization.members.count' <<<"${page}")"
    nodes="$(jq -n --argjson acc "${nodes}" --argjson p "${page}" \
      '$acc + ($p.data.organization.members.edges | map(.node))')"

    [ "$(jq -r '.data.organization.members.pageInfo.hasNextPage' <<<"${page}")" = "true" ] || break
    after="$(jq -c '.data.organization.members.pageInfo.endCursor' <<<"${page}")"
  done

  # Truncation guard: a short read must fail loudly, never under-report admins.
  local collected
  collected="$(jq 'length' <<<"${nodes}")"
  if [ "${collected}" -ne "${declared}" ]; then
    echo "census incomplete: collected ${collected} of ${declared} members" >&2
    return 3
  fi

  printf '%s' "${nodes}"
}

census() {
  local nodes server_admins
  nodes="$(fetch_roster)" || return $?
  server_admins="$(jq -n --arg q "${ADMIN_COUNT_QUERY}" --arg slug "${BUILDKITE_ORG_SLUG}" \
    '{query:$q, variables:{slug:$slug}}' | gql_checked \
    | jq -r '.data.organization.members.count')"

  jq -n \
    --arg org "${BUILDKITE_ORG_SLUG}" \
    --argjson members "${nodes}" \
    --argjson server_admins "${server_admins}" \
    '
    ($members | map(select(.role == "ADMIN"))) as $admins
    | {
        organization: $org,
        total_members: ($members | length),
        admin_count: ($admins | length),
        server_reported_admin_count: $server_admins,
        counts_agree: (($admins | length) == $server_admins),
        admins: ($admins | map({
          member_id:  .id,
          member_uuid: .uuid,
          user_uuid: .user.uuid,
          name:  .user.name,
          email: .user.email,
          headless: (.user.bot or .user.machineUser),
          two_factor_enabled: (.security.twoFactorEnabled == true),
          sso_mode: .sso.mode,
          created_at: .createdAt,
          last_seen_at: .lastSeenAt
        })),
        headless_admins:      ($admins | map(select(.user.bot or .user.machineUser) | .user.email)),
        admins_without_2fa:   ($admins | map(select(.security.twoFactorEnabled != true) | .user.email)),
        admins_sso_optional:  ($admins | map(select(.sso.mode != "REQUIRED") | .user.email))
      }'
}
# HTH Guide Excerpt: end admin-census

# HTH Guide Excerpt: begin assert-bounded-admins
# CI gate. Non-zero exit on any violation, so this drops straight into a
# pipeline step. Every check is fail-closed: a census that cannot be trusted
# fails rather than reporting a comfortable zero.
assert_admins() {
  local report failures=0 admin_count agree

  report="$(census)" || return $?
  printf '%s\n' "${report}"

  admin_count="$(jq -r '.admin_count' <<<"${report}")"
  agree="$(jq -r '.counts_agree' <<<"${report}")"

  if [ "${agree}" != "true" ]; then
    echo "FAIL: local admin count $(jq -r '.admin_count' <<<"${report}") disagrees with server-reported $(jq -r '.server_reported_admin_count' <<<"${report}")" >&2
    failures=$((failures + 1))
  fi

  # Buildkite organizations always retain at least one admin, so zero means the
  # census failed rather than that the org is unusually well hardened.
  if [ "${admin_count}" -eq 0 ]; then
    echo "FAIL: census reported 0 administrators, which is not a valid organization state" >&2
    failures=$((failures + 1))
  fi

  if [ "${admin_count}" -gt "${MAX_ADMINS}" ]; then
    echo "FAIL: ${admin_count} organization administrators, limit is ${MAX_ADMINS}" >&2
    jq -r '.admins[] | "  admin: \(.email) headless=\(.headless) 2fa=\(.two_factor_enabled) last_seen=\(.last_seen_at)"' <<<"${report}" >&2
    failures=$((failures + 1))
  fi

  if [ "${REQUIRE_ADMIN_2FA}" = "true" ] && [ "$(jq '.admins_without_2fa | length' <<<"${report}")" -ne 0 ]; then
    echo "FAIL: administrators without two-factor authentication: $(jq -r '.admins_without_2fa | join(", ")' <<<"${report}")" >&2
    failures=$((failures + 1))
  fi

  if [ "${REQUIRE_ADMIN_SSO}" = "true" ] && [ "$(jq '.admins_sso_optional | length' <<<"${report}")" -ne 0 ]; then
    echo "FAIL: administrators whose SSO mode is not REQUIRED: $(jq -r '.admins_sso_optional | join(", ")' <<<"${report}")" >&2
    failures=$((failures + 1))
  fi

  # Advisory, not a gate: a headless admin may be legitimate automation, but it
  # should be a deliberate decision rather than something nobody noticed.
  if [ "$(jq '.headless_admins | length' <<<"${report}")" -ne 0 ]; then
    echo "WARN: bot or machine accounts hold organization admin: $(jq -r '.headless_admins | join(", ")' <<<"${report}")" >&2
  fi

  [ "${failures}" -eq 0 ] || return 1
}
# HTH Guide Excerpt: end assert-bounded-admins

# HTH Guide Excerpt: begin demote-admin
# Write path. Guarded, because both mutations can strand an organization.
# Member ids come from the census above; a raw uuid or a REST id is rejected.
require_member_id() {
  local id="$1"
  case "${id}" in
    "${MEMBER_ID_PREFIX}"*) : ;;
    *)
      echo "refusing: '${id}' is not an OrganizationMember relay id." >&2
      echo "Use the member_id from '$0 census'. A bare uuid will not resolve, and" >&2
      echo "the id returned by REST /v2/organizations/{org}/members is the USER uuid." >&2
      return 2
      ;;
  esac
}

# Refuse to act on the calling identity or to empty the admin population.
preflight_target() {
  local id="$1" report caller_uuid target_user_uuid admin_count

  report="$(census)" || return $?

  # `viewer` resolves the identity behind BUILDKITE_TOKEN, which is how the
  # self-demotion guard below knows whose access it would be revoking.
  caller_uuid="$(jq -n --arg q 'query{viewer{user{uuid}}}' '{query:$q}' | gql_checked \
    | jq -r '.data.viewer.user.uuid')"

  target_user_uuid="$(jq -r --arg id "${id}" \
    'first(.admins[] | select(.member_id == $id) | .user_uuid) // ""' <<<"${report}")"
  admin_count="$(jq -r '.admin_count' <<<"${report}")"

  if [ -z "${target_user_uuid}" ]; then
    echo "refusing: ${id} is not currently an organization administrator" >&2
    return 2
  fi

  if [ "${target_user_uuid}" = "${caller_uuid}" ]; then
    echo "refusing: ${id} is the calling identity (${caller_uuid}); self-demotion can lock you out" >&2
    return 2
  fi

  if [ "${admin_count}" -le 1 ]; then
    echo "refusing: ${id} is the last remaining administrator" >&2
    return 2
  fi

  echo "target member uuid ${target_user_uuid}, ${admin_count} admins before change" >&2
}

# Demote an organization administrator to MEMBER. Requires BUILDKITE_CONFIRM=demote.
demote_admin() {
  local id="$1"
  # Explicit `|| return` on every guard. Relying on `set -e` here would be
  # fail-open: errexit is suppressed for the whole call chain the moment anyone
  # writes `if demote_admin ...` or `demote_admin ... && ...`, and the mutation
  # would then run with its preflight quietly skipped.
  require_member_id "${id}" || return $?
  [ "${BUILDKITE_CONFIRM:-}" = "demote" ] || {
    echo "refusing: set BUILDKITE_CONFIRM=demote to authorise this mutation" >&2; return 2; }
  preflight_target "${id}" || return $?

  jq -n --arg id "${id}" '{
    query: "mutation($id:ID!){ organizationMemberUpdate(input:{id:$id, role: MEMBER}){
              organizationMember { id role user { email } } } }",
    variables: { id: $id }
  }' | gql_checked | jq '.data.organizationMemberUpdate.organizationMember'
}

# Remove a member from the organization entirely. Requires BUILDKITE_CONFIRM=remove.
remove_member() {
  local id="$1"
  require_member_id "${id}" || return $?
  [ "${BUILDKITE_CONFIRM:-}" = "remove" ] || {
    echo "refusing: set BUILDKITE_CONFIRM=remove to authorise this mutation" >&2; return 2; }
  preflight_target "${id}" || return $?

  jq -n --arg id "${id}" '{
    query: "mutation($id:ID!){ organizationMemberDelete(input:{id:$id}){
              deletedOrganizationMemberID user { email } } }",
    variables: { id: $id }
  }' | gql_checked | jq '.data.organizationMemberDelete'
}
# HTH Guide Excerpt: end demote-admin

case "${1:-assert}" in
  census) census ;;
  assert) assert_admins ;;
  demote) demote_admin "${2:?member relay id required — take member_id from the census subcommand}" ;;
  remove) remove_member "${2:?member relay id required — take member_id from the census subcommand}" ;;
  *)
    echo "usage: $0 [census|assert|demote <member-id>|remove <member-id>]" >&2
    exit 2
    ;;
esac
