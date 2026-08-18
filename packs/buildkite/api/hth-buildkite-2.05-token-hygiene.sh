#!/usr/bin/env bash
# =============================================================================
# HTH Buildkite Control 2.5: Manage API Access Token Hygiene
# Profile Level: L1 (Crawl)
# Frameworks: CIS 5.4 | NIST IA-5, AC-6
# Source: https://howtoharden.com/guides/buildkite/#25-manage-api-access-token-hygiene
#
# WHY THIS IS AN api/ PACK AND NOT terraform/.
# The buildkite/buildkite provider (v1.38.0) has no resource and no data source
# for organization API access tokens. There is no apiAccessTokenCreate mutation
# either — tokens are minted in Personal Settings only. What the control plane
# DOES expose is the half that matters for hygiene: read the whole inventory,
# revoke individual tokens, and set an org-wide auto-revoke-on-inactivity clock.
# Guide Step 5 says "revoke tokens that stop appearing" and ships no code; this
# pack is that code.
#
# ── TRAP 1: the connection has no `count` field ──────────────────────────────
# OrganizationAPIAccessTokenConnection exposes only edges / nodes / pageInfo.
# Asking for `apiAccessTokens(first:0){ count }` — the idiom that works on
# Organization.members — is a hard GraphQL error here. Every count below is
# computed client-side from edges, and the query paginates on pageInfo.
#
# ── TRAP 2: your own token is in the inventory ───────────────────────────────
# The token authenticating this script appears in its own results. Revoking it
# locks you out of the API mid-runbook and there is no undo. `revoke` below
# refuses to proceed on a self-match; the match is made against
# GET /v2/access-token, which returns the calling token's uuid.
#
# ── TRAP 3: revoke takes the GraphQL id, not the uuid ────────────────────────
# organizationApiAccessTokenRevoke wants `apiAccessTokenId: ID!` — the opaque
# base64 node id, NOT the human-visible uuid you see in the console. The
# inventory query below returns both and `revoke` resolves uuid -> id for you.
#
# ── TRAP 4: `ipAddress` is NOT an allowlist ──────────────────────────────────
# OrganizationAPIAccessToken.ipAddress reads like a restriction field. It is
# not: it is the source address the token was LAST USED FROM (verified live —
# the value equalled the caller's egress IP and moved with it; a never-used
# token reads null). Per-token IP allowlists are console-only and have no API.
# Treat this field as detection — a token answering from an address your
# integration does not own is the finding.
#
# ── TRAP 5: `scopes` governs REST only ───────────────────────────────────────
# Buildkite's own docs: the GraphQL API "is accessed using an authenticated API
# access token whose scopes cannot be restricted." A token whose REST scope list
# looks narrow may still hold unrestricted GraphQL. Whether GraphQL is enabled
# on a token is not exposed on this type, so it cannot be audited from here —
# which is exactly the argument for Portals (see the 2.5 terraform pack).
#
# ── TRAP 6: null lastAccessedAt means NEVER USED, not stale ──────────────────
# Buildkite provisions system tokens (e.g. "Hosted Queue API Access Token") that
# legitimately carry null lastAccessedAt. A naive "revoke everything that has
# never been seen" sweep breaks hosted agents. `stale` reports null separately
# and never folds it into the age ranking.
#
# ── TRAP 7: restrict-token-creation is REST, and PATCH is PARTIAL ───────────
# Guide Step 1 (`restrict_user_api_token_creation`) is the only organization-wide
# token control on this page that has NO GraphQL mutation and NO Terraform
# attribute — buildkite_organization exposes allowed_api_ip_addresses and
# enforce_2fa and nothing else. It lives solely on the REST api-settings
# resource, which is why this verb speaks REST while everything else here
# speaks GraphQL.
#
# The danger is the resource it shares. PATCH .../api-settings also carries
# `allowed_ip_addresses`, and the vendor's own page warns: "The IP allowlist
# takes effect immediately. If you write a CIDR range that does not include your
# own IP address, your next API request will be rejected. There is no dry-run
# mode." A read-modify-write that echoes the whole document back would re-assert
# that allowlist on every run — and one stale local copy locks the organization
# out of its own API. The vendor documents PATCH as partial ("Include only the
# fields you want to change"), so `set_restrict_token_creation` below builds a
# SINGLE-KEY body with jq and never reads the current document first. Do not
# "improve" it into a read-modify-write.
#
# ── VERIFICATION STATUS ─────────────────────────────────────────────────────
#   inventory / stale / auto-revoke-status  VERIFIED-LIVE — executed against a
#     real organization; pagination, self-token match, and the null-lastAccessedAt
#     bucket all exercised on real data.
#   restrict-token-creation-status / set-restrict-token-creation
#                                            DOC-VERIFIED-ONLY — authored from the
#     vendor's api-settings REST reference (verbs, path, request/response field
#     names, scope, and the plan-gate `features` map all transcribed from that
#     page) and NOT executed against any tenant in this run. Treat as unproven
#     against a live organization until someone runs the status verb.
#   set-auto-revoke                          DRIFT-CHECKED-ONLY — the mutation is
#     Enterprise-gated and this tenant reads as non-Enterprise. The document was
#     validated against the live schema (only the deliberately-omitted variables
#     errored), so field and type names are confirmed, but it was not executed.
#   revoke                                   DRIFT-CHECKED-ONLY — every guard was
#     exercised live; the mutation itself was schema-validated but not executed,
#     because revoking a real token is not reversible.
#
# Requires: BUILDKITE_TOKEN (GraphQL-enabled API access token), BUILDKITE_ORG_SLUG,
#           curl, jq.
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

# Abort on a GraphQL-layer error rather than letting jq quietly emit nulls.
die_on_gql_errors() {
  local body="$1"
  if jq -e '.errors' >/dev/null 2>&1 <<<"${body}"; then
    jq -r '"GraphQL error: " + ([.errors[].message] | join("; "))' <<<"${body}" >&2
    exit 1
  fi
}

# HTH Guide Excerpt: begin restrict-token-creation
# Guide Step 1. `restrict_user_api_token_creation` = "only organization
# administrators can create API access tokens" (vendor wording). It is the only
# organization-wide token setting here that is NOT plan-gated: the `features`
# map this resource returns enumerates the gated ones — api_ip_allow_list and
# inactive_api_token_revocation — and this field is not among them. So a
# non-Enterprise organization that cannot arm the inactivity clock can still
# close the tap.
rest_api_settings_get() {
  curl -sS --fail-with-body \
    -H "Authorization: Bearer ${BUILDKITE_TOKEN}" \
    "${REST}/organizations/${BUILDKITE_ORG_SLUG}/api-settings"
}

# Read-only. Reports the setting plus the plan-gate map, so an operator can tell
# "configured off" apart from "not available on this plan" — the distinction the
# `features` map exists to make.
restrict_token_creation_status() {
  rest_api_settings_get | jq '{
    restrict_user_api_token_creation,
    compliant: (.restrict_user_api_token_creation == true),
    ip_allowlist_configured: (.allowed_ip_addresses != null),
    revoke_inactive_tokens_after_days,
    plan_gated_features: .features,
    note: "restrict_user_api_token_creation is absent from .features, so it is not plan-gated"
  }'
}

# Write. TRAP 7: single-key PATCH body, built here and never derived from a read.
# Nothing in this function can emit allowed_ip_addresses, so it cannot re-assert
# (or clear) an IP allowlist as a side effect of toggling token creation.
set_restrict_token_creation() {
  local value="$1"
  case "${value}" in
    true|false) ;;
    *) echo "invalid value '${value}'; expected true or false" >&2; exit 2 ;;
  esac

  # Turning this OFF re-opens token creation to every member. That is a
  # loosening, so say so rather than performing it silently.
  if [ "${value}" = "false" ]; then
    echo "NOTE: setting restrict_user_api_token_creation=false lets every" >&2
    echo "organization member mint API access tokens again. This widens the" >&2
    echo "credential surface the rest of this pack is written to police." >&2
  fi

  jq -n --argjson v "${value}" '{restrict_user_api_token_creation: $v}' \
  | curl -sS --fail-with-body \
      -H "Authorization: Bearer ${BUILDKITE_TOKEN}" \
      -H "Content-Type: application/json" \
      -X PATCH "${REST}/organizations/${BUILDKITE_ORG_SLUG}/api-settings" \
      --data @- \
  | jq '{restrict_user_api_token_creation, plan_gated_features: .features}'
}
# HTH Guide Excerpt: end restrict-token-creation

# HTH Guide Excerpt: begin inventory-api-tokens
# Full inventory of the organization's API access tokens, paginated.
# There is no `count` on this connection — pull every edge and count locally.
fetch_token_page() {
  local after="$1"
  jq -n --arg slug "${BUILDKITE_ORG_SLUG}" --arg after "${after}" '{
    query: "query($slug:ID!,$after:String){ organization(slug:$slug){
              revokeInactiveTokensAfter
              apiAccessTokens(first:100, after:$after){
                edges { node {
                  id uuid description scopes
                  createdAt expiresAt lastAccessedAt ipAddress
                  owner { name email }
                } }
                pageInfo { hasNextPage endCursor }
              } } }",
    variables: { slug: $slug, after: (if $after == "" then null else $after end) }
  }' | gql
}

HTH_TOKENS_TMP=""
hth_tokens_cleanup() {
  if [ -n "${HTH_TOKENS_TMP}" ]; then rm -f "${HTH_TOKENS_TMP}"; fi
  HTH_TOKENS_TMP=""
}

collect_tokens() {
  local after="" page
  # mktemp, not `: >/tmp/hth-bk-tokens.$$.jsonl`. A PID-derived name in a shared
  # world-writable directory is guessable, and `>` follows a symlink planted at
  # that path. What accumulates here is the whole token inventory —
  # descriptions, uuids, owner emails, last-used IPs. No secret VALUES are in it
  # (GraphQL never returns them), which is why this is hygiene and not
  # disclosure, but it is still a reconnaissance map of every credential in the
  # organization.
  HTH_TOKENS_TMP="$(mktemp "${TMPDIR:-/tmp}/hth-bk-tokens.XXXXXX")"
  # RETURN covers the normal path. EXIT is the one that matters: die_on_gql_errors
  # calls exit mid-loop on any GraphQL error, so a plain `rm -f` after the loop is
  # unreachable on exactly the runs most likely to strand the file.
  trap hth_tokens_cleanup RETURN EXIT
  while :; do
    page=$(fetch_token_page "${after}")
    die_on_gql_errors "${page}"
    jq -c '.data.organization.apiAccessTokens.edges[].node' <<<"${page}" >>"${HTH_TOKENS_TMP}"
    if [ "$(jq -r '.data.organization.apiAccessTokens.pageInfo.hasNextPage' <<<"${page}")" != "true" ]; then
      break
    fi
    after=$(jq -r '.data.organization.apiAccessTokens.pageInfo.endCursor' <<<"${page}")
  done
  jq -s '.' "${HTH_TOKENS_TMP}"
}

# The uuid of the token running this script. Revoking it is unrecoverable.
self_token_uuid() {
  curl -sS --fail-with-body -H "Authorization: Bearer ${BUILDKITE_TOKEN}" \
    "${REST}/access-token" | jq -r '.uuid'
}

# Risk-annotated inventory. ORG_ADMIN_SCOPES are the REST scopes that let a
# token change who can do what — a token holding any of them is an admin
# credential no matter what it was created for.
inventory() {
  local self
  self=$(self_token_uuid)
  collect_tokens | jq --arg self "${self}" '
    def age_days: if . == null then null
                  else ((now - (sub("\\.[0-9]+";"") | fromdateiso8601)) / 86400 | floor) end;
    def admin_scopes: ["WRITE_ORGANIZATIONS","WRITE_ORGANIZATION_SETTINGS",
                       "WRITE_ORGANIZATION_INVITATIONS","WRITE_TEAMS","WRITE_CLUSTERS"];
    {
      total: length,
      never_expiring: [ .[] | select(.expiresAt == null) ] | length,
      never_used:     [ .[] | select(.lastAccessedAt == null) ] | length,
      admin_capable:  [ .[] | select((.scopes - admin_scopes) != .scopes) ] | length,
      tokens: [ .[] | {
        uuid, description,
        owner: .owner.name,
        is_self: (.uuid == $self),
        scope_count: (.scopes | length),
        admin_capable: ((.scopes - admin_scopes) != .scopes),
        expires_at: .expiresAt,
        never_expires: (.expiresAt == null),
        last_used_days_ago: (.lastAccessedAt | age_days),
        last_used_from_ip: .ipAddress
      } ] | sort_by(.last_used_days_ago == null, -(.last_used_days_ago // 0))
    }'
}

# Tokens unused for longer than the threshold. Never-used tokens are reported
# in a separate bucket because Buildkite provisions system tokens that read null.
stale() {
  local days="${1:-90}" self
  self=$(self_token_uuid)
  collect_tokens | jq --argjson days "${days}" --arg self "${self}" '
    def age_days: if . == null then null
                  else ((now - (sub("\\.[0-9]+";"") | fromdateiso8601)) / 86400 | floor) end;
    {
      threshold_days: $days,
      stale: [ .[] | . + {age: (.lastAccessedAt | age_days)}
               | select(.age != null and .age >= $days)
               | {uuid, description, owner: .owner.name, age_days: .age,
                  last_used_from_ip: .ipAddress, is_self: (.uuid == $self)} ],
      never_used_review_manually: [ .[] | select(.lastAccessedAt == null)
               | {uuid, description, owner: .owner.name, created_at: .createdAt} ]
    }'
}
# HTH Guide Excerpt: end inventory-api-tokens

# HTH Guide Excerpt: begin auto-revoke-inactive-tokens
# The org-wide inactivity clock. This is the single setting that turns Step 4's
# manual review into an automatic control: Buildkite revokes any API access token
# that has not been used within the period, without anyone running a script.
#
# ENTERPRISE-GATED (the mutation, not the read). Organization
# .revokeInactiveTokensAfter reads on every plan and returns null when unset —
# so the CHECK half below runs anywhere. The update mutation requires Enterprise
# and returns a plan error otherwise.
#
# Valid RevokeInactiveTokenPeriod values:
#   DAYS_30  DAYS_60  DAYS_90  DAYS_180  DAYS_365  NEVER
# NEVER is the insecure setting; it is also what null means in practice.
read_auto_revoke() {
  local body
  body=$(jq -n --arg slug "${BUILDKITE_ORG_SLUG}" '{
    query: "query($slug:ID!){ organization(slug:$slug){ id revokeInactiveTokensAfter } }",
    variables: { slug: $slug }
  }' | gql)
  die_on_gql_errors "${body}"
  jq '{
    organization_id: .data.organization.id,
    revoke_inactive_tokens_after: .data.organization.revokeInactiveTokensAfter,
    compliant: (.data.organization.revokeInactiveTokensAfter
                | . != null and . != "NEVER")
  }' <<<"${body}"
}

# RevokeInactiveTokenPeriod -> days, so the pre-flight below can ask `stale` the
# same question the clock will ask. NEVER has no day count; it never reaches here.
period_days() {
  case "$1" in
    DAYS_30) echo 30 ;; DAYS_60) echo 60 ;; DAYS_90) echo 90 ;;
    DAYS_180) echo 180 ;; DAYS_365) echo 365 ;;
    *) echo 90 ;;
  esac
}

# TRAP 6 IS THE WHOLE REASON THIS VERB IS GATED.
# `stale` deliberately buckets null lastAccessedAt separately because Buildkite
# provisions system tokens that legitimately read null, and "revoke everything
# never seen" breaks hosted agents. set-auto-revoke hands that same sweep to
# Buildkite to run automatically and permanently, org-wide, against every token
# including the ones nobody in this organization created. Dormant-BY-DESIGN
# credentials are the casualties: break-glass tokens, DR tokens, the token behind
# a quarterly job, and the vendor's own system tokens. None of them announce
# themselves, and a token revoked by the clock cannot be un-revoked.
#
# So this is the one mutation here that refuses to run blind. The operator must
# have looked at what the clock will eat — the never-used bucket is printed on
# every invocation — and must assert it with HTH_AUTO_REVOKE_REVIEWED=1, the same
# shape as the SCIM gate in the 2.6 pack. NEVER is exempt: it only ever loosens.
set_auto_revoke() {
  local period="$1" org_id body never_used
  case "${period}" in
    DAYS_30|DAYS_60|DAYS_90|DAYS_180|DAYS_365|NEVER) ;;
    *) echo "invalid period '${period}'; expected one of DAYS_30 DAYS_60 DAYS_90 DAYS_180 DAYS_365 NEVER" >&2
       exit 2 ;;
  esac

  if [ "${period}" != "NEVER" ]; then
    # Pre-flight, not advice: show the tokens the clock is most likely to take
    # first. Anything below with no legitimate reason to be used inside the
    # period is a token this setting will revoke without asking again.
    never_used=$(stale "$(period_days "${period}")" | jq '.never_used_review_manually')
    echo "Tokens with NO recorded use (TRAP 6 — includes Buildkite's own system" >&2
    echo "tokens, break-glass and DR credentials). Every one of these is revoked" >&2
    echo "by ${period} unless it is exercised inside the period:" >&2
    jq -r 'if length == 0 then "  (none)"
           else .[] | "  \(.uuid)  \(.description // "<no description>")  owner=\(.owner // "-")  created=\(.created_at)"
           end' <<<"${never_used}" >&2
    echo >&2

    if [ "${HTH_AUTO_REVOKE_REVIEWED:-}" != "1" ]; then
      echo "REFUSING: set HTH_AUTO_REVOKE_REVIEWED=1 to confirm you have read the" >&2
      echo "list above and the '${period}' bucket in 'stale', and that no token" >&2
      echo "that is dormant BY DESIGN will be destroyed by this clock. This arms" >&2
      echo "an automatic, permanent, org-wide revocation of API access tokens." >&2
      echo "Run '$0 inventory' and '$0 stale $(period_days "${period}")' first." >&2
      exit 5
    fi
  fi

  org_id=$(read_auto_revoke | jq -r '.organization_id')

  # NOTE the exact input type name: OrganizationRevokeInactiveTokensAfterUpdate
  # MutationInput. It carries the "Mutation" infix; the shorter ...UpdateInput
  # spelling does not exist and fails schema validation before it ever executes.
  body=$(jq -n --arg org "${org_id}" --arg period "${period}" '{
    query: "mutation($org:ID!,$period:RevokeInactiveTokenPeriod!){
              organizationRevokeInactiveTokensAfterUpdate(input:{
                organizationId:$org, revokeInactiveTokensAfter:$period
              }){ organization { id revokeInactiveTokensAfter } } }",
    variables: { org: $org, period: $period }
  }' | gql)
  die_on_gql_errors "${body}"
  jq '.data.organizationRevokeInactiveTokensAfterUpdate.organization' <<<"${body}"
}
# HTH Guide Excerpt: end auto-revoke-inactive-tokens

# HTH Guide Excerpt: begin revoke-api-token
# Revoke one token by uuid. Resolves uuid -> GraphQL id, and refuses to revoke
# the token this script is authenticating with.
revoke_token() {
  local target_uuid="$1" self node org_id body
  self=$(self_token_uuid)

  if [ "${target_uuid}" = "${self}" ]; then
    echo "REFUSING: ${target_uuid} is the token authenticating this script." >&2
    echo "Revoking it ends your API access with no way back. Mint a replacement," >&2
    echo "re-export BUILDKITE_TOKEN, then revoke this one." >&2
    exit 3
  fi

  node=$(collect_tokens | jq -c --arg u "${target_uuid}" 'map(select(.uuid == $u)) | first')
  if [ -z "${node}" ] || [ "${node}" = "null" ]; then
    echo "no API access token in ${BUILDKITE_ORG_SLUG} with uuid ${target_uuid}" >&2
    echo "run 'inventory' to list the uuids this organization actually has." >&2
    exit 4
  fi

  org_id=$(read_auto_revoke | jq -r '.organization_id')

  # Exact input type: OrganizationAPIAccessTokenRevokeMutationInput — capital
  # API, "Mutation" infix. Fields: organizationId, apiAccessTokenId.
  body=$(jq -n --arg org "${org_id}" --arg id "$(jq -r '.id' <<<"${node}")" '{
    query: "mutation($org:ID!,$id:ID!){
              organizationApiAccessTokenRevoke(input:{
                organizationId:$org, apiAccessTokenId:$id
              }){ revokedApiAccessTokenId } }",
    variables: { org: $org, id: $id }
  }' | gql)
  die_on_gql_errors "${body}"

  jq -n --argjson node "${node}" --argjson res "${body}" '{
    revoked_description: $node.description,
    revoked_uuid: $node.uuid,
    revoked_api_access_token_id: $res.data.organizationApiAccessTokenRevoke.revokedApiAccessTokenId
  }'
}
# HTH Guide Excerpt: end revoke-api-token

case "${1:-inventory}" in
  inventory)          inventory ;;
  stale)              stale "${2:-90}" ;;
  restrict-token-creation-status) restrict_token_creation_status ;;
  set-restrict-token-creation)
                      set_restrict_token_creation "${2:?value required (true|false)}" ;;
  auto-revoke-status) read_auto_revoke ;;
  set-auto-revoke)    set_auto_revoke "${2:?period required (DAYS_30|DAYS_60|DAYS_90|DAYS_180|DAYS_365|NEVER)}" ;;
  revoke)             revoke_token "${2:?token uuid required}" ;;
  *)
    cat >&2 <<'USAGE'
usage:
  hth-buildkite-2.05-token-hygiene.sh inventory
  hth-buildkite-2.05-token-hygiene.sh stale [DAYS]            # default 90
  hth-buildkite-2.05-token-hygiene.sh restrict-token-creation-status
  hth-buildkite-2.05-token-hygiene.sh set-restrict-token-creation true|false
      Guide Step 1. true = only organization administrators may create API
      access tokens. NOT plan-gated. Sends a single-key PATCH (TRAP 7) so it
      can never touch the IP allowlist on the same resource.
  hth-buildkite-2.05-token-hygiene.sh auto-revoke-status
  hth-buildkite-2.05-token-hygiene.sh set-auto-revoke PERIOD  # Enterprise
      PERIOD = DAYS_30|DAYS_60|DAYS_90|DAYS_180|DAYS_365|NEVER
      Arms an automatic org-wide revocation clock. Anything but NEVER prints the
      never-used bucket (TRAP 6) and requires HTH_AUTO_REVOKE_REVIEWED=1.
  hth-buildkite-2.05-token-hygiene.sh revoke UUID
USAGE
    exit 2 ;;
esac
