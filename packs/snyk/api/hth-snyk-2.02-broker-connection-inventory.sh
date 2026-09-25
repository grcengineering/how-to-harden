#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: snyk-2.2
#   guide:   https://howtoharden.com/guides/snyk/#22-scm-integration-security
#   profile: L1
#   mode:    read-only
#   requires: SNYK_TOKEN(org.read; tenant.read for deployments), SNYK_ORG_ID, SNYK_TENANT_ID(optional), SNYK_ALLOWED_CONNECTION_TYPES(optional)
# =============================================================================
# HTH Snyk Control 2.2: SCM Integration Security
# Profile: L1 | NIST 800-53: CM-7
# https://howtoharden.com/guides/snyk/#22-scm-integration-security
#
# Inventories the Universal Broker connections an Organization uses, and the
# Tenant's Broker deployments, so every private-repo path Snyk has can be
# reviewed against need. Connections are created and scoped in the console
# (Settings -> Integrations -> Snyk Broker) or through the Universal Broker
# write endpoints; this pack only reads.
#
# Plan gate: Snyk Broker is an Enterprise capability.
# Endpoints (Snyk REST spec, Universal Broker, GA since 2024-10-15):
#   GET /orgs/{org_id}/brokers/connections        View Organization (org.read)
#   GET /tenants/{tenant_id}/brokers/deployments  View Tenant Details (tenant.read)
# Set SNYK_ALLOWED_CONNECTION_TYPES (comma-separated connection_type values;
# spaces around the commas are ignored) to turn the inventory into a gate:
# any other type is a finding.
#
# Exit codes: 0 read completed (and every type allowed, when an allow-list is set)
#             1 a connection type outside SNYK_ALLOWED_CONNECTION_TYPES
#             2 precondition, bad input, or a request that did not succeed
# Requires: curl, jq.
# Verified against:
#   https://docs.snyk.io/developer-tools/snyk-api/reference/universal-broker
#   https://docs.snyk.io/platform-administration/snyk-broker/universal-broker
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

# HTH Guide Excerpt: begin api-broker-connection-inventory
inventory_connections() {
  local org_id="$1" rows total types disallowed="" rc=0
  rows=$(snyk_list "${SNYK_API}/rest/orgs/${org_id}/brokers/connections?version=${SNYK_API_VERSION}&limit=100" \
    '[(.attributes.connection_type // "(none)"), (.attributes.name // "(unnamed)"),
      (.attributes.deployment_id // "(none)")] | @tsv') || return 2
  total=$(printf '%s' "${rows}" | grep -c . || true)
  echo "== Broker connections for orgs/${org_id}: ${total} =="
  echo "-- connection_type / name / deployment_id:"
  [ "${total}" -eq 0 ] || printf '%s\n' "${rows}" | sed 's/^/  /'
  if [ -n "${SNYK_ALLOWED_CONNECTION_TYPES:-}" ] && [ "${total}" -gt 0 ]; then
    types=$(printf '%s\n' "${rows}" | cut -f1 | sort -u) && [ -n "${types}" ] \
      || { echo "ERROR: could not list the connection types to compare" >&2; return 2; }
    disallowed=$(printf '%s\n' "${types}" \
      | grep -vxF -f <(printf '%s\n' "${SNYK_ALLOWED_CONNECTION_TYPES}" | tr ',' '\n' | tr -d '[:blank:]')) || rc=$?
    # grep exits 1 when every type is on the allow-list. Any other failure
    # means the comparison did not run, which must not read as "all allowed".
    if [ "${rc}" -gt 1 ]; then
      echo "ERROR: allow-list comparison failed (grep exit ${rc})" >&2; return 2
    fi
  fi
  if [ -n "${disallowed}" ]; then
    echo "FINDING: connection types outside SNYK_ALLOWED_CONNECTION_TYPES:"
    printf '%s\n' "${disallowed}" | sed 's/^/  /'
    return 1
  fi
}

inventory_deployments() {
  local tenant_id="$1" rows total
  rows=$(snyk_list "${SNYK_API}/rest/tenants/${tenant_id}/brokers/deployments?version=${SNYK_API_VERSION}&limit=100" \
    '[.id, (.attributes.broker_app_installed_in_org_id // "(none)"), (.attributes.updated_at // "n/a")] | @tsv') || return 2
  total=$(printf '%s' "${rows}" | grep -c . || true)
  echo "== Broker deployments for tenants/${tenant_id}: ${total} =="
  echo "-- deployment_id / installed_in_org / updated_at:"
  [ "${total}" -eq 0 ] || printf '%s\n' "${rows}" | sed 's/^/  /'
}
# HTH Guide Excerpt: end api-broker-connection-inventory

# HTH Guide Excerpt: begin api-broker-connection-inventory-run
if [ -z "${SNYK_ORG_ID:-}" ]; then
  echo "PRECONDITION: set SNYK_ORG_ID - Broker connections are listed per Organization" >&2; exit 2
fi
[[ "${SNYK_ORG_ID}" =~ ${UUID_RE} ]] || { echo "ERROR: SNYK_ORG_ID is not a UUID" >&2; exit 2; }
if [ -n "${SNYK_TENANT_ID:-}" ]; then
  [[ "${SNYK_TENANT_ID}" =~ ${UUID_RE} ]] || { echo "ERROR: SNYK_TENANT_ID is not a UUID" >&2; exit 2; }
  inventory_deployments "${SNYK_TENANT_ID}"
fi
inventory_connections "${SNYK_ORG_ID}"
# HTH Guide Excerpt: end api-broker-connection-inventory-run
