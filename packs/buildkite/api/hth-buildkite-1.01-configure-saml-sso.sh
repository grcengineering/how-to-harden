#!/usr/bin/env bash
# =============================================================================
# HTH Buildkite Control 1.1: Configure SAML SSO
# Profile Level: L2 (Walk)
# Frameworks: CIS 5.3 | NIST IA-2
# Source: https://howtoharden.com/guides/buildkite/#11-configure-saml-sso
#
# WHY THIS IS AN api/ PACK AND NOT terraform/.
# The buildkite/buildkite provider (v1.19) exposes 21 resources and 16 data
# sources; NONE of them manage an SSO provider. This control was previously
# shipped as a .tf file containing only comments — a pack with no code, which
# reads as "automation exists" while automating nothing. The real surface is
# GraphQL: the ssoProvider* mutation family below was enumerated by live schema
# introspection against api.buildkite.com/v2/graphql.
#
# LOCKOUT WARNING — READ BEFORE RUNNING enable.
# ssoProviderEnable makes SSO the required path for organization members. If the
# IdP is misconfigured, or your own account cannot authenticate through it, you
# lose console access. Two mitigations, both mandatory:
#   1. Keep an API access token (this script's BUILDKITE_TOKEN) off-session. API
#      tokens authenticate independently of SSO, so ssoProviderDisable below is
#      your way back in.
#   2. Run `verify` first and confirm the provider is in a testable state.
# Buildkite requires each member to authorize the provider once before enforcement
# takes effect, so enabling on a fresh provider strands anyone who has not.
#
# Requires: BUILDKITE_TOKEN with GraphQL scope, BUILDKITE_ORG_SLUG.
# =============================================================================

set -euo pipefail

: "${BUILDKITE_TOKEN:?set BUILDKITE_TOKEN (GraphQL-enabled API access token)}"
: "${BUILDKITE_ORG_SLUG:?set BUILDKITE_ORG_SLUG}"

GQL="https://graphql.buildkite.com/v1"

gql() {
  curl -sS -X POST "${GQL}" \
    -H "Authorization: Bearer ${BUILDKITE_TOKEN}" \
    -H "Content-Type: application/json" \
    --data @-
}

# HTH Guide Excerpt: begin verify-sso
# Read the organization's current SSO providers, their state, and whether
# session-level enforcement is active. Run this BEFORE any mutation.
read_sso() {
  jq -n --arg slug "${BUILDKITE_ORG_SLUG}" '{
    query: "query($slug:ID!){ organization(slug:$slug){ id name
              ssoProviders(first:10){ edges { node {
                id state
                ... on SSOProviderSAML { sessionDurationInHours }
              } } } } }",
    variables: { slug: $slug }
  }' | gql
}

read_sso | jq '{
  organization: .data.organization.name,
  providers: [ .data.organization.ssoProviders.edges[].node
               | { id, state, sessionDurationInHours } ]
}'
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
# HTH Guide Excerpt: end enforce-sso

case "${1:-verify}" in
  verify)  ;;                                   # already printed above
  enable)  enable_sso "${2:?provider id required}"  | jq '.data.ssoProviderEnable' ;;
  disable) disable_sso "${2:?provider id required}" | jq '.data.ssoProviderDisable' ;;
  *) echo "usage: $0 [verify|enable <provider-id>|disable <provider-id>]" >&2; exit 2 ;;
esac
