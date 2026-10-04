#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: notion-3.1
#   guide:   https://howtoharden.com/guides/notion/#31-configure-sharing-controls
#   profile: L1
#   mode:    read-only
#   requires: NOTION_TOKEN(internal integration secret with "Read content", shared with the pages to audit)
# =============================================================================
# HTH Notion Control 3.1: Configure Sharing Controls
# Profile: L1 | CIS Controls: 3.3 | NIST 800-53: AC-3
# Dependencies: curl, jq
#
# Finds pages published to the open web. The Notion page object carries a
# public_url field: "The public page URL if the page has been published to
# the web. Otherwise, null." Enumerates pages via POST /v1/search with the
# object=page filter. Search only returns pages shared with the integration,
# so share the content you need audited with it (page ··· → Connections).
# Docs: https://developers.notion.com/reference/page
#       https://developers.notion.com/reference/post-search
#
# Fail-closed: an audit that scanned zero pages proves nothing, so it exits 2
# (INCONCLUSIVE) instead of printing a clean result. Any non-200 is exit 2.
# Search is a read; curl implies POST from -d, so no -X flag is written.
# Exit codes: 0 compliant | 1 finding | 2 precondition / inconclusive
# =============================================================================
set -euo pipefail

[ -n "${NOTION_TOKEN:-}" ] || { echo "PRECONDITION: set NOTION_TOKEN — a Notion internal integration secret" >&2; exit 2; }
command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-notion.XXXXXX")"
PAGES_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-notion-pages.XXXXXX")"
trap 'rm -f "${BODY_FILE}" "${PAGES_FILE}"' EXIT

# HTH Guide Excerpt: begin api-audit-public-pages
NOTION_VERSION="2026-03-11"
cursor=""
calls=0
while :; do
  payload=$(jq -nc --arg c "${cursor}" \
    '{filter: {property: "object", value: "page"}, page_size: 100}
     + (if $c == "" then {} else {start_cursor: $c} end)')
  code=$(curl -sS -o "${BODY_FILE}" -w '%{http_code}' "https://api.notion.com/v1/search" \
    -H "Authorization: Bearer ${NOTION_TOKEN}" \
    -H "Notion-Version: ${NOTION_VERSION}" \
    -H "Content-Type: application/json" \
    -d "${payload}") || code="000"
  if [ "${code}" != "200" ]; then
    echo "PRECONDITION: POST /v1/search returned HTTP ${code}: $(jq -r '.code // "no body"' "${BODY_FILE}" 2>/dev/null || echo unreadable)" >&2
    exit 2
  fi
  jq -c '.results[]' "${BODY_FILE}" >> "${PAGES_FILE}"
  calls=$((calls + 1))
  [ "$(jq -r '.has_more' "${BODY_FILE}")" = "true" ] || break
  cursor=$(jq -r '.next_cursor' "${BODY_FILE}")
  [ "${calls}" -lt 500 ] || { echo "PRECONDITION: pagination runaway guard hit" >&2; exit 2; }
done

scanned=$(jq -s 'length' "${PAGES_FILE}")
public=$(jq -s '[ .[] | select(.public_url != null and .public_url != "") ]' "${PAGES_FILE}")
n_public=$(jq 'length' <<<"${public}")
echo "scanned ${scanned} page(s) shared with this integration"

if [ "${scanned}" -eq 0 ]; then
  echo "INCONCLUSIVE: 0 pages are shared with this integration — share the content to audit (page ··· → Connections) and re-run" >&2
  exit 2
fi
if [ "${n_public}" -gt 0 ]; then
  echo "WARN: ${n_public} page(s) reachable by anyone on the internet:"
  jq -r '.[] | "  \(.id)\tlast_edited=\(.last_edited_time)\t\(.public_url)"' <<<"${public}"
  echo "Unpublish any page not deliberately public (control 3.1)."
  exit 1
fi
echo "PASS: none of the ${scanned} scanned page(s) is published to the web"
# HTH Guide Excerpt: end api-audit-public-pages
