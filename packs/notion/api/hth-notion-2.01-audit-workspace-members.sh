#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: notion-2.1
#   guide:   https://howtoharden.com/guides/notion/#21-configure-workspace-access
#   profile: L1
#   mode:    read-only
#   requires: NOTION_TOKEN(internal integration secret with "Read user information including email addresses"), ALLOWED_EMAIL_DOMAINS(comma-separated, required)
# =============================================================================
# HTH Notion Control 2.1: Configure Workspace Access
# Profile: L1 | CIS Controls: 5.4 | NIST 800-53: AC-6
# Dependencies: curl, jq
#
# Audits workspace membership via the Notion REST API: lists every user,
# separates person users from bot (integration) users, and flags members
# whose email domain is outside ALLOWED_EMAIL_DOMAINS.
# Endpoint: GET https://api.notion.com/v1/users (paginated with
# start_cursor/page_size; response carries results/has_more/next_cursor).
# The integration needs the user-information capability *including email
# addresses*; without it person.email is absent and every member is flagged
# as "email not visible".
# Docs: https://developers.notion.com/reference/get-users
#
# Fail-closed: there is no default domain list (a placeholder would flag
# everyone), any non-200 response is a precondition, and a run that saw zero
# person users is INCONCLUSIVE rather than a clean result.
# Exit codes: 0 compliant | 1 finding | 2 precondition / inconclusive
# =============================================================================
set -euo pipefail

[ -n "${NOTION_TOKEN:-}" ] || { echo "PRECONDITION: set NOTION_TOKEN — a Notion internal integration secret" >&2; exit 2; }
[ -n "${ALLOWED_EMAIL_DOMAINS:-}" ] || { echo "PRECONDITION: set ALLOWED_EMAIL_DOMAINS — comma-separated corporate email domains" >&2; exit 2; }
command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-notion.XXXXXX")"
USERS_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-notion-users.XXXXXX")"
trap 'rm -f "${BODY_FILE}" "${USERS_FILE}"' EXIT

# HTH Guide Excerpt: begin api-audit-workspace-members
NOTION_VERSION="2026-03-11"
cursor=""
calls=0
while :; do
  url="https://api.notion.com/v1/users?page_size=100"
  [ -n "${cursor}" ] && url="${url}&start_cursor=${cursor}"
  code=$(curl -sS -o "${BODY_FILE}" -w '%{http_code}' "${url}" \
    -H "Authorization: Bearer ${NOTION_TOKEN}" \
    -H "Notion-Version: ${NOTION_VERSION}") || code="000"
  if [ "${code}" != "200" ]; then
    echo "PRECONDITION: GET /v1/users returned HTTP ${code}: $(jq -r '.code // "no body"' "${BODY_FILE}" 2>/dev/null || echo unreadable)" >&2
    echo "  401 = invalid token; 403 = integration lacks the user-information capability." >&2
    exit 2
  fi
  jq -c '.results[]' "${BODY_FILE}" >> "${USERS_FILE}"
  calls=$((calls + 1))
  [ "$(jq -r '.has_more' "${BODY_FILE}")" = "true" ] || break
  cursor=$(jq -r '.next_cursor' "${BODY_FILE}")
  [ "${calls}" -lt 500 ] || { echo "PRECONDITION: pagination runaway guard hit" >&2; exit 2; }
done

report=$(jq -s --arg allowed "${ALLOWED_EMAIL_DOMAINS}" '
  ($allowed | ascii_downcase | split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(. != ""))) as $ok
  | {
      people: [ .[] | select(.type == "person") ],
      bots:   [ .[] | select(.type == "bot") | (.name // "(unnamed)") ]
    }
  | .flagged = [ .people[]
      | ((.person.email // "") | ascii_downcase) as $e
      | (if ($e | contains("@")) then ($e | split("@") | last) else "" end) as $d
      | select(($ok | index($d)) == null)
      | "\(.name // "(unnamed)") <\(if $e == "" then "email not visible" else $e end)>" ]
' "${USERS_FILE}")

n_people=$(jq '.people | length' <<<"${report}")
n_bots=$(jq '.bots | length' <<<"${report}")
n_flagged=$(jq '.flagged | length' <<<"${report}")
echo "${n_people} person user(s), ${n_bots} bot/integration user(s)"
jq -r '.bots[] | "  bot: \(.)"' <<<"${report}"

if [ "${n_people}" -eq 0 ]; then
  echo "INCONCLUSIVE: the API returned zero person users — nothing was audited" >&2
  exit 2
fi
if [ "${n_flagged}" -gt 0 ]; then
  echo "WARN: ${n_flagged} member(s) outside allowed email domains:"
  jq -r '.flagged[] | "  \(.)"' <<<"${report}"
  echo "Remove unauthorized members and restrict allowed email domains (control 2.1)."
  exit 1
fi
echo "PASS: all ${n_people} person user(s) are inside ${ALLOWED_EMAIL_DOMAINS}"
# HTH Guide Excerpt: end api-audit-workspace-members
