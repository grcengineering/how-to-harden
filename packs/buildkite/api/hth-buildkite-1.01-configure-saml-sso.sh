#!/usr/bin/env bash
# =============================================================================
# HTH Buildkite Control 1.1: Configure SAML SSO
# Profile Level: L2 (Walk)
# Frameworks: CIS 5.3 | NIST IA-2
# Source: https://howtoharden.com/guides/buildkite/#11-configure-saml-sso
#
# WHY THIS IS AN api/ PACK AND NOT terraform/.
# The buildkite/buildkite provider (v1.38.0) exposes 21 resources and 16 data
# sources; NONE of them manage an SSO provider or a member's SSO mode. This
# control was previously shipped as a .tf file containing only comments — a pack
# with no code, which reads as "automation exists" while automating nothing. The
# real surface is GraphQL: the ssoProvider* and organizationMemberUpdate
# mutations below were enumerated by live schema introspection against
# graphql.buildkite.com/v1.
#
# LOCKOUT WARNING — READ BEFORE RUNNING enable, session, require-sso OR require-all.
# ssoProviderEnable makes SSO the required path for organization members. If the
# IdP is misconfigured, or your own account cannot authenticate through it, you
# lose console access. Two mitigations, both mandatory:
#   1. Keep an API access token (this script's BUILDKITE_TOKEN) off-session. API
#      tokens authenticate independently of SSO, so ssoProviderDisable below is
#      your way back in.
#   2. Run `verify` first and confirm the provider is in a testable state.
# Buildkite requires each member to authorize the provider once before enforcement
# takes effect, so enabling on a fresh provider strands anyone who has not.
# `require-all` extends the same hazard to every member at once and is therefore
# gated twice: on a literal CONFIRM argument and on an ENABLED provider existing.
#
# ── TRAP 1: SSO is enforced PER MEMBER, not per organization ─────────────────
# An enabled SSO provider does not, by itself, force anyone through the IdP.
# Enforcement lives on OrganizationMember.sso.mode, which is REQUIRED or OPTIONAL
# per user. A single member left OPTIONAL keeps a working email+password path
# into the organization, and that member bypasses every IdP-side control you
# bought SSO for — conditional access, device posture, IdP MFA, deprovisioning
# on offboarding. Nothing in the console surfaces this as a list, and no other
# HTH check detects it. `members` below is that detector, and it exits 1 on a
# finding so it can be wired into a pipeline as a gate.
#
# ── TRAP 2: SSOProvider is an INTERFACE — do not reach for inline fragments ──
# sessionDurationInHours, pinSessionToIpAddress, testAuthorizationRequired,
# state and type are fields of the SSOProvider INTERFACE itself, not only of
# SSOProviderSAML. Selecting them through `... on SSOProviderSAML { ... }`
# compiles fine but silently returns null for the other two implementations
# (SSOProviderGoogleGSuite, SSOProviderGitHubApp) — a Google-backed org would
# read as "no session limit configured" when one is in force. Select them
# directly on the interface, as read_sso does.
#
# ── TRAP 3: sessionDurationInHours has no server-side sanity floor ───────────
# The field is a plain Int. Buildkite accepts a duration far longer than any
# reasonable session, and a long session defeats IdP-side revocation: disabling
# an account at the IdP does not end a Buildkite session already issued. The
# ceiling that matters is your offboarding SLA, not Buildkite's limit, so
# harden_session enforces a local band rather than trusting the API to refuse.
#
# ── TRAP 4: pinSessionToIpAddress is Enterprise-gated ────────────────────────
# The field exists on SSOProviderUpdateInput for every plan, but the enforcement
# behind it is an Enterprise feature. On a non-Enterprise organization the
# mutation is the wrong place to learn that. Pass `false` for the third argument
# of `session` on non-Enterprise plans and set the duration alone.
#
# VERIFICATION STATUS.
# Every READ path below (read_sso, list_member_sso, members) was executed against
# a live organization and returned data with zero GraphQL errors. Every WRITE
# path (enable, disable, session, require-sso, require-all) is
# DRIFT-CHECKED-ONLY: authored from live introspection of the mutation input
# objects, deliberately never executed, because these mutations change how humans
# log in to a real organization.
#
# Requires: BUILDKITE_TOKEN with GraphQL scope, BUILDKITE_ORG_SLUG. Needs jq.
# =============================================================================

set -euo pipefail

: "${BUILDKITE_TOKEN:?set BUILDKITE_TOKEN (GraphQL-enabled API access token)}"
: "${BUILDKITE_ORG_SLUG:?set BUILDKITE_ORG_SLUG}"

GQL="https://graphql.buildkite.com/v1"

# Upper bound on members fetched in one page. Organizations larger than this
# need cursor pagination; the report says so rather than silently truncating.
MEMBER_PAGE_SIZE="${MEMBER_PAGE_SIZE:-500}"

gql() {
  curl -sS -X POST "${GQL}" \
    -H "Authorization: Bearer ${BUILDKITE_TOKEN}" \
    -H "Content-Type: application/json" \
    --data @-
}

# Abort on a GraphQL error rather than letting `jq` render an empty finding set
# as a clean bill of health. GraphQL returns HTTP 200 on application errors, so
# curl's exit status proves nothing here.
require_no_errors() {
  local body="$1" what="$2"
  if jq -e 'has("errors") and (.errors | length > 0)' >/dev/null 2>&1 <<<"${body}"; then
    printf 'GraphQL error during %s:\n' "${what}" >&2
    jq '.errors' <<<"${body}" >&2
    return 1
  fi
}

# HTH Guide Excerpt: begin verify-sso
# Read the organization's SSO providers, their state, and the two session
# controls. Run this BEFORE any mutation.
# sessionDurationInHours / pinSessionToIpAddress / testAuthorizationRequired are
# fields of the SSOProvider INTERFACE, so they are selected directly and resolve
# for SAML, Google Workspace and GitHub App providers alike (see TRAP 2).
read_sso() {
  jq -n --arg slug "${BUILDKITE_ORG_SLUG}" '{
    query: "query($slug:ID!){ organization(slug:$slug){ id name
              ssoProviders(first:10){ edges { node {
                id uuid type state note emailDomain
                sessionDurationInHours pinSessionToIpAddress
                testAuthorizationRequired
              } } } } }",
    variables: { slug: $slug }
  }' | gql
}

report_sso() {
  local raw
  raw="$(read_sso)"
  require_no_errors "${raw}" "read_sso"
  jq '{
    organization: .data.organization.name,
    providers: [ .data.organization.ssoProviders.edges[].node ],
    findings: [ .data.organization.ssoProviders.edges[].node
                | select(.state == "ENABLED")
                | select((.sessionDurationInHours == null) or (.pinSessionToIpAddress != true))
                | { id, type,
                    session_duration_hours: .sessionDurationInHours,
                    ip_pinned: .pinSessionToIpAddress,
                    finding: "enabled provider without a bounded session and IP-pinned session" } ]
  }' <<<"${raw}"
}
# HTH Guide Excerpt: end verify-sso

# HTH Guide Excerpt: begin enforce-sso
# Enable an existing, already-tested SSO provider.
# ORDER MATTERS: create -> members authorize -> enable. Enabling a provider whose
# members have not authorized it locks them out; there is no bypass except the
# disable mutation below, which needs an API token issued before the lockout.
enable_sso() {
  local provider_id="$1"
  jq -n --arg id "${provider_id}" '{
    query: "mutation($id:ID!){ ssoProviderEnable(input:{id:$id}){
              ssoProvider { id state } } }",
    variables: { id: $id }
  }' | gql
}

# The documented way back in. Keep this reachable from a machine that is not
# behind the SSO you just enabled.
disable_sso() {
  local provider_id="$1"
  jq -n --arg id "${provider_id}" '{
    query: "mutation($id:ID!){ ssoProviderDisable(input:{id:$id}){
              ssoProvider { id state } } }",
    variables: { id: $id }
  }' | gql
}

# Bound the session and pin it to the address it was issued to.
# Duration caps how long a session outlives revocation at the IdP: disabling an
# account upstream does not terminate a Buildkite session already issued, so this
# number IS the worst-case window between offboarding and loss of access.
# IP pinning kills stolen-cookie replay from another network — Enterprise-gated
# (TRAP 4), so pass pin=false on other plans and set the duration alone.
harden_session() {
  local provider_id="$1" hours="$2" pin="${3:-true}"

  case "${hours}" in
    ''|*[!0-9]*) echo "session duration must be a positive integer number of hours" >&2; return 2 ;;
  esac
  # Local band, not a server rule (TRAP 3). 8760h is one year, Buildkite's
  # documented maximum; anything above 24h leaves a session usable for more than
  # a working day after an IdP revocation, so it must be stated deliberately.
  if [ "${hours}" -lt 1 ] || [ "${hours}" -gt 8760 ]; then
    echo "session duration ${hours}h is outside the supported 1-8760h range" >&2
    return 2
  fi
  if [ "${hours}" -gt 24 ] && [ "${HTH_ALLOW_LONG_SSO_SESSION:-}" != "1" ]; then
    echo "refusing ${hours}h: a session longer than 24h outlives same-day offboarding." >&2
    echo "Set HTH_ALLOW_LONG_SSO_SESSION=1 to record this as a deliberate exception." >&2
    return 3
  fi
  case "${pin}" in true|false) ;; *) echo "pin must be true or false" >&2; return 2 ;; esac

  jq -n --arg id "${provider_id}" --argjson hours "${hours}" --argjson pin "${pin}" '{
    query: "mutation($id:ID!,$hours:Int!,$pin:Boolean!){
              ssoProviderUpdate(input:{ id:$id,
                                        sessionDurationInHours:$hours,
                                        pinSessionToIpAddress:$pin }){
                ssoProvider { id state sessionDurationInHours pinSessionToIpAddress } } }",
    variables: { id: $id, hours: $hours, pin: $pin }
  }' | gql
}
# HTH Guide Excerpt: end enforce-sso

# HTH Guide Excerpt: begin member-sso-mode
# Per-member SSO enforcement — the half of this control that has no console list
# view and no other detector (TRAP 1). `optional` is a server-side filtered
# count of the same connection, so the total and the finding count cannot drift
# apart between two round trips.
list_member_sso() {
  jq -n --arg slug "${BUILDKITE_ORG_SLUG}" --argjson n "${MEMBER_PAGE_SIZE}" '{
    query: "query($slug:ID!,$n:Int!){ organization(slug:$slug){
              members(first:$n){ count edges { node {
                id role sso { mode } user { name email }
              } } }
              optional: members(first:$n, sso:{mode:OPTIONAL}){ count } } }",
    variables: { slug: $slug, n: $n }
  }' | gql
}

# Exits 1 when any member can still authenticate without SSO, so this is usable
# as a pipeline gate and not only as a report.
members_report() {
  local raw total
  raw="$(list_member_sso)"
  require_no_errors "${raw}" "list_member_sso"

  total="$(jq -r '.data.organization.members.count' <<<"${raw}")"
  if [ "${total}" -gt "${MEMBER_PAGE_SIZE}" ]; then
    echo "refusing to report: ${total} members exceeds MEMBER_PAGE_SIZE=${MEMBER_PAGE_SIZE};" >&2
    echo "raise MEMBER_PAGE_SIZE so the roster is not silently truncated." >&2
    return 4
  fi

  jq '{
    members_total: .data.organization.members.count,
    sso_optional_total: .data.organization.optional.count,
    findings: [ .data.organization.members.edges[].node
                | select(.sso.mode != "REQUIRED")
                | { id, role, sso_mode: .sso.mode,
                    name: .user.name, email: .user.email,
                    finding: "member can authenticate without SSO" } ]
  }' <<<"${raw}"

  local optional
  optional="$(jq -r '.data.organization.optional.count' <<<"${raw}")"
  if [ "${optional}" -gt 0 ]; then
    echo "FAIL: ${optional} of ${total} members can still authenticate without SSO." >&2
    return 1
  fi
  return 0
}

# Flip one member to REQUIRED. The id is the OrganizationMember node id returned
# by list_member_sso — NOT the user id and NOT the uuid.
require_sso_for_member() {
  local member_id="$1"
  jq -n --arg id "${member_id}" '{
    query: "mutation($id:ID!){ organizationMemberUpdate(input:{ id:$id,
                                                                sso:{mode:REQUIRED} }){
              organizationMember { id role sso { mode } user { email } } } }",
    variables: { id: $id }
  }' | gql
}

# Flip every non-REQUIRED member. Gated twice, because this is the one call in
# this pack that can lock out an entire organization in a single invocation:
#   1. a literal CONFIRM argument, so it cannot be reached by a typo; and
#   2. an ENABLED provider must exist — requiring SSO of members who have no
#      working provider to authorize against strands all of them at once.
require_sso_for_all() {
  [ "${1:-}" = "CONFIRM" ] || {
    echo "refusing: pass the literal argument CONFIRM to flip every member to REQUIRED" >&2
    return 2
  }

  local providers states
  providers="$(read_sso)"
  require_no_errors "${providers}" "read_sso"
  states="$(jq -r '[.data.organization.ssoProviders.edges[].node.state] | join(",")' <<<"${providers}")"
  case ",${states}," in
    *,ENABLED,*) ;;
    *) echo "refusing: no SSO provider is ENABLED (states: ${states:-none})." >&2
       echo "Requiring SSO with no enabled provider locks out every member." >&2
       return 3 ;;
  esac

  local raw ids
  raw="$(list_member_sso)"
  require_no_errors "${raw}" "list_member_sso"
  ids="$(jq -r '.data.organization.members.edges[].node
                | select(.sso.mode != "REQUIRED") | .id' <<<"${raw}")"

  if [ -z "${ids}" ]; then
    jq -n '{changed: 0, note: "every member is already REQUIRED"}'
    return 0
  fi

  while IFS= read -r id; do
    [ -n "${id}" ] || continue
    require_sso_for_member "${id}" \
      | jq -c '.data.organizationMemberUpdate.organizationMember'
  done <<<"${ids}"
}
# HTH Guide Excerpt: end member-sso-mode

case "${1:-verify}" in
  verify)      report_sso ;;
  members)     members_report ;;
  enable)      enable_sso  "${2:?provider id required}" | jq '.data.ssoProviderEnable' ;;
  disable)     disable_sso "${2:?provider id required}" | jq '.data.ssoProviderDisable' ;;
  session)     harden_session "${2:?provider id required}" \
                              "${3:?duration in hours required}" \
                              "${4:-true}" | jq '.data.ssoProviderUpdate' ;;
  require-sso) require_sso_for_member "${2:?organization member id required}" \
                 | jq '.data.organizationMemberUpdate' ;;
  require-all) require_sso_for_all "${2:-}" ;;
  *)
    cat >&2 <<'USAGE'
usage:
  hth-buildkite-1.01-configure-saml-sso.sh verify
  hth-buildkite-1.01-configure-saml-sso.sh members                      # exits 1 on any OPTIONAL member
  hth-buildkite-1.01-configure-saml-sso.sh enable  <provider-id>
  hth-buildkite-1.01-configure-saml-sso.sh disable <provider-id>
  hth-buildkite-1.01-configure-saml-sso.sh session <provider-id> <hours> [pin]
                                                                        # pin=true is Enterprise-only
  hth-buildkite-1.01-configure-saml-sso.sh require-sso <organization-member-id>
  hth-buildkite-1.01-configure-saml-sso.sh require-all CONFIRM
USAGE
    exit 2 ;;
esac
