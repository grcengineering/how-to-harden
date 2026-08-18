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
# `enable` is gated the same way, and no longer on prose alone. Mitigation 2 above
# used to be an instruction with nothing enforcing it; it is now a precondition:
#   * a literal CONFIRM argument, so `enable` cannot be reached by a typo;
#   * HTH_SSO_LOCKOUT_ACK=1, so the operator states they have read this warning
#     and hold the off-session token of mitigation 1 before anything is written;
#   * a read-back of the target provider — it must exist in this organization and
#     be CREATED or DISABLED, and testAuthorizationRequired must be a definitive
#     false (TRAP 6) or HTH_SSO_UNTESTED_PROVIDER=1 must record the exception;
#   * the exact `disable` command, with this provider id already filled in,
#     printed to stderr BEFORE the mutation is sent, so the way back is on the
#     operator's screen at the moment the lockout becomes possible.
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
# ── TRAP 5: HTTP 200 is not success, and the recovery path is where it bites ──
# Buildkite's GraphQL API answers 200 with {"errors":[...]} for a wrong provider
# id, a revoked or under-scoped token, and a permission failure. A write that is
# only piped to `jq '.data.<field>'` therefore prints `null` and exits 0. On the
# recovery path that is the worst possible failure mode: an operator already
# locked out of the console runs `disable`, sees no error, and believes SSO is
# off. Every write below routes through gql_checked, which puts the response body
# through require_no_errors before rendering anything, so a failed mutation is
# loud and exits non-zero. `require-all` additionally counts per-member failures
# and refuses to report a partial flip as a completed one.
#
# ── TRAP 6: testAuthorizationRequired is read, never assumed ─────────────────
# The field is on the SSOProvider interface and is selected by read_sso, but its
# exact semantics are NOT live-verified: the organization this pack was authored
# against has zero SSO providers, so `verify` returned an empty provider list and
# there was nothing to observe the field on. `enable` therefore fails closed — it
# proceeds only on a definitive false, and treats true and null alike as "not
# proven safe", requiring HTH_SSO_UNTESTED_PROVIDER=1 to continue. Do not read
# that gate as a claim about what the field means; it is a refusal to guess with
# the one call that can strand every human in the organization.
#
# VERIFICATION STATUS.
# Every READ path below (read_sso, list_member_sso, members) was executed against
# a live organization and returned data with zero GraphQL errors. Every WRITE
# path (enable, disable, session, require-sso, require-all) is
# DRIFT-CHECKED-ONLY: authored from live introspection of the mutation input
# objects, deliberately never executed, because these mutations change how humans
# log in to a real organization. The guards in front of those writes — every
# refusal in enable, and the failure accounting in require-all — were exercised
# offline with `gql` replaced by a stub, so the refusals are proven; what remains
# unexecuted is the mutation the refusals stand in front of.
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

# The only way a mutation reaches the network in this pack. Reads the request
# document on stdin exactly like gql, but checks the response before emitting it,
# so a caller that pipes to `jq '.data.<field>'` can never print `null` out of an
# error response and exit 0 (TRAP 5). Errors are explicit rather than left to
# errexit: a caller may invoke this inside an `if`, which suppresses errexit for
# everything beneath it.
gql_checked() {
  local what="$1" body
  body="$(gql)" || return 1
  require_no_errors "${body}" "${what}" || return 1
  printf '%s\n' "${body}"
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
  raw="$(read_sso)" || return 1
  require_no_errors "${raw}" "read_sso" || return 1
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
#
# This is the most lockout-capable call in the pack, so it is the most gated: a
# literal CONFIRM, an acknowledgement variable, a fail-closed read-back of the
# target provider, and the recovery command printed before the write. Nothing
# here is advice — every one of them refuses.
enable_sso() {
  local provider_id="$1" confirm="${2:-}"

  [ "${confirm}" = "CONFIRM" ] || {
    echo "refusing: pass the literal argument CONFIRM after the provider id." >&2
    echo "usage: $0 enable <provider-id> CONFIRM" >&2
    return 2
  }
  [ "${HTH_SSO_LOCKOUT_ACK:-}" = "1" ] || {
    echo "refusing: enabling this provider makes the IdP the login path for every" >&2
    echo "member of ${BUILDKITE_ORG_SLUG}. Set HTH_SSO_LOCKOUT_ACK=1 to record that" >&2
    echo "you have read the LOCKOUT WARNING at the top of this file and that you" >&2
    echo "hold an API access token issued outside the SSO you are about to enable." >&2
    return 2
  }

  # Fail-closed read-back. The provider must be one this organization actually
  # has, in a state this script can reason about, before anything is written.
  local raw node state tested
  raw="$(read_sso)" || return 1
  require_no_errors "${raw}" "read_sso" || return 1
  node="$(jq -c --arg id "${provider_id}" '
    [ .data.organization.ssoProviders.edges[].node | select(.id == $id) ] | first // empty
  ' <<<"${raw}")"

  if [ -z "${node}" ]; then
    echo "refusing: no SSO provider with id '${provider_id}' exists in ${BUILDKITE_ORG_SLUG}." >&2
    echo "Run \`$0 verify\` and enable one of the provider ids it lists." >&2
    return 3
  fi

  state="$(jq -r '.state // "UNKNOWN"' <<<"${node}")"
  if [ "${state}" = "ENABLED" ]; then
    jq -n --arg id "${provider_id}" \
      '{changed: 0, id: $id, state: "ENABLED", note: "provider is already ENABLED"}'
    return 0
  fi
  case "${state}" in
    CREATED|DISABLED) ;;
    *) echo "refusing: provider ${provider_id} reports state '${state}', which is" >&2
       echo "neither CREATED nor DISABLED. Re-read it with \`$0 verify\`." >&2
       return 3 ;;
  esac

  # TRAP 6: only a definitive false proceeds. true and null are both "not proven
  # safe", because enabling a provider members have not authorized strands them.
  tested="$(jq -r 'if .testAuthorizationRequired == null
                   then "null" else (.testAuthorizationRequired | tostring) end' <<<"${node}")"
  if [ "${tested}" != "false" ] && [ "${HTH_SSO_UNTESTED_PROVIDER:-}" != "1" ]; then
    echo "refusing: provider ${provider_id} reports testAuthorizationRequired=${tested}," >&2
    echo "not a definitive false. Buildkite requires each member to authorize the" >&2
    echo "provider once before enforcement takes effect, so enabling now strands" >&2
    echo "everyone who has not. Authorize it and re-run \`$0 verify\`, or set" >&2
    echo "HTH_SSO_UNTESTED_PROVIDER=1 to record this as a deliberate exception." >&2
    return 3
  fi

  # The way back, on screen, before the lockout becomes possible.
  {
    echo "RECOVERY PATH — copy this line now, before the mutation is sent:"
    echo "  BUILDKITE_TOKEN=<off-session token> BUILDKITE_ORG_SLUG=${BUILDKITE_ORG_SLUG} \\"
    echo "    $0 disable ${provider_id}"
    echo "That token must already exist and must not depend on the SSO being enabled."
    echo "Enabling ${provider_id} (state ${state}, testAuthorizationRequired=${tested})..."
  } >&2

  local body
  body="$(jq -n --arg id "${provider_id}" '{
    query: "mutation($id:ID!){ ssoProviderEnable(input:{id:$id}){
              ssoProvider { id state } } }",
    variables: { id: $id }
  }' | gql_checked "ssoProviderEnable")" || return 1
  jq '.data.ssoProviderEnable' <<<"${body}"
}

# The documented way back in. Keep this reachable from a machine that is not
# behind the SSO you just enabled. Deliberately ungated — a recovery path with a
# confirmation gate is a recovery path you cannot use in an incident — but NOT
# unchecked: it routes through gql_checked so a revoked token or a wrong provider
# id fails loudly instead of printing null and exiting 0 (TRAP 5).
disable_sso() {
  local provider_id="$1"
  jq -n --arg id "${provider_id}" '{
    query: "mutation($id:ID!){ ssoProviderDisable(input:{id:$id}){
              ssoProvider { id state } } }",
    variables: { id: $id }
  }' | gql_checked "ssoProviderDisable"
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
  }' | gql_checked "ssoProviderUpdate"
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
  raw="$(list_member_sso)" || return 1
  require_no_errors "${raw}" "list_member_sso" || return 1

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
  }' | gql_checked "organizationMemberUpdate"
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
  providers="$(read_sso)" || return 1
  require_no_errors "${providers}" "read_sso" || return 1
  states="$(jq -r '[.data.organization.ssoProviders.edges[].node.state] | join(",")' <<<"${providers}")"
  case ",${states}," in
    *,ENABLED,*) ;;
    *) echo "refusing: no SSO provider is ENABLED (states: ${states:-none})." >&2
       echo "Requiring SSO with no enabled provider locks out every member." >&2
       return 3 ;;
  esac

  local raw ids
  raw="$(list_member_sso)" || return 1
  require_no_errors "${raw}" "list_member_sso" || return 1
  ids="$(jq -r '.data.organization.members.edges[].node
                | select(.sso.mode != "REQUIRED") | .id' <<<"${raw}")"

  if [ -z "${ids}" ]; then
    jq -n '{changed: 0, note: "every member is already REQUIRED"}'
    return 0
  fi

  # Per-member accounting. A member whose update is rejected must not be
  # rendered as `null` in a stream that otherwise reads as a completed flip
  # (TRAP 5) — every failure is counted, named, and makes the run exit non-zero.
  # The loop continues rather than aborting so one rejection does not hide the
  # rest, but the organization is then in a PARTIAL state and says so.
  local changed=0 failed=0 failed_ids="" body
  while IFS= read -r id; do
    [ -n "${id}" ] || continue
    if body="$(require_sso_for_member "${id}")"; then
      jq -c '.data.organizationMemberUpdate.organizationMember' <<<"${body}"
      changed=$((changed + 1))
    else
      failed=$((failed + 1))
      failed_ids="${failed_ids}${failed_ids:+ }${id}"
    fi
  done <<<"${ids}"

  if [ "${failed}" -gt 0 ]; then
    echo "FAIL: ${changed} member(s) flipped to REQUIRED, ${failed} REJECTED: ${failed_ids}" >&2
    echo "This organization is PARTIALLY enforced — the members above can still" >&2
    echo "authenticate without SSO. Fix the errors printed above and re-run;" >&2
    echo "this verb is idempotent and re-selects only non-REQUIRED members." >&2
    return 1
  fi
  jq -n --argjson changed "${changed}" '{changed: $changed, failed: 0}'
}
# HTH Guide Excerpt: end member-sso-mode

case "${1:-verify}" in
  verify)      report_sso ;;
  members)     members_report ;;
  enable)      enable_sso  "${2:?provider id required}" "${3:-}" ;;
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
  hth-buildkite-1.01-configure-saml-sso.sh enable  <provider-id> CONFIRM
                                                                        # also needs HTH_SSO_LOCKOUT_ACK=1
  hth-buildkite-1.01-configure-saml-sso.sh disable <provider-id>        # recovery path, ungated
  hth-buildkite-1.01-configure-saml-sso.sh session <provider-id> <hours> [pin]
                                                                        # pin=true is Enterprise-only
  hth-buildkite-1.01-configure-saml-sso.sh require-sso <organization-member-id>
  hth-buildkite-1.01-configure-saml-sso.sh require-all CONFIRM

environment:
  HTH_SSO_LOCKOUT_ACK=1         required by enable; acknowledges the LOCKOUT WARNING
  HTH_SSO_UNTESTED_PROVIDER=1   required by enable when testAuthorizationRequired
                                is not a definitive false (see TRAP 6)
  HTH_ALLOW_LONG_SSO_SESSION=1  required by session for a duration above 24h

exit codes:
  1  a GraphQL error, or a partially-applied require-all
  2  a missing or malformed confirmation / argument
  3  a refused precondition (unknown provider, wrong state, untested provider)
  4  the member roster exceeds MEMBER_PAGE_SIZE
USAGE
    exit 2 ;;
esac
