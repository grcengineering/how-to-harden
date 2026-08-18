#!/usr/bin/env bash
# =============================================================================
# HTH Buildkite Control 3.1: Configure Agent Tokens — token lifecycle
# Profile Level: L1 (Crawl)
# Frameworks: CIS 3.11 | NIST SC-12
# Source: https://howtoharden.com/guides/buildkite/#31-configure-agent-tokens
#
# WHY THIS IS AN api/ PACK AND NOT MORE TERRAFORM.
# The terraform/ pack for 3.1 covers scoping and IP restriction. It cannot cover
# the other two halves of "manage agent tokens": EXPIRY and REVOCATION. Verified
# against buildkite/buildkite v1.38.0 — `buildkite_cluster_agent_token` has
# exactly three writable attributes (cluster_id, description,
# allowed_ip_addresses) and no `expires_at`. There is also no Terraform verb for
# "revoke this token now and disconnect what it registered". Both live only here.
#
# WHICH SURFACE: GraphQL, not REST.
# `clusterAgentTokenCreate` accepts `expiresAt: DateTime` — confirmed by live
# schema introspection of ClusterAgentTokenCreateInput. GraphQL is used below
# because the same call sets expiry AND the IP allowlist and returns the secret
# in one round trip. The REST equivalents are implemented too
# (POST/DELETE .../clusters/{cluster_uuid}/tokens) for shops whose token only
# carries REST scopes; they are the same control, not a different one.
#
# TRAP 1 — THE ONE THE GUIDE OMITS. Revocation does NOT disconnect agents.
#   Revoking a token stops it being used to register NEW agents. Every agent that
#   already registered with it stays connected and keeps accepting jobs. If you
#   are revoking because the token leaked, revocation alone is not containment:
#   you must also stop the agents. `contain` below does both, in that order.
#
# TRAP 2 — expiry is write-once and has a floor.
#   `expiresAt` must be at least 10 minutes in the future and is IMMUTABLE once
#   set. There is no "extend"; rotation means creating a replacement token and
#   revoking the incumbent. Tokens created in the web UI have NO expiry at all,
#   which is why an org that only ever clicked "New token" will show every token
#   with expiresAt: null in the audit below.
#
# TRAP 3 — two identifiers, not interchangeable. Verified live:
#   GraphQL wants the base64 cluster ID ("Q2x1c3Rlci0tLT...") — passing the UUID
#   to `agents(cluster:)` returns "An invalid ID was supplied".
#   REST wants the cluster UUID in the path. The audit prints both so you can
#   feed either surface without guessing.
#
# TRAP 4 — the secret is returned exactly once.
#   `clusterAgentTokenCreate` returns `tokenValue`; the ClusterToken type has no
#   field that carries the secret afterwards. Lose it and the only recovery is
#   another rotation. Pipe `create` straight into a secret manager.
#
# TRAP 5 — allowedIpAddresses is a single space-separated STRING here, while the
#   Terraform attribute of the same name is list(string). Do not copy literals
#   between the two packs.
#
# Requires: BUILDKITE_TOKEN (GraphQL scope; REST subcommands additionally need
# read_clusters/write_clusters), BUILDKITE_ORG_SLUG, curl, jq.
# Default subcommand is `audit`, which is read-only.
# =============================================================================

set -euo pipefail

: "${BUILDKITE_TOKEN:?set BUILDKITE_TOKEN (Buildkite API access token)}"
: "${BUILDKITE_ORG_SLUG:?set BUILDKITE_ORG_SLUG (organization slug from your Buildkite URL)}"

GQL="https://graphql.buildkite.com/v1"
REST="https://api.buildkite.com/v2"

gql() {
  curl -sS -X POST "${GQL}" \
    -H "Authorization: Bearer ${BUILDKITE_TOKEN}" \
    -H "Content-Type: application/json" \
    --data @-
}

# Fail loudly on GraphQL-level errors instead of letting jq return null further
# down the pipe — a silent null here would read as "no tokens", i.e. as a pass.
assert_no_errors() {
  local body="$1"
  if printf '%s' "${body}" | jq -e '.errors // empty' >/dev/null 2>&1; then
    printf '%s' "${body}" | jq '.errors' >&2
    exit 1
  fi
  printf '%s' "${body}"
}

org_id() {
  jq -n --arg slug "${BUILDKITE_ORG_SLUG}" \
    '{query:"query($slug:ID!){ organization(slug:$slug){ id } }", variables:{slug:$slug}}' \
  | gql | jq -r '.data.organization.id'
}

# HTH Guide Excerpt: begin audit-token-lifecycle
# Read every cluster agent token in the organization and judge it against the
# two conditions the control actually requires. Run this first, and run it again
# after any change — it is the only surface that reports expiry at all.
#
#   BK-3.01a  expiresAt must not be null   (UI-created tokens are always null)
#   BK-3.01b  allowedIpAddresses must not be empty (empty == any source address)
audit_tokens() {
  local body
  body="$(jq -n --arg slug "${BUILDKITE_ORG_SLUG}" '{
    query: "query($slug:ID!){ organization(slug:$slug){ name
              clusters(first:100){ edges { node {
                id uuid name
                agentTokens(first:100){ count edges { node {
                  id uuid description expiresAt allowedIpAddresses
                } } }
              } } } } }",
    variables: { slug: $slug }
  }' | gql)"
  assert_no_errors "${body}" >/dev/null

  printf '%s' "${body}" | jq '
    [ .data.organization.clusters.edges[].node
      | .name as $cluster
      | .id   as $cluster_graphql_id
      | .uuid as $cluster_uuid
      | .agentTokens.edges[]?.node
      | {
          cluster: $cluster,
          cluster_graphql_id: $cluster_graphql_id,   # GraphQL mutations use this
          cluster_uuid: $cluster_uuid,               # REST paths use this
          token_id: .id,
          description: .description,
          expires_at: .expiresAt,
          allowed_ip_addresses: .allowedIpAddresses,
          "BK-3.01a_has_expiry": (.expiresAt != null),
          "BK-3.01b_ip_restricted":
            ((.allowedIpAddresses // "") | gsub("\\s";"") | length > 0)
        }
    ]
    | { total: length,
        failing_expiry:      [ .[] | select(."BK-3.01a_has_expiry"      | not) | .token_id ],
        failing_ip_allowlist:[ .[] | select(."BK-3.01b_ip_restricted"   | not) | .token_id ],
        tokens: . }'
}

# Same audit over REST, for tokens that only carry REST scopes. The cluster UUID
# — not the GraphQL ID — belongs in this path.
rest_audit_tokens() {
  local cluster_uuid="$1"
  curl -sS -H "Authorization: Bearer ${BUILDKITE_TOKEN}" \
    "${REST}/organizations/${BUILDKITE_ORG_SLUG}/clusters/${cluster_uuid}/tokens" \
  | jq '[ .[] | { id, description, expires_at, allowed_ip_addresses } ]'
}
# HTH Guide Excerpt: end audit-token-lifecycle

# HTH Guide Excerpt: begin create-expiring-token
# Portable RFC3339 timestamp N days out. GNU date and BSD/macOS date disagree on
# every relevant flag, so try both rather than shipping a Linux-only pack.
rfc3339_in_days() {
  local days="$1"
  date -u -d "+${days} days" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
    || date -u -v"+${days}d" +%Y-%m-%dT%H:%M:%SZ
}

to_epoch() {
  date -u -d "$1" +%s 2>/dev/null \
    || date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$1" +%s
}

# Enforce Buildkite's own floor locally, so a rejected mutation is not the first
# time you learn the timestamp was too close. The API refuses anything under ten
# minutes out, and refuses to change it afterwards.
assert_expiry_valid() {
  local expires_at="$1" target now
  target="$(to_epoch "${expires_at}")"
  now="$(date -u +%s)"
  if [ $(( target - now )) -lt 600 ]; then
    echo "expiresAt ${expires_at} is less than 10 minutes out; Buildkite rejects this and the value is immutable once accepted" >&2
    exit 1
  fi
}

# Create a token that is bounded in BOTH dimensions: time (expiresAt) and space
# (allowedIpAddresses). allowedIpAddresses is a single space-separated string of
# CIDRs here — "203.0.113.0/24 198.51.100.7/32" — unlike the Terraform list.
# An empty string means unrestricted, so this function refuses it.
create_token() {
  local cluster_graphql_id="$1" description="$2" allowed_ips="$3" expires_at="$4"

  [ -n "${allowed_ips// /}" ] || {
    echo "refusing to create an unrestricted token: pass a space-separated CIDR list" >&2
    exit 1
  }
  assert_expiry_valid "${expires_at}"

  local body
  body="$(jq -n \
    --arg org "$(org_id)" \
    --arg cluster "${cluster_graphql_id}" \
    --arg desc "${description}" \
    --arg ips "${allowed_ips}" \
    --arg exp "${expires_at}" '{
      query: "mutation($org:ID!,$cluster:ID!,$desc:String!,$ips:String,$exp:DateTime){
                clusterAgentTokenCreate(input:{
                  organizationId:$org, clusterId:$cluster, description:$desc,
                  allowedIpAddresses:$ips, expiresAt:$exp
                }){ tokenValue clusterAgentToken { id uuid description expiresAt allowedIpAddresses } } }",
      variables: { org:$org, cluster:$cluster, desc:$desc, ips:$ips, exp:$exp }
    }' | gql)"
  assert_no_errors "${body}" >/dev/null

  # tokenValue is returned here and nowhere else, ever. Route it to a secret
  # manager on this line rather than letting it land in a shell history file.
  printf '%s' "${body}" | jq '.data.clusterAgentTokenCreate'
}

# REST equivalent. Path takes the cluster UUID; expires_at is the same ISO8601
# value with the same 10-minute floor and the same immutability.
rest_create_token() {
  local cluster_uuid="$1" description="$2" allowed_ips="$3" expires_at="$4"
  assert_expiry_valid "${expires_at}"
  jq -n --arg d "${description}" --arg ips "${allowed_ips}" --arg exp "${expires_at}" \
      '{description:$d, allowed_ip_addresses:$ips, expires_at:$exp}' \
  | curl -sS -X POST \
      -H "Authorization: Bearer ${BUILDKITE_TOKEN}" \
      -H "Content-Type: application/json" \
      --data @- \
      "${REST}/organizations/${BUILDKITE_ORG_SLUG}/clusters/${cluster_uuid}/tokens"
}
# HTH Guide Excerpt: end create-expiring-token

# HTH Guide Excerpt: begin revoke-and-contain
# Revoke a token. ClusterAgentTokenRevokeInput requires organizationId as well as
# the token id — passing id alone is rejected.
revoke_token() {
  local token_id="$1" body
  body="$(jq -n --arg org "$(org_id)" --arg id "${token_id}" '{
    query: "mutation($org:ID!,$id:ID!){ clusterAgentTokenRevoke(input:{organizationId:$org,id:$id}){ deletedClusterAgentTokenId } }",
    variables: { org:$org, id:$id }
  }' | gql)"
  assert_no_errors "${body}" >/dev/null
  printf '%s' "${body}" | jq '.data.clusterAgentTokenRevoke'
}

# REST equivalent — returns 204 with an empty body, so read the status code and
# do not try to parse output that will not exist.
rest_revoke_token() {
  local cluster_uuid="$1" token_id="$2" code
  code="$(curl -sS -o /dev/null -w '%{http_code}' -X DELETE \
    -H "Authorization: Bearer ${BUILDKITE_TOKEN}" \
    "${REST}/organizations/${BUILDKITE_ORG_SLUG}/clusters/${cluster_uuid}/tokens/${token_id}")"
  [ "${code}" = "204" ] || { echo "revoke failed: HTTP ${code}" >&2; exit 1; }
  echo "revoked ${token_id} (HTTP 204)"
}

# CONTAINMENT. This is the step the guide's Step 4 has no mechanism for.
# Revoking a leaked token closes the door for new registrations; it leaves every
# agent that already walked through it running jobs. Stop those agents too.
# graceful=true lets in-flight jobs finish; pass "false" when you believe the
# agent itself is hostile and you want it gone mid-job.
stop_cluster_agents() {
  local cluster_graphql_id="$1" graceful="${2:-true}" org body agent_ids
  org="$(org_id)"

  # NOTE: agents(cluster:) takes the base64 cluster ID. The UUID is rejected with
  # "An invalid ID was supplied" — verified against a live organization.
  body="$(jq -n --arg slug "${BUILDKITE_ORG_SLUG}" --arg c "${cluster_graphql_id}" '{
    query: "query($slug:ID!,$c:ID){ organization(slug:$slug){ agents(first:500, cluster:$c){ count edges { node { id name connectionState } } } } }",
    variables: { slug:$slug, c:$c }
  }' | gql)"
  assert_no_errors "${body}" >/dev/null

  agent_ids="$(printf '%s' "${body}" | jq -r '.data.organization.agents.edges[].node.id')"
  if [ -z "${agent_ids}" ]; then
    echo "no agents connected to ${cluster_graphql_id}; revocation alone is sufficient"
    return 0
  fi

  local id
  while IFS= read -r id; do
    [ -n "${id}" ] || continue
    jq -n --arg id "${id}" --argjson g "${graceful}" '{
      query: "mutation($id:ID!,$g:Boolean){ agentStop(input:{id:$id, graceful:$g}){ agent { id name connectionState } } }",
      variables: { id:$id, g:$g }
    }' | gql | jq -c '.data.agentStop.agent // .errors'
  done <<< "${agent_ids}"
}

# Full containment for a leaked token, in the order that actually contains it.
contain_leaked_token() {
  local cluster_graphql_id="$1" token_id="$2" graceful="${3:-true}"
  revoke_token "${token_id}"
  stop_cluster_agents "${cluster_graphql_id}" "${graceful}"
}
# HTH Guide Excerpt: end revoke-and-contain

usage() {
  cat >&2 <<'USAGE'
usage: hth-buildkite-3.01-agent-token-lifecycle.sh <subcommand> [args]

  audit                                              read-only; default
  rest-audit <cluster_uuid>                          read-only, REST surface
  expiry-in <days>                                   print an RFC3339 expiry N days out
  create <cluster_graphql_id> <desc> <cidrs> <expires_at>
  rest-create <cluster_uuid> <desc> <cidrs> <expires_at>
  revoke <token_id>
  rest-revoke <cluster_uuid> <token_id>
  stop-agents <cluster_graphql_id> [true|false]      graceful, default true
  contain <cluster_graphql_id> <token_id> [true|false]

<cidrs> is ONE space-separated string, e.g. "203.0.113.0/24 198.51.100.7/32".
USAGE
  exit 2
}

case "${1:-audit}" in
  audit)       audit_tokens ;;
  rest-audit)  rest_audit_tokens "${2:?cluster uuid required}" ;;
  expiry-in)   rfc3339_in_days "${2:?days required}" ;;
  create)      create_token "${2:?cluster graphql id}" "${3:?description}" "${4:?cidr list required — an empty allowlist means unrestricted}" "${5:-$(rfc3339_in_days 90)}" ;;
  rest-create) rest_create_token "${2:?cluster uuid}" "${3:?description}" "${4:?cidr list required — an empty allowlist means unrestricted}" "${5:-$(rfc3339_in_days 90)}" ;;
  revoke)      revoke_token "${2:?token id required}" ;;
  rest-revoke) rest_revoke_token "${2:?cluster uuid}" "${3:?token id}" ;;
  stop-agents) stop_cluster_agents "${2:?cluster graphql id}" "${3:-true}" ;;
  contain)     contain_leaked_token "${2:?cluster graphql id}" "${3:?token id}" "${4:-true}" ;;
  *)           usage ;;
esac
