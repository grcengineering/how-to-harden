#!/usr/bin/env bash
# HTH Sentry Control 3.2: Configure DSN Security
# Profile: L1 | CIS Controls: 3.11 | NIST 800-53: SC-12
# https://howtoharden.com/guides/sentry/#32-configure-dsn-security
#
# Audits a project's client keys (DSNs) via the Sentry Web API, flags keys
# without a rate limit, applies a rate limit, and deactivates compromised
# keys. Requires: curl, jq, an auth token with project:read (audit) and
# project:write (changes).
# Verified against:
#   https://docs.sentry.io/api/projects/list-a-projects-client-keys/
#   https://docs.sentry.io/api/projects/update-a-client-key/
set -euo pipefail

command -v curl >/dev/null || { echo "ERROR: curl not found" >&2; exit 1; }
command -v jq >/dev/null || { echo "ERROR: jq not found" >&2; exit 1; }

# HTH Guide Excerpt: begin api-dsn-key-audit
: "${SENTRY_AUTH_TOKEN:?Set SENTRY_AUTH_TOKEN to an auth token with project:read}"
SENTRY_ORG="${SENTRY_ORG:?Set SENTRY_ORG to your organization slug}"
SENTRY_PROJECT="${SENTRY_PROJECT:?Set SENTRY_PROJECT to the project slug}"
SENTRY_URL="${SENTRY_URL:-https://sentry.io}"

KEYS=$(curl -sf \
  -H "Authorization: Bearer ${SENTRY_AUTH_TOKEN}" \
  "${SENTRY_URL}/api/0/projects/${SENTRY_ORG}/${SENTRY_PROJECT}/keys/")

echo "== Client keys for ${SENTRY_ORG}/${SENTRY_PROJECT} =="
echo "${KEYS}" | jq -r '.[] |
  [ .id, .name,
    (if .isActive then "active" else "inactive" end),
    (if .rateLimit == null then "NO-RATE-LIMIT" else
      "\(.rateLimit.count)/\(.rateLimit.window)s" end),
    .dateCreated
  ] | @tsv'

UNLIMITED=$(echo "${KEYS}" | jq '[.[] | select(.isActive and .rateLimit == null)] | length')
if [ "${UNLIMITED}" -gt 0 ]; then
  echo "FAIL: ${UNLIMITED} active key(s) have no rate limit - event flooding on a leaked DSN is uncapped"
else
  echo "PASS: every active client key carries a rate limit"
fi
# HTH Guide Excerpt: end api-dsn-key-audit

# HTH Guide Excerpt: begin api-dsn-set-rate-limit
# Cap a key at e.g. 300 events per 60-second window (tune to your traffic):
KEY_ID="${1:?Usage: $0 <key_id> [deactivate]}"
if [ "${2:-}" != "deactivate" ]; then
  curl -sf -X PUT \
    -H "Authorization: Bearer ${SENTRY_AUTH_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{"rateLimit": {"window": 60, "count": 300}}' \
    "${SENTRY_URL}/api/0/projects/${SENTRY_ORG}/${SENTRY_PROJECT}/keys/${KEY_ID}/" \
    | jq '{id, name, isActive, rateLimit}'
fi
# HTH Guide Excerpt: end api-dsn-set-rate-limit

# HTH Guide Excerpt: begin api-dsn-deactivate-compromised-key
# Rotation flow for a leaked DSN: create a replacement key in the console,
# move clients over, then deactivate the compromised key:
if [ "${2:-}" = "deactivate" ]; then
  curl -sf -X PUT \
    -H "Authorization: Bearer ${SENTRY_AUTH_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{"isActive": false}' \
    "${SENTRY_URL}/api/0/projects/${SENTRY_ORG}/${SENTRY_PROJECT}/keys/${KEY_ID}/" \
    | jq '{id, name, isActive}'
fi
# HTH Guide Excerpt: end api-dsn-deactivate-compromised-key
