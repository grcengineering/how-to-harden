#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: snyk-2.1
#   guide:   https://howtoharden.com/guides/snyk/#21-secure-service-account-tokens
#   profile: L1
#   mode:    mutating
#   requires: SNYK_TOKEN(org.service_account.read or group.service_account.read; --delete also needs *.service_account.delete), SNYK_ORG_ID and/or SNYK_GROUP_ID
# =============================================================================
# HTH Snyk Control 2.1: Secure Service Account Tokens
# Profile: L1 | NIST 800-53: IA-5
# https://howtoharden.com/guides/snyk/#21-secure-service-account-tokens
#
# The default invocation is READ-ONLY (GET requests only). It audits every
# service account at group and/or org level and flags the credential types the
# guide treats as standing risk: api_key (never expires, legacy, not
# recommended) and access_token (1-year ceiling, no in-place rotation). The
# contract says mode: mutating because the same file carries one explicit,
# opt-in write:
#   hth-snyk-2.01-service-account-token-audit.sh --delete <orgs|groups> <scope_id> <service_account_id>
#
# Plan gate: service accounts are available only on Enterprise plans; Free and
# Team organizations have personal tokens only.
#
# Least privilege (the "Required permissions" of each endpoint in Snyk's REST spec):
#   GET    /orgs/{org_id}/service_accounts          org.service_account.read   (Org Admin, Group Viewer)
#   GET    /groups/{group_id}/service_accounts      group.service_account.read (Group Admin)
#   DELETE /orgs/{org_id}/service_accounts/{id}     org.service_account.delete
#   DELETE /groups/{group_id}/service_accounts/{id} group.service_account.delete
# Lists page with limit (default 10, max 100) and links.next; every page is read.
#
# Exit codes: 0 no finding | 1 finding (api_key or unrecognised auth_type)
#             2 precondition, bad input, or a request that did not succeed
# Requires: curl, jq.
# Verified against:
#   https://docs.snyk.io/platform-administration/service-accounts/service-accounts
#   https://docs.snyk.io/developer-tools/snyk-api/reference/serviceaccounts
#   https://docs.snyk.io/developer-tools/snyk-api/authentication-for-api
set -euo pipefail

command -v curl >/dev/null || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq >/dev/null || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# HTH Guide Excerpt: begin api-snyk-rest-get-paginated
if [ -z "${SNYK_TOKEN:-}" ]; then
  echo "PRECONDITION: set SNYK_TOKEN - see the least-privilege note in this pack header" >&2; exit 2
fi
SNYK_API="${SNYK_API:-https://api.snyk.io}"
SNYK_API_VERSION="${SNYK_API_VERSION:-2024-10-15}"
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
# HTH Guide Excerpt: end api-snyk-rest-get-paginated

# HTH Guide Excerpt: begin api-service-account-credential-audit
FINDINGS=0

# Audit one scope: "groups <group_id>" or "orgs <org_id>".
audit_service_accounts() {
  local scope="$1" scope_id="$2" url page count=0 pages=0 n bad
  url="${SNYK_API}/rest/${scope}/${scope_id}/service_accounts?version=${SNYK_API_VERSION}&limit=100"
  echo "== Service accounts for ${scope}/${scope_id} =="
  while [ -n "${url}" ]; do
    page=$(snyk_get "${url}") \
      || { echo "ERROR: GET ${scope}/${scope_id}/service_accounts did not succeed" >&2; return 2; }
    printf '%s' "${page}" | jq -e '.data | type == "array"' >/dev/null \
      || { echo "ERROR: response is not the documented JSON:API list" >&2; return 2; }
    # auth_type is one of api_key, access_token, oauth_client_secret,
    # oauth_private_key_jwt. Anything else is reported, never assumed safe.
    printf '%s' "${page}" | jq -r '.data[] | .attributes |
      [ .name,
        (.auth_type // "(none)"),
        (.access_token_expires_at // "n/a"),
        (if .auth_type == "api_key" then
           "FAIL: legacy API key - never expires, migrate to OAuth 2.0"
         elif .auth_type == "access_token" then
           "WARN: 1-year max expiry, no in-place rotation - plan replacement"
         elif ((.auth_type // "") | startswith("oauth_")) then
           "PASS: OAuth 2.0 short-lived credential"
         else
           "UNKNOWN: unrecognised auth_type - review"
         end)
      ] | @tsv'
    n=$(printf '%s' "${page}" | jq '.data | length')
    bad=$(printf '%s' "${page}" | jq '[.data[] | (.attributes.auth_type // "")
      | select(. == "api_key" or (. != "access_token" and (startswith("oauth_") | not)))] | length')
    count=$((count + n))
    FINDINGS=$((FINDINGS + bad))
    pages=$((pages + 1))
    [ "${pages}" -lt "${MAX_PAGES}" ] || { echo "ERROR: pagination did not end after ${MAX_PAGES} pages" >&2; return 2; }
    url=$(next_url "${page}") || return 2
  done
  echo "-- ${count} service account(s) audited in ${scope}/${scope_id}"
}
# HTH Guide Excerpt: end api-service-account-credential-audit

# HTH Guide Excerpt: begin api-delete-legacy-service-account
# Remove a flagged legacy service account once its workload is migrated to an
# OAuth 2.0 service account (deletion also kills its API key). Opt-in only:
#   --delete <orgs|groups> <scope_id> <service_account_id>
delete_service_account() {
  local scope="$1" scope_id="$2" sa_id="$3"
  case "${scope}" in
    orgs | groups) ;;
    *) echo "ERROR: scope must be orgs or groups" >&2; return 2 ;;
  esac
  if ! [[ "${scope_id}" =~ ${UUID_RE} && "${sa_id}" =~ ${UUID_RE} ]]; then
    echo "ERROR: scope_id and service_account_id must be UUIDs" >&2; return 2
  fi
  curl -sS -f -X DELETE \
    --header "Authorization: token ${SNYK_TOKEN}" \
    "${SNYK_API}/rest/${scope}/${scope_id}/service_accounts/${sa_id}?version=${SNYK_API_VERSION}" >/dev/null \
    || { echo "ERROR: DELETE did not succeed for ${scope}/${scope_id} service account ${sa_id}" >&2; return 2; }
  echo "Deleted service account ${sa_id} from ${scope}/${scope_id}"
}
# HTH Guide Excerpt: end api-delete-legacy-service-account

# HTH Guide Excerpt: begin api-service-account-audit-run
case "${1:-}" in
  --delete)
    if [ "$#" -ne 4 ]; then
      echo "Usage: $0 --delete <orgs|groups> <scope_id> <service_account_id>" >&2; exit 2
    fi
    delete_service_account "$2" "$3" "$4"
    exit 0 ;;
  "") ;;
  *) echo "Usage: $0 [--delete <orgs|groups> <scope_id> <service_account_id>]" >&2; exit 2 ;;
esac

if [ -z "${SNYK_GROUP_ID:-}" ] && [ -z "${SNYK_ORG_ID:-}" ]; then
  echo "ERROR: set SNYK_GROUP_ID and/or SNYK_ORG_ID - nothing to audit" >&2; exit 2
fi
for scope in groups orgs; do
  if [ "${scope}" = groups ]; then scope_id="${SNYK_GROUP_ID:-}"; else scope_id="${SNYK_ORG_ID:-}"; fi
  [ -n "${scope_id}" ] || continue
  [[ "${scope_id}" =~ ${UUID_RE} ]] || { echo "ERROR: the ${scope} id is not a UUID" >&2; exit 2; }
  audit_service_accounts "${scope}" "${scope_id}"
done

if [ "${FINDINGS}" -gt 0 ]; then
  echo "FINDING: ${FINDINGS} service account(s) use an api_key or an unrecognised auth_type"
  exit 1
fi
echo "No api_key or unrecognised service-account credential types found."
# HTH Guide Excerpt: end api-service-account-audit-run
