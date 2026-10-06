#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: snyk-1.1
#   guide:   https://howtoharden.com/guides/snyk/#11-enforce-sso-with-mfa
#   profile: L1
#   mode:    read-only
#   requires: SNYK_TOKEN(group.sso.read and group.membership.read - Group Admin), SNYK_GROUP_ID
# =============================================================================
# HTH Snyk Control 1.1: Enforce SSO with MFA
# Profile: L1 | NIST 800-53: IA-2(1)
# https://howtoharden.com/guides/snyk/#11-enforce-sso-with-mfa
#
# PROVES the SSO half of the control; nothing here can SET it. Snyk's REST API
# exposes SSO configuration read-only (GET /groups/{group_id}/sso_connections)
# and has no endpoint that creates or changes an SSO connection, so the
# connection itself is configured in the console (Group -> Settings -> SSO).
# MFA is enforced in the identity provider: the Snyk platform has no native
# password and no Snyk-side MFA setting, so there is nothing in Snyk to read.
#
# Plan gate: SSO is available only on Enterprise plans.
# Endpoints (Snyk REST spec):
#   GET /groups/{group_id}/sso_connections  BETA (2023-01-30~beta)  group.sso.read
#   GET /groups/{group_id}/memberships      GA   (2024-08-25)       group.membership.read
# The membership read prints only a count per login method (never names or
# emails) so leftover social-login and personal accounts stand out for the
# Group -> Members clean-up the guide describes. Snyk documents login_method
# as a free-form string, so the pack reports the distribution and does not
# guess which values are "SSO".
#
# Exit codes: 0 at least one SSO connection | 1 no SSO connection (finding)
#             2 precondition, bad input, or a request that did not succeed
# Requires: curl, jq.
# Verified against:
#   https://docs.snyk.io/developer-tools/snyk-api/reference/groups
#   https://docs.snyk.io/platform-administration/user-management/single-sign-on-sso-for-authentication-to-snyk
set -euo pipefail

command -v curl >/dev/null || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq >/dev/null || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# HTH Guide Excerpt: begin api-snyk-rest-get-paginated
if [ -z "${SNYK_TOKEN:-}" ]; then
  echo "PRECONDITION: set SNYK_TOKEN - see the least-privilege note in this pack header" >&2; exit 2
fi
SNYK_API="${SNYK_API:-https://api.snyk.io}"
SNYK_API_VERSION="${SNYK_API_VERSION:-2024-10-15}"
SNYK_SSO_API_VERSION="${SNYK_SSO_API_VERSION:-2023-01-30~beta}"
UUID_RE='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
MAX_PAGES="${SNYK_MAX_PAGES:-1000}"

# One GET that fails closed: a transport error or any HTTP status >= 400
# aborts the audit instead of being read as an empty result.
snyk_get() {
  curl -sS -f \
    --header "Authorization: token ${SNYK_TOKEN}" \
    --header "Accept: application/vnd.api+json" \
    "$1"
}

# links.next arrives as a string or as {href}, absolute or relative to /rest.
# A link that leaves the configured API host is refused: the token would go
# with it.
next_url() {
  local next
  next=$(printf '%s' "$1" | jq -r '.links.next // empty | if type == "object" then .href else . end') || return 1
  case "${next}" in
    "") ;;
    "${SNYK_API}"/*) printf '%s' "${next}" ;;
    http://* | https://*) echo "ERROR: refusing to follow a pagination link to another host" >&2; return 1 ;;
    /rest/*) printf '%s' "${SNYK_API}${next}" ;;
    /*) printf '%s' "${SNYK_API}/rest${next}" ;;
    *) echo "ERROR: unrecognised pagination link" >&2; return 1 ;;
  esac
}

# Print one jq projection per item across every page of a list endpoint.
# Returns 2 on any failed request or on a body that is not a JSON:API list.
snyk_list() {
  local url="$1" projection="$2" page pages=0
  while [ -n "${url}" ]; do
    page=$(snyk_get "${url}") || { echo "ERROR: GET ${url%%\?*} did not succeed" >&2; return 2; }
    printf '%s' "${page}" | jq -e '.data | type == "array"' >/dev/null \
      || { echo "ERROR: response is not the documented JSON:API list" >&2; return 2; }
    printf '%s' "${page}" | jq -r ".data[] | ${projection}" || return 2
    pages=$((pages + 1))
    [ "${pages}" -lt "${MAX_PAGES}" ] || { echo "ERROR: pagination did not end after ${MAX_PAGES} pages" >&2; return 2; }
    url=$(next_url "${page}") || return 2
  done
}
# HTH Guide Excerpt: end api-snyk-rest-get-paginated

# HTH Guide Excerpt: begin api-sso-connection-audit
audit_sso() {
  local gid="$1" conns methods count
  conns=$(snyk_list "${SNYK_API}/rest/groups/${gid}/sso_connections?version=${SNYK_SSO_API_VERSION}&limit=100" \
    '.attributes.name // "(unnamed)"') || return 2
  count=$(printf '%s' "${conns}" | grep -c . || true)
  echo "== SSO connections for groups/${gid}: ${count} =="
  [ -z "${conns}" ] || printf '%s\n' "${conns}" | sed 's/^/  - /'

  methods=$(snyk_list "${SNYK_API}/rest/groups/${gid}/memberships?version=${SNYK_API_VERSION}&limit=100" \
    '.relationships.user.data.attributes.login_method // "(not reported)"') || return 2
  echo "== Group members by login method (count only) =="
  if [ -n "${methods}" ]; then
    printf '%s\n' "${methods}" | sort | uniq -c | sed 's/^ */  /'
  else
    echo "  (no group memberships returned)"
  fi
  echo "  Remove members who still sign in with social login or a personal account (Group -> Members)."

  if [ "${count}" -eq 0 ]; then
    echo "FINDING: groups/${gid} has no SSO connection - sign-in is not governed by your IdP"
    return 1
  fi
  echo "OK: SSO is configured; confirm MFA is enforced for the Snyk app in your IdP."
}
# HTH Guide Excerpt: end api-sso-connection-audit

# HTH Guide Excerpt: begin api-sso-connection-audit-run
if [ -z "${SNYK_GROUP_ID:-}" ]; then
  echo "PRECONDITION: set SNYK_GROUP_ID - SSO is configured per Group" >&2; exit 2
fi
[[ "${SNYK_GROUP_ID}" =~ ${UUID_RE} ]] || { echo "ERROR: SNYK_GROUP_ID is not a UUID" >&2; exit 2; }
audit_sso "${SNYK_GROUP_ID}"
# HTH Guide Excerpt: end api-sso-connection-audit-run
