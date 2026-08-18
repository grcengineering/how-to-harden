#!/usr/bin/env bash
# =============================================================================
# HTH Buildkite Control 2.6: Remove Dormant Organization Members
# Profile Level: L2 (Walk)
# Frameworks: CIS 5.3 | NIST AC-2(3)
# Source: https://howtoharden.com/guides/buildkite/#26-remove-dormant-organization-members
#
# WHY THIS IS AN api/ PACK AND NOT terraform/.
# Schema-checked against buildkite/buildkite v1.38.0. There is NO
# buildkite_organization_member RESOURCE — only two data sources, and both are
# blind to exactly the field this control turns on:
#   data.buildkite_organization_member  -> email(req) + id, name, uuid
#   data.buildkite_organization_members -> members[] { email, id, name, uuid }
# No lastSeenAt. No role. No createdAt. And with no resource, Terraform cannot
# remove a member even once you have decided to. Dormancy is a GraphQL-only read
# and removal is a GraphQL-only mutation, so this control lives here or nowhere.
#
# WHY THIS IS NOT SCIM. SCIM deprovisioning fires when someone leaves the
# company. It says nothing about the engineer who moved to another team two
# years ago and still holds pipeline access, and nothing about members created
# before SCIM was switched on. Those are current, valid identities in your IdP.
# Only activity distinguishes them.
#
# ── TRAP 1: `inactiveSince` IS real, and it is NOT the Enterprise-gated part ──
# The HTH Buildkite reconciliation lists `inactiveSince` as "doc-verified, not
# tenant-verified; grep returns zero across all four dumps". That row is stale.
# Live introspection of Organization.members returns twelve arguments —
#   first after last before search email team role security sso order inactiveSince
# — and `inactiveSince` is a **DateTime**, not a Date. `iso_days_ago` below
# always emits the full ISO 8601 instant; the date-only "YYYY-MM-DD" form is also
# accepted by the scalar (probed live) but an instant removes the ambiguity about
# which side of midnight the cutoff falls on.
#
# The argument is also NOT Enterprise-gated, which is the opposite of what the
# guide's availability note and this repo's own audit both imply. Executed live
# against a tenant that reads as NON-Enterprise:
#   members(first:5, inactiveSince:"2026-05-20T00:00:00Z") -> HTTP 200,
#   count 0 (the one member's lastSeenAt is newer than the cutoff), and the same
#   query with no filter -> count 1. The filter works and it filters correctly.
# What IS gated on that same tenant with that same token is the audit log —
# see TRAP 1b. Do not conflate the two: dormancy DETECTION works everywhere;
# only dormancy EXPLANATION needs Enterprise.
#
# ── TRAP 1b: the Enterprise gate is auditEvents, and it fails differently ─────
# Organization.auditEvents exists on every plan's schema and returns, verbatim:
#   {"type":"permission_error","errors":[{"message":"You cannot see audit events
#    in this organization on your current plan. Please upgrade your plan in order
#    to use this feature."}]}
# Note the shape: a TOP-LEVEL "type" field, not a normal errors-only envelope.
# Code that only checks `.errors[].extensions.code` misses it. This matters for
# the review, not the detection: without auditEvents you can prove an account
# went quiet but not what it did in the days before it did.
#
# ── TRAP 1c: there is no server-side dormancy ORDER ──────────────────────────
# OrganizationMemberOrder is exactly NAME | RECENTLY_CREATED | RELEVANCE
# (introspected live — three values, no lastSeenAt option). "The ten most dormant
# accounts" cannot be requested; it can only be computed after pulling every
# page. That is why `collect_members` below always paginates to exhaustion
# instead of reading the first page and ranking it.
#
# ── TRAP 1d: `members` HAS a `count`, unlike `apiAccessTokens` ────────────────
# The exact inversion of pack 2.5's TRAP 1. OrganizationMemberConnection exposes
# { count, edges, pageInfo } and `count` respects `inactiveSince`, so
# members(first:0, inactiveSince:X){count} is a legitimate one-request dormancy
# tally on plans where the filter is live. This pack still enumerates, because a
# count cannot tell you WHO or separate the never-signed-in bucket (TRAP 2) —
# but reach for `count` if you only need a metric.
#
# ── TRAP 2: null lastSeenAt is the WORST case, not a benign one ──────────────
# This is the exact inversion of pack 2.5. There, a null lastAccessedAt meant a
# Buildkite-provisioned system token and sweeping it broke hosted agents. Here,
# a null lastSeenAt means a member who accepted the invitation and has never
# signed in — an account that holds org access with zero activity to profile
# against. A naive `lastSeenAt < cutoff` comparison silently drops every one of
# them, because null compares false. `report` buckets them separately and ranks
# them by createdAt age instead. It is also unspecified whether the server-side
# `inactiveSince` filter includes them, which is the second reason the
# client-side path below is not merely a fallback for lower plans.
#
# ── TRAP 3: dormant on lastSeenAt is NOT dormant on the API ─────────────────
# lastSeenAt tracks web sign-in. A member who never touches the console but owns
# an API access token driving builds every hour reads as maximally dormant and
# is maximally live. Removing them breaks production. `report` therefore joins
# every dormant member against the organization's API access tokens on
# owner.email and refuses to rank a token-active member as removable.
#
# ── TRAP 4: three identifiers, two of them indistinguishable UUIDs ───────────
# Each node carries an OrganizationMember `id` (opaque base64), an
# OrganizationMember `uuid`, and a nested User with its own id AND uuid.
# organizationMemberDelete wants `id: ID!` — the MEMBERSHIP node id. The trap is
# not the base64 (obviously different); it is that the two UUIDs are the same
# shape and neither is labelled in the console URL. Live values from one real
# member, showing they are separate objects in separate namespaces:
#   member.id        base64 of "OrganizationMember---01a0061c-e078-4304-b235-..."
#   member.uuid      01a0061c-e078-4304-b235-b1d48fd1306e   <- the MEMBERSHIP
#   member.user.uuid 01a0061c-44ee-486d-af5d-1a94840c8077   <- the HUMAN
# `remove` takes the membership uuid and resolves it to member.id itself. Hand it
# a user uuid and the lookup misses — which reads as "not a member" rather than
# "wrong namespace", so check which UUID you copied before believing that error.
#
# ── TRAP 5: you are in your own report ──────────────────────────────────────
# The identity authenticating this script is an organization member and appears
# in these results. `remove` resolves the caller through GET /v2/user and
# refuses a self-match. It fails closed: if that endpoint does not return an
# email, the guard cannot be evaluated and the command aborts rather than
# proceeding unguarded.
#
# ── TRAP 6: removing the last ADMIN strands the organization ─────────────────
# Nothing in the API stops you deleting the final ADMIN membership. `remove`
# counts surviving admins first and refuses.
#
# ── TRAP 7: under SCIM, deletion here is undone at the next sync ─────────────
# If the IdP still asserts the user, Buildkite re-creates the membership on the
# next sync and the review evidences a removal that did not hold. No GraphQL
# field exposes whether an org is SCIM-managed, so this cannot be auto-detected;
# `remove` requires HTH_SCIM_REVIEWED=1 to record that the operator checked
# whether the deletion belongs in the IdP instead.
#
# ── TRAP 8: the `role` argument exists, and both known spellings are wrong ───
# The reconciliation states `members` has no `role` filter (audit of control
# 2.3). Introspection disagrees: `role` is present — but as a LIST, so the
# `role: ADMIN` scalar form that produced that finding is also wrong. The
# element type is truncated in the introspection dump, so this pack does not
# send the argument at all and filters on the returned `role` field, which is
# verified. Do not guess the list element spelling to save a round trip.
#
# ── VERIFICATION STATUS ─────────────────────────────────────────────────────
#   Handles                        VERIFIED — Organization.members arguments and
#     OrganizationMember fields (id, uuid, role, createdAt, lastSeenAt, sso, user)
#     introspected live; OrganizationMemberSSO exposes { authorizations, mode };
#     User.name / User.email exercised live by pack 2.5 via owner { name email };
#     organizationMemberDelete(input: OrganizationMemberDeleteInput!) with fields
#     { clientMutationId, id } confirmed against the live mutation list.
#   report / filter-support        VERIFIED-LIVE (paths), DRIFT-CHECKED-ONLY
#     (findings). Both commands were executed end to end against a real
#     organization and returned well-formed JSON: `filter-support` reported
#     "available", and `report 1` / `report 3650` both completed, exercising the
#     member pagination loop, the apiAccessTokens pagination loop and the
#     email join. What was NOT exercised is data: the authoring tenant carries a
#     single active member, so the dormant / never_signed_in /
#     dormant_but_api_active / dormant_outside_sso buckets all returned empty and
#     the multi-page cursor branch never fired.
#   inactiveSince path             VERIFIED-LIVE — and the earlier "Enterprise
#     gate was never opened" reading was WRONG. The argument was executed against
#     this NON-Enterprise tenant and filtered correctly (see TRAP 1): filtered
#     count 0 with a cutoff newer than the member's lastSeenAt, unfiltered count 1.
#     The gate that is genuinely closed here is auditEvents (TRAP 1b), captured
#     verbatim. `report` still pulls unfiltered by choice, not by necessity —
#     the reason is TRAP 2, not the plan tier.
#   auditEvents corroboration      NOT AVAILABLE on this tenant — permission_error
#     reproduced live and quoted in TRAP 1b. Anything in a review that depends on
#     "what did this account do before it went quiet" is unproven here.
#   remove                         DRIFT-CHECKED-ONLY — the mutation was NOT
#     executed. Deleting a real person's organization membership is irreversible
#     and this run was read-only. Guards are executable; the delete is not proven.
#
# Requires: BUILDKITE_TOKEN (GraphQL-enabled API access token), BUILDKITE_ORG_SLUG,
#           curl, jq. `remove` additionally requires HTH_SCIM_REVIEWED=1.
# =============================================================================

set -euo pipefail

: "${BUILDKITE_TOKEN:?set BUILDKITE_TOKEN (GraphQL-enabled API access token)}"
: "${BUILDKITE_ORG_SLUG:?set BUILDKITE_ORG_SLUG (organization slug from your Buildkite URL)}"

GQL="https://graphql.buildkite.com/v1"
REST="https://api.buildkite.com/v2"

gql() {
  curl -sS --fail-with-body -X POST "${GQL}" \
    -H "Authorization: Bearer ${BUILDKITE_TOKEN}" \
    -H "Content-Type: application/json" \
    --data @-
}

die_on_gql_errors() {
  local body="$1"
  if jq -e '.errors' >/dev/null 2>&1 <<<"${body}"; then
    jq -r '"GraphQL error: " + ([.errors[].message] | join("; "))' <<<"${body}" >&2
    exit 1
  fi
}

# TRAP 1. inactiveSince is a DateTime. GNU date and BSD/macOS date disagree on
# relative arithmetic and this repo runs on both, so try each in turn.
iso_days_ago() {
  local days="$1"
  date -u -d "${days} days ago" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null \
    || date -u -v-"${days}"d '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null \
    || { echo "cannot compute a cutoff: neither GNU nor BSD date syntax worked" >&2; exit 1; }
}

# HTH Guide Excerpt: begin dormant-member-report
# Full membership roster, paginated. Selects only introspection-confirmed fields.
# `role` is fetched and filtered client-side rather than passed as an argument
# (TRAP 8). `sso { mode }` matters because an SSO-OPTIONAL dormant member can
# still authenticate with a password that no IdP policy governs.
fetch_member_page() {
  local after="$1" since="$2"
  if [ -n "${since}" ]; then
    jq -n --arg slug "${BUILDKITE_ORG_SLUG}" --arg after "${after}" --arg since "${since}" '{
      query: "query($slug:ID!,$after:String,$since:DateTime){ organization(slug:$slug){
                members(first:100, after:$after, inactiveSince:$since){
                  edges { node {
                    id uuid role createdAt lastSeenAt
                    sso { mode }
                    user { name email }
                  } }
                  pageInfo { hasNextPage endCursor }
                } } }",
      variables: { slug: $slug, since: $since,
                   after: (if $after == "" then null else $after end) }
    }' | gql
  else
    jq -n --arg slug "${BUILDKITE_ORG_SLUG}" --arg after "${after}" '{
      query: "query($slug:ID!,$after:String){ organization(slug:$slug){
                members(first:100, after:$after){
                  edges { node {
                    id uuid role createdAt lastSeenAt
                    sso { mode }
                    user { name email }
                  } }
                  pageInfo { hasNextPage endCursor }
                } } }",
      variables: { slug: $slug, after: (if $after == "" then null else $after end) }
    }' | gql
  fi
}

collect_members() {
  local since="${1:-}" after="" page tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/hth-bk-members.XXXXXX")"
  while :; do
    page=$(fetch_member_page "${after}" "${since}")
    die_on_gql_errors "${page}"
    jq -c '.data.organization.members.edges[].node' <<<"${page}" >>"${tmp}"
    if [ "$(jq -r '.data.organization.members.pageInfo.hasNextPage' <<<"${page}")" != "true" ]; then
      break
    fi
    after=$(jq -r '.data.organization.members.pageInfo.endCursor' <<<"${page}")
  done
  jq -s '.' "${tmp}"
  rm -f "${tmp}"
}

# TRAP 1 / Enterprise gate. Probe the server-side filter with a one-row request
# rather than assuming a plan tier. Any error at all -> client-side path.
filter_supported() {
  local body
  body=$(jq -n --arg slug "${BUILDKITE_ORG_SLUG}" --arg since "$(iso_days_ago 3650)" '{
    query: "query($slug:ID!,$since:DateTime){ organization(slug:$slug){
              members(first:1, inactiveSince:$since){ edges { node { uuid } } } } }",
    variables: { slug: $slug, since: $since }
  }' | gql) || return 1
  ! jq -e '.errors' >/dev/null 2>&1 <<<"${body}"
}

# TRAP 1b. The audit log is the half that is actually plan-gated, and it fails
# with a TOP-LEVEL "type":"permission_error" rather than a plain errors envelope.
# Probed separately so a review never assumes it has corroboration it does not.
audit_log_available() {
  local body
  body=$(jq -n --arg slug "${BUILDKITE_ORG_SLUG}" '{
    query: "query($slug:ID!){ organization(slug:$slug){ auditEvents(first:1){ count } } }",
    variables: { slug: $slug }
  }' | gql) || return 1
  ! jq -e '.errors' >/dev/null 2>&1 <<<"${body}"
}

filter_support_status() {
  local filter audit
  if filter_supported; then filter=available; else filter=unavailable; fi
  if audit_log_available; then audit=available; else audit=unavailable; fi

  jq -n --arg filter "${filter}" --arg audit "${audit}" '{
    inactiveSince_filter: $filter,
    filter_note: (if $filter == "available"
      then "Server-side dormancy filtering works here. `report` still pulls unfiltered on purpose (TRAP 2), so this is provenance, not a switch."
      else "The argument was rejected. `report` was already filtering client-side on lastSeenAt, so detection is unaffected; only the request count changes." end),
    audit_log: $audit,
    audit_note: (if $audit == "available"
      then "auditEvents readable — a dormant account can be corroborated with what it last did."
      else "auditEvents is plan-gated on this organization. Dormancy is still fully DETECTABLE; what the account did before going quiet is not recoverable, so removal decisions rest on activity timestamps alone." end),
    detection_capability: "unconditional — never depends on either flag above"
  }'
}

# TRAP 3. Members who own an API access token that is actually being used are
# not dormant, whatever lastSeenAt says. Verified handles, exercised live by
# pack 2.5: apiAccessTokens has no `count`, so paginate and join on owner.email.
collect_token_owners() {
  local after="" page tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/hth-bk-owners.XXXXXX")"
  while :; do
    page=$(jq -n --arg slug "${BUILDKITE_ORG_SLUG}" --arg after "${after}" '{
      query: "query($slug:ID!,$after:String){ organization(slug:$slug){
                apiAccessTokens(first:100, after:$after){
                  edges { node { description lastAccessedAt owner { email } } }
                  pageInfo { hasNextPage endCursor }
                } } }",
      variables: { slug: $slug, after: (if $after == "" then null else $after end) }
    }' | gql)
    die_on_gql_errors "${page}"
    jq -c '.data.organization.apiAccessTokens.edges[].node' <<<"${page}" >>"${tmp}"
    if [ "$(jq -r '.data.organization.apiAccessTokens.pageInfo.hasNextPage' <<<"${page}")" != "true" ]; then
      break
    fi
    after=$(jq -r '.data.organization.apiAccessTokens.pageInfo.endCursor' <<<"${page}")
  done
  jq -s '.' "${tmp}"
  rm -f "${tmp}"
}

# The dormancy review. Three buckets, deliberately not one ranking:
#   dormant             — signed in once, not since the threshold
#   never_signed_in     — accepted the invite and never authenticated (TRAP 2)
#   dormant_but_api_active — lastSeenAt says gone, a live token says otherwise (TRAP 3)
report() {
  local days="${1:-90}" cutoff members owners mode
  case "${days}" in
    ''|*[!0-9]*) echo "threshold must be a whole number of days, got '${days}'" >&2; exit 2 ;;
  esac
  cutoff="$(iso_days_ago "${days}")"

  # The roster is ALWAYS pulled unfiltered, on every plan. The server-side
  # filter would drop the never_signed_in bucket if it treats null lastSeenAt as
  # "not inactive" (TRAP 2), and that bucket is the point of the control. The
  # probe is therefore reported as provenance, not used as a shortcut.
  if filter_supported; then mode="server-filter-available-unused"; else mode="client-side-only"; fi
  members=$(collect_members "")
  owners=$(collect_token_owners)

  jq -n --argjson members "${members}" --argjson owners "${owners}" \
        --argjson days "${days}" --arg cutoff "${cutoff}" --arg mode "${mode}" '
    def age_days: if . == null then null
                  else ((now - (sub("\\.[0-9]+";"") | fromdateiso8601)) / 86400 | floor) end;

    # email -> most recent token use, for the API-activity join.
    ($owners | map(select(.owner.email != null))
             | group_by(.owner.email)
             | map({ key: .[0].owner.email,
                     value: { tokens: length,
                              last_used_days_ago: ([ .[] | .lastAccessedAt | age_days ]
                                                   | map(select(. != null))
                                                   | if length == 0 then null else min end),
                              descriptions: [ .[] | .description ] } })
             | from_entries) as $tok

    | ($members | map(. + {
         idle_days:  (.lastSeenAt | age_days),
         email:      .user.email,
         name:       .user.name,
         sso_mode:   .sso.mode,
         token:      ($tok[.user.email // ""] // null)
       })) as $m

    | {
        threshold_days: $days,
        cutoff: $cutoff,
        dormancy_source: $mode,
        total_members: ($m | length),
        admins: ($m | map(select(.role == "ADMIN")) | length),

        # Signed in at least once, but not inside the window. Ordered by an
        # ADMIN-first, then longest-idle ranking: an idle admin is the finding.
        dormant: [ $m[]
          | select(.idle_days != null and .idle_days >= $days)
          | select(.token == null or .token.last_used_days_ago == null
                                  or .token.last_used_days_ago >= $days)
          | { uuid, id, name, email, role, sso_mode,
              idle_days, last_seen_at: .lastSeenAt, member_since: .createdAt } ]
          | sort_by(.role != "ADMIN", -.idle_days),

        # TRAP 2. Null never satisfies the comparison above, so it is collected
        # explicitly and aged on createdAt. These are the highest-risk accounts.
        never_signed_in: [ $m[]
          | select(.lastSeenAt == null)
          | { uuid, id, name, email, role, sso_mode,
              member_since: .createdAt,
              days_since_invite: (.createdAt | age_days) } ]
          | sort_by(.role != "ADMIN", -(.days_since_invite // 0)),

        # TRAP 3. Console-dormant, API-live. Do NOT remove these on this report.
        dormant_but_api_active: [ $m[]
          | select(.idle_days != null and .idle_days >= $days)
          | select(.token != null and .token.last_used_days_ago != null
                                   and .token.last_used_days_ago < $days)
          | { uuid, name, email, role,
              console_idle_days: .idle_days,
              token_last_used_days_ago: .token.last_used_days_ago,
              tokens: .token.descriptions,
              verdict: "service identity — migrate the automation off a human membership before removing" } ],

        # An SSO-OPTIONAL dormant member can still sign in with a password no
        # IdP policy governs, so SSO mode changes the urgency of the removal.
        dormant_outside_sso: [ $m[]
          | select((.idle_days != null and .idle_days >= $days) or .lastSeenAt == null)
          | select(.sso_mode != "REQUIRED")
          | { uuid, name, email, role, sso_mode } ]
      }'
}
# HTH Guide Excerpt: end dormant-member-report

# HTH Guide Excerpt: begin remove-dormant-member
# Remove one membership by uuid, behind every guard the API does not provide.
# organizationMemberDelete takes OrganizationMemberDeleteInput { clientMutationId, id }.
remove_member() {
  local target_uuid="$1" members node self_email admin_count body

  # TRAP 7. No field exposes SCIM management, so the operator asserts the check.
  if [ "${HTH_SCIM_REVIEWED:-}" != "1" ]; then
    echo "REFUSING: set HTH_SCIM_REVIEWED=1 to confirm you checked whether this" >&2
    echo "organization is SCIM-managed. If the IdP still asserts this user, this" >&2
    echo "deletion is reverted at the next sync and the access review evidences a" >&2
    echo "removal that did not hold. Deprovision in the IdP instead." >&2
    exit 5
  fi

  # TRAP 5. Fail closed: no resolvable caller identity means no self-guard.
  self_email=$(curl -sS --fail-with-body -H "Authorization: Bearer ${BUILDKITE_TOKEN}" \
                 "${REST}/user" | jq -r '.email // empty')
  if [ -z "${self_email}" ]; then
    echo "REFUSING: GET /v2/user returned no email, so the self-removal guard" >&2
    echo "cannot be evaluated. Aborting rather than deleting unguarded." >&2
    exit 6
  fi

  members=$(collect_members "")
  node=$(jq -c --arg u "${target_uuid}" 'map(select(.uuid == $u)) | first' <<<"${members}")
  if [ -z "${node}" ] || [ "${node}" = "null" ]; then
    echo "no organization member in ${BUILDKITE_ORG_SLUG} with uuid ${target_uuid}" >&2
    echo "run 'report' to list the uuids this organization actually has." >&2
    exit 4
  fi

  if [ "$(jq -r '.user.email // ""' <<<"${node}")" = "${self_email}" ]; then
    echo "REFUSING: ${target_uuid} is the membership of ${self_email}, the identity" >&2
    echo "authenticating this script. Removing it ends your own organization access." >&2
    exit 3
  fi

  # TRAP 6. Refuse to delete the last ADMIN.
  if [ "$(jq -r '.role' <<<"${node}")" = "ADMIN" ]; then
    admin_count=$(jq '[ .[] | select(.role == "ADMIN") ] | length' <<<"${members}")
    if [ "${admin_count}" -le 1 ]; then
      echo "REFUSING: ${target_uuid} is the only ADMIN in ${BUILDKITE_ORG_SLUG}." >&2
      echo "Deleting it leaves nobody able to manage the organization. Promote a" >&2
      echo "replacement admin first, then re-run." >&2
      exit 7
    fi
  fi

  # TRAP 4. The mutation takes the membership node `id`, not the uuid shown in
  # the console and not the user's id. Resolve it here so it cannot be confused.
  body=$(jq -n --arg id "$(jq -r '.id' <<<"${node}")" '{
    query: "mutation($id:ID!){
              organizationMemberDelete(input:{ id:$id }){
                clientMutationId
                organization { name }
                user { name email } } }",
    variables: { id: $id }
  }' | gql)
  die_on_gql_errors "${body}"

  jq -n --argjson node "${node}" --argjson res "${body}" '{
    removed_uuid: $node.uuid,
    removed_member_id: $node.id,
    removed_name: $node.user.name,
    removed_email: $node.user.email,
    removed_role: $node.role,
    last_seen_at: $node.lastSeenAt,
    member_since: $node.createdAt,
    confirmed_by_server: $res.data.organizationMemberDelete.user
  }'
}
# HTH Guide Excerpt: end remove-dormant-member

case "${1:-report}" in
  report)         report "${2:-90}" ;;
  filter-support) filter_support_status ;;
  remove)         remove_member "${2:?member uuid required — take it from report, not from the console URL}" ;;
  *)
    cat >&2 <<'USAGE'
usage:
  hth-buildkite-2.06-dormant-members.sh report [DAYS]   # default 90
  hth-buildkite-2.06-dormant-members.sh filter-support  # is inactiveSince usable here
  hth-buildkite-2.06-dormant-members.sh remove UUID     # needs HTH_SCIM_REVIEWED=1
USAGE
    exit 2 ;;
esac
