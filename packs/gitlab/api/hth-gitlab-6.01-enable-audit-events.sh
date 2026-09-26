#!/usr/bin/env bash
# HTH GitLab Control 6.1: Enable Audit Events
# Profile: L1 | NIST: AU-2, AU-3, AU-6 | SOC 2: CC7.2
# https://howtoharden.com/guides/gitlab/#61-enable-audit-events
#
# Required: GROUP_ID environment variable (or pass as $1)
# Exit codes: 0 compliant | 1 finding | 2 precondition (an API call failed, so the state is unknown)
source "$(dirname "$0")/common.sh"

GROUP_ID="${GROUP_ID:-${1:-}}"
: "${GROUP_ID:?Set GROUP_ID or pass as first argument}"

# GraphQL helper -- audit event streaming destinations are exposed through the
# GraphQL API (docs.gitlab.com/api/graphql/audit_event_streaming_groups).
# A read_api token is sufficient for queries. Like gl_get, a non-2xx status is
# reported on stderr and returns non-zero.
gl_graphql() {
  local out code
  out=$(curl -sS -X POST "${GITLAB_URL}/api/graphql" \
    -H "Authorization: Bearer ${GITLAB_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$1" \
    -w '\n%{http_code}') || { gl_explain_status POST /api/graphql 000; return 1; }
  code="${out##*$'\n'}"
  case "${code}" in
    2??) printf '%s' "${out%$'\n'*}" ;;
    *)   gl_explain_status POST /api/graphql "${code}"; return 1 ;;
  esac
}

banner "6.1: Enable Audit Events (Group: ${GROUP_ID})"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "6.1 Querying audit events for group ${GROUP_ID}..."
STATE_UNKNOWN=0

# HTH Guide Excerpt: begin api-query-audit-events
# Query group-level audit events and verify audit logging is active.
# GitLab Premium/Ultimate exposes audit events via the REST API.
info "6.1 Retrieving recent audit events..."
AUDIT_EVENTS=$(gl_get "/groups/${GROUP_ID}/audit_events?per_page=20") || {
  fail "6.1 Failed to retrieve audit events (HTTP status above; a 403 means GitLab Premium/Ultimate and the group Owner role are required)"
  increment_failed
  summary
  exit 2
}

EVENT_COUNT=$(printf '%s' "${AUDIT_EVENTS}" | jq 'length')
info "6.1 Retrieved ${EVENT_COUNT} recent audit event(s)"

if [ "${EVENT_COUNT}" -gt 0 ]; then
  # Show recent security-relevant events
  printf '%s' "${AUDIT_EVENTS}" | jq -r '.[] | "  - [\(.created_at)] \(.author.name // .author_id): \(.entity_type)/\(.details.action // .details.custom_message // "event")"'

  # Check for key security event types
  info "6.1 Checking for security-relevant event categories..."
  AUTH_EVENTS=$(printf '%s' "${AUDIT_EVENTS}" | jq '[.[] | select(.details.action // "" | test("auth|login|session"; "i"))] | length')
  PERM_EVENTS=$(printf '%s' "${AUDIT_EVENTS}" | jq '[.[] | select(.details.action // "" | test("permission|role|access"; "i"))] | length')
  REPO_EVENTS=$(printf '%s' "${AUDIT_EVENTS}" | jq '[.[] | select(.details.action // "" | test("push|merge|branch|tag"; "i"))] | length')

  info "6.1 Event breakdown: auth=${AUTH_EVENTS}, permissions=${PERM_EVENTS}, repository=${REPO_EVENTS}"
fi

# Check for audit event streaming destinations (L2; Ultimate, top-level group Owner).
# A failed query is reported as unknown -- never as "no destinations configured".
if should_apply 2 2>/dev/null; then
  info "6.1 L2: Checking external audit event streaming destinations..."
  GROUP_PATH=$(gl_get "/groups/${GROUP_ID}" | jq -r '.full_path // empty') || GROUP_PATH=""
  # externalAuditEventStreamingDestinations covers every category (HTTP, Google
  # Cloud Logging, Amazon S3); the three per-type fields are deprecated in
  # GitLab 18.10 but still hold destinations created the older way.
  QUERY='query($fullPath: ID!) { group(fullPath: $fullPath) {
    externalAuditEventStreamingDestinations { nodes { name category active } }
    externalAuditEventDestinations { nodes { name active } }
    googleCloudLoggingConfigurations { nodes { name active } }
    amazonS3Configurations { nodes { name active } } } }'
  BODY=$(jq -n --arg q "${QUERY}" --arg p "${GROUP_PATH}" '{query: $q, variables: {fullPath: $p}}')
  STREAMS=""
  if [ -n "${GROUP_PATH}" ]; then
    STREAMS=$(gl_graphql "${BODY}") || STREAMS=""
  fi
  if [ -z "${STREAMS}" ] || [ "$(printf '%s' "${STREAMS}" | jq '((.errors // []) | length) == 0 and .data.group != null')" != "true" ]; then
    fail "6.1 L2: Could not read streaming destinations (an HTTP status above is the cause; with none, the query returned no group -- Ultimate and the Owner role on a top-level group are required)"
    STATE_UNKNOWN=1
  else
    # A destination can appear under both the new and a legacy field, so list
    # them rather than sum them.
    DESTS=$(printf '%s' "${STREAMS}" | jq -r '.data.group as $g |
      [ ($g.externalAuditEventStreamingDestinations.nodes // [])[] | "\(.category): \(.name) (active: \(.active))" ] +
      [ ($g.externalAuditEventDestinations.nodes // [])[] | "http: \(.name) (active: \(.active))" ] +
      [ ($g.googleCloudLoggingConfigurations.nodes // [])[] | "gcpLogging: \(.name) (active: \(.active))" ] +
      [ ($g.amazonS3Configurations.nodes // [])[] | "amazonS3: \(.name) (active: \(.active))" ] | unique | .[]')
    if [ -n "${DESTS}" ]; then
      pass "6.1 Audit event streaming destination(s) configured:"
      printf '%s\n' "${DESTS}" | sed 's/^/  - /'
    else
      warn "6.1 No external audit event streaming destinations configured"
      warn "6.1 Configure via Secure > Audit events > Streams to forward to your SIEM"
    fi
  fi
fi
# HTH Guide Excerpt: end api-query-audit-events

if [ "${EVENT_COUNT}" -gt 0 ]; then
  pass "6.1 Audit events are accessible and logging is active"
  increment_applied
else
  warn "6.1 No audit events found -- verify GitLab tier (Premium/Ultimate required) and token permissions"
  increment_failed
fi

summary
[ "${STATE_UNKNOWN}" -eq 0 ] || exit 2
[ "${CONTROLS_FAILED}" -eq 0 ] || exit 1
