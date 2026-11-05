#!/usr/bin/env bash
# HTH Anthropic Claude — Shared helpers for Admin API scripts
# Requires: ANTHROPIC_ADMIN_KEY (sk-ant-admin01-...) environment variable
# API Docs: https://platform.claude.com/docs/en/manage-claude/admin-api

set -euo pipefail
umask 077

# ── Configuration ──────────────────────────────────────────────────────
ANTHROPIC_API_BASE="${ANTHROPIC_API_BASE:-https://api.anthropic.com}"
[[ "${ANTHROPIC_API_BASE}" == 'https://api.anthropic.com' ]] || { echo 'ERROR: only the first-party HTTPS API is supported by these packs.' >&2; exit 2; }
ANTHROPIC_VERSION="${ANTHROPIC_VERSION:-2026-10-21}"
# Page size for list endpoints. The Admin API defaults to 20 and accepts 1-1000
# (platform.claude.com/docs/en/api/admin/users/list), so ask for the maximum.
ANTHROPIC_PAGE_LIMIT="${ANTHROPIC_PAGE_LIMIT:-1000}"
if ! [[ "${ANTHROPIC_PAGE_LIMIT}" =~ ^[0-9]+$ ]] || (( ANTHROPIC_PAGE_LIMIT < 1 || ANTHROPIC_PAGE_LIMIT > 1000 )); then
  echo "ERROR: ANTHROPIC_PAGE_LIMIT must be an integer from 1 to 1000." >&2
  exit 1
fi
for _hth_dep in curl jq; do
  command -v "${_hth_dep}" >/dev/null 2>&1 || { echo "ERROR: ${_hth_dep} is required." >&2; exit 1; }
done

# ── Colour helpers ─────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'

info()  { printf "${BLUE}[INFO]${NC}  %s\n" "$*"; }
pass()  { printf "${GREEN}[PASS]${NC}  %s\n" "$*"; APPLIED=$((APPLIED+1)); }
fail()  { printf "${RED}[FAIL]${NC}  %s\n" "$*"; FAILED=$((FAILED+1)); }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; SKIPPED=$((SKIPPED+1)); }

APPLIED=0; FAILED=0; SKIPPED=0

banner() {
  echo ""
  printf "${BLUE}━━━ HTH Anthropic Claude: %s ━━━${NC}\n" "$1"
  echo ""
}

summary() {
  echo ""
  (( FAILED == 0 )) || exit 1
  printf "${BLUE}──── Summary ────${NC}\n"
  printf "  Applied: ${GREEN}%d${NC}  Failed: ${RED}%d${NC}  Skipped: ${YELLOW}%d${NC}\n" \
    "${APPLIED}" "${FAILED}" "${SKIPPED}"
  echo ""
}

# ── Auth check ─────────────────────────────────────────────────────────
require_admin_key() {
  if [[ -z "${ANTHROPIC_ADMIN_KEY:-}" ]]; then
    echo "ERROR: ANTHROPIC_ADMIN_KEY is not set." >&2
    echo "Provision an Admin API key at: https://platform.claude.com/settings/admin-keys" >&2
    exit 1
  fi
  [[ "${ANTHROPIC_ADMIN_KEY}" != *[[:space:]]* ]] || { echo 'ERROR: credential contains whitespace.' >&2; exit 2; }
}

# ── HTTP helpers ───────────────────────────────────────────────────────
# The admin key reaches curl as a header FILE (-H @<(...)), never as an
# argument: anything in curl's argv is readable by other local processes via
# `ps` for as long as the request runs (CWE-214). printf is a shell builtin, so
# the key appears in no process's arguments. Every helper uses -f, so an HTTP
# 4xx/5xx (401 bad key, 403, 429) or a transport failure is a non-zero exit.
_anthropic_key_header() {
  printf 'x-api-key: %s\n' "${ANTHROPIC_ADMIN_KEY}"
}

_anthropic_request() {
  local method="$1" path="$2" body="${3:-}" response
  [[ "${path}" == /v1/* && "${path}" != *[[:space:]]* && "${path}" != *'#'* ]] || return 2
  [[ "${ANTHROPIC_VERSION}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || return 2
  [[ -z "${HTH_ANTHROPIC_BETA:-}" || "${HTH_ANTHROPIC_BETA}" =~ ^[a-z0-9,-]+$ ]] || return 2
  require_admin_key
  if [[ "${method}" != GET && "${HTH_APPLY:-0}" != 1 ]]; then
    echo 'ERROR: mutation refused; review the exact target and set HTH_APPLY=1 deliberately.' >&2
    return 2
  fi
  local args=(-q --silent --show-error --fail --globoff --proto '=https' --connect-timeout 10 --max-time 30
    --request "${method}" --header @- --header "anthropic-version: ${ANTHROPIC_VERSION}")
  [[ -z "${HTH_ANTHROPIC_BETA:-}" ]] || args+=(--header "anthropic-beta: ${HTH_ANTHROPIC_BETA}")
  if [[ -n "${body}" ]]; then
    printf '%s' "${body}" | jq -se 'length == 1 and (.[0] | type == "object")' >/dev/null || return 2
    args+=(--header 'Content-Type: application/json' --data "${body}")
  fi
  # -q disables ~/.curlrc. No redirect following, retries, trace, or secret in argv.
  response=$(_anthropic_key_header | curl "${args[@]}" "${ANTHROPIC_API_BASE}${path}") || { echo 'ERROR: API request failed; no complete evidence returned.' >&2; return 1; }
  printf '%s' "${response}" | jq -cse 'if length == 1 and (.[0] | type == "object") then .[0] else error("expected one response object") end'
}

anthropic_get() { _anthropic_request GET "$1"; }

anthropic_post() {
  local path="$1"
  # Default body is an empty JSON object. Never write the default inline as a
  # brace inside ${2:-...}: bash ends the expansion at the FIRST closing brace,
  # so a literal brace is appended to every body a caller passes and each POST
  # sends invalid JSON (bash 3.2 and 5.x alike).
  local body="${2:-}"
  [[ -n "${body}" ]] || body='{}'
  _anthropic_request POST "${path}" "${body}"
}

anthropic_delete() {
  local path="$1"
  _anthropic_request DELETE "${path}"
}

# Paginated list helper. The Admin API pages with has_more + last_id: pass a
# page's last_id back as after_id to get the next page. There is no `next_page`
# field. The helper fails closed: a failed call, a body without a `data` array,
# or has_more=true with no usable last_id returns 1 and prints nothing, so a
# caller can never mistake a truncated list for a complete one. `path` may
# already carry a query string (e.g. ?status=active).
anthropic_list_all() {
  local path="$1"
  local sep='?'
  [[ "${path}" == *\?* ]] && sep='&'
  local base="${path}${sep}limit=${ANTHROPIC_PAGE_LIMIT}"
  local url="${base}" results='[]' response page_data has_more last_id encoded seen='|' pages=0
  while true; do
    response=$(anthropic_get "${url}") || return 1
    page_data=$(printf '%s' "${response}" | jq -ce 'if (.data | type) == "array" then .data else error("no data array") end') || return 1
    results=$(printf '%s\n%s\n' "${results}" "${page_data}" | jq -cs 'add') || return 1
    has_more=$(printf '%s' "${response}" | jq -er 'if (.has_more | type) == "boolean" then .has_more | tostring else error("has_more is required") end') || return 1
    [[ "${has_more}" == "true" ]] || break
    last_id=$(printf '%s' "${response}" | jq -er '.last_id | select(type == "string" and length > 0 and length < 4096)') || return 1
    encoded=$(printf '%s' "${last_id}" | jq -sRr @uri) || return 1
    [[ "${seen}" != *"|${encoded}|"* ]] || { echo 'ERROR: repeated pagination cursor.' >&2; return 1; }
    seen="${seen}${encoded}|"
    pages=$((pages + 1))
    (( pages < 10000 )) || { echo "ERROR: ${path}: pagination did not terminate." >&2; return 1; }
    url="${base}&after_id=${encoded}"
  done
  printf '%s\n' "${results}"
}

# Usage/cost and page-token Compliance families use page/next_page.
# The Activity Feed uses anthropic_list_all (after_id/last_id).
# Returns an array only after every page has succeeded; an empty page may carry a cursor.
anthropic_report_all() {
  local path="$1" response cursor encoded url="$1" results='[]' seen='|' more pages=0 sep='?'
  [[ "${path}" != *\?* ]] || sep='&'
  while true; do
    response=$(anthropic_get "${url}") || return 1
    printf '%s' "${response}" | jq -e '(.data | type) == "array" and (.has_more | type) == "boolean"' >/dev/null || return 1
    results=$(printf '%s\n%s' "${results}" "${response}" | jq -cs '.[0] + .[1].data') || return 1
    more=$(printf '%s' "${response}" | jq -r '.has_more')
    [[ "${more}" == true ]] || break
    cursor=$(printf '%s' "${response}" | jq -er '.next_page | select(type == "string" and length > 0 and length < 4096)') || return 1
    encoded=$(printf '%s' "${cursor}" | jq -sRr @uri) || return 1
    [[ "${seen}" != *"|${encoded}|"* ]] || return 1
    seen="${seen}${encoded}|"
    pages=$((pages + 1)); (( pages < 10000 )) || return 1
    url="${path}${sep}page=${encoded}"
  done
  printf '%s\n' "${results}"
}

# Evidence always lands in a newly created private directory, never a caller-owned symlink.
anthropic_evidence_dir() {
  umask 077
  mktemp -d "${TMPDIR:-/tmp}/hth-anthropic.XXXXXXXX"
}

# PageCursor families use next_page without has_more (e.g. workspace rate limits).
anthropic_page_token_all() {
  local path="$1" url="$1" response cursor encoded results='[]' seen='|' pages=0 sep='?'
  [[ "${path}" != *\?* ]] || sep='&'
  while true; do
    response=$(anthropic_get "${url}") || return 1
    printf '%s' "${response}" | jq -e '(.data | type) == "array" and has("next_page") and (.next_page == null or ((.next_page | type) == "string" and (.next_page | length) > 0 and (.next_page | length) < 4096))' >/dev/null || return 1
    results=$(printf '%s\n%s' "${results}" "${response}" | jq -cs '.[0] + .[1].data') || return 1
    cursor=$(printf '%s' "${response}" | jq -r '.next_page // empty') || return 1
    [[ -n "${cursor}" ]] || break
    encoded=$(printf '%s' "${cursor}" | jq -sRr @uri) || return 1
    [[ "${seen}" != *"|${encoded}|"* ]] || return 1
    seen="${seen}${encoded}|"
    pages=$((pages+1)); (( pages<10000 )) || return 1
    url="${path}${sep}page=${encoded}"
  done
  printf '%s\n' "${results}"
}
