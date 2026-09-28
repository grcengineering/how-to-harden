#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: slack-3.3
#   guide:   https://howtoharden.com/guides/slack/#33-govern-slack-mcp-server-and-ai-agent-access
#   profile: L2
#   mode:    read-only
#   requires: SLACK_ADMIN_TOKEN(admin.apps:read user token — Enterprise only)
# =============================================================================
# HTH Slack Control 3.3: Govern Slack MCP Server and AI Agent Access — MCP allowlist audit
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 2.5, 3.3 | NIST 800-53 AC-3, AC-6, CM-7
# Source: https://docs.slack.dev/reference/methods/admin.apps.mcp.servers.list
#         https://docs.slack.dev/reference/methods/admin.apps.mcp.servers.permissions.list
# Dependencies: curl (7.55+ for -H @file), jq
# Usage: bash hth-slack-3.03-list-mcp-servers.sh [app_id ...]
#
# Lists the third-party app MCP servers approved for the org (derived from the
# org's MCP server allowlist). Entries reflect allowlist state, not install or
# scope liveness: servers of apps that were uninstalled but not deleted are
# still listed, which is exactly what a review should catch. For each app_id
# passed as an argument it also prints that app's MCP servers with their access
# control permissions.
#
# Slack does not publish the response schema for these two methods, so each
# page is printed verbatim minus the envelope fields (ok, response_metadata)
# rather than parsed against guessed field names. POST is their documented
# transport; they only read. Fails CLOSED on a non-200 status or "ok": false,
# on a repeated pagination cursor, and on an "ok": true envelope that carries
# no data field at all: with no published schema, a bare {} cannot be told
# apart from a response this script does not understand, so it is never
# reported as an empty allowlist (an explicit empty list still prints).
# =============================================================================
set -euo pipefail

# HTH Guide Excerpt: begin api-list-mcp-servers
: "${SLACK_ADMIN_TOKEN:?set SLACK_ADMIN_TOKEN (admin.apps:read)}"

slack_post() {  # slack_post <method> [curl --data-urlencode args ...]
  local method="$1" out code body
  shift
  out="$(curl -sS "https://slack.com/api/${method}" \
    -H @<(printf 'Authorization: Bearer %s\n' "${SLACK_ADMIN_TOKEN}") \
    "$@" -w '\n%{http_code}')"
  code="${out##*$'\n'}"
  body="${out%$'\n'*}"
  [ "${code}" = "200" ] || { echo "${method} failed: HTTP ${code}" >&2; exit 1; }
  if [ "$(printf '%s' "${body}" | jq -r '.ok')" != "true" ]; then
    echo "${method} failed: $(printf '%s' "${body}" | jq -r '.error // "unknown"')" >&2
    exit 1
  fi
  printf '%s' "${body}"
}

print_data() {  # print_data <method> <body>: the page minus its envelope
  local data
  data="$(printf '%s' "$2" | jq -c 'del(.ok, .response_metadata)')"
  if [ "${data}" = "{}" ]; then
    echo "$1: ok but no data fields; not a confirmed empty list, check the console" >&2
    exit 1
  fi
  printf '%s\n' "${data}"
}

cursor=""
seen=" "
while :; do
  page="$(slack_post admin.apps.mcp.servers.list \
    --data-urlencode "limit=100" --data-urlencode "cursor=${cursor}")"
  print_data admin.apps.mcp.servers.list "${page}"
  cursor="$(printf '%s' "${page}" | jq -r '.response_metadata.next_cursor // ""')"
  [ -n "${cursor}" ] || break
  case "${seen}" in *" ${cursor} "*) echo "admin.apps.mcp.servers.list: pagination cursor repeated, listing incomplete" >&2; exit 1 ;; esac
  seen="${seen}${cursor} "
done

for app_id in "$@"; do
  echo "permissions for ${app_id}:"
  print_data admin.apps.mcp.servers.permissions.list \
    "$(slack_post admin.apps.mcp.servers.permissions.list --data-urlencode "app_id=${app_id}")"
done
# HTH Guide Excerpt: end api-list-mcp-servers
