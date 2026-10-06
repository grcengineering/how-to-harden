#!/usr/bin/env bash
# HTH Anthropic Claude — Shared helpers for Admin API scripts
# Requires: ANTHROPIC_ADMIN_KEY (sk-ant-admin01-...) environment variable
# API Docs: https://platform.claude.com/docs/en/manage-claude/admin-api

set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────
ANTHROPIC_API_BASE="${ANTHROPIC_API_BASE:-https://api.anthropic.com}"
ANTHROPIC_VERSION="${ANTHROPIC_VERSION:-2023-06-01}"
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

anthropic_get() {
  local path="$1"
  curl -sf "${ANTHROPIC_API_BASE}${path}" \
    -H @<(_anthropic_key_header) \
    -H "anthropic-version: ${ANTHROPIC_VERSION}" \
    -H "Content-Type: application/json"
}

anthropic_post() {
  local path="$1"
  # Default body is an empty JSON object. Never write the default inline as a
  # brace inside ${2:-...}: bash ends the expansion at the FIRST closing brace,
  # so a literal brace is appended to every body a caller passes and each POST
  # sends invalid JSON (bash 3.2 and 5.x alike).
  local body="${2:-}"
  [[ -n "${body}" ]] || body='{}'
  curl -sf "${ANTHROPIC_API_BASE}${path}" \
    -X POST \
    -H @<(_anthropic_key_header) \
    -H "anthropic-version: ${ANTHROPIC_VERSION}" \
    -H "Content-Type: application/json" \
    -d "${body}"
}

anthropic_delete() {
  local path="$1"
  curl -sf "${ANTHROPIC_API_BASE}${path}" \
    -X DELETE \
    -H @<(_anthropic_key_header) \
    -H "anthropic-version: ${ANTHROPIC_VERSION}"
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
  local url="${base}" results='[]' response page_data has_more last_id pages=0
  while true; do
    response=$(anthropic_get "${url}") || return 1
    page_data=$(printf '%s' "${response}" | jq -ce 'if (.data | type) == "array" then .data else error("no data array") end') || return 1
    results=$(printf '%s\n%s\n' "${results}" "${page_data}" | jq -cs 'add') || return 1
    has_more=$(printf '%s' "${response}" | jq -r '.has_more // false') || return 1
    [[ "${has_more}" == "true" ]] || break
    last_id=$(printf '%s' "${response}" | jq -r '.last_id // empty') || return 1
    if ! [[ "${last_id}" =~ ^[A-Za-z0-9_-]+$ ]]; then
      echo "ERROR: ${path}: has_more=true without a usable last_id; refusing to return a partial list." >&2
      return 1
    fi
    pages=$((pages + 1))
    (( pages < 10000 )) || { echo "ERROR: ${path}: pagination did not terminate." >&2; return 1; }
    url="${base}&after_id=${last_id}"
  done
  printf '%s\n' "${results}"
}
