#!/usr/bin/env bash
# HTH Cloudflare Code Pack -- Common Utilities
# Source this file: source "$(dirname "$0")/common.sh"
#
# Required environment variables:
#   CF_API_TOKEN      -- Cloudflare API token with Zero Trust permissions
#   CF_ACCOUNT_ID     -- Your Cloudflare account ID
#   HTH_PROFILE_LEVEL -- 1 (Crawl), 2 (Walk), 3 (Run) [default: 1]
#
# Optional:
#   HTH_APPLY=1       -- permit a pack that can WRITE to perform that write.
#                        Packs that create or change tenant objects (1.01,
#                        3.01-3.04, 4.01, 4.02) only report what they would
#                        change unless this is set.
#
# Exit codes: 0 = no check failed (compliant, or skipped because nothing
# applied) | 1 = at least one check failed or could not be completed.
# summary() sets the exit code, so a caller (CI, `op run`) sees a [FAIL].
#
# https://howtoharden.com/guides/cloudflare/

set -euo pipefail

# Required environment variables
: "${CF_API_TOKEN:?Set CF_API_TOKEN (Cloudflare API token)}"
: "${CF_ACCOUNT_ID:?Set CF_ACCOUNT_ID (Cloudflare account ID)}"
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"
HTH_APPLY="${HTH_APPLY:-0}"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

CF_API="https://api.cloudflare.com/client/v4"
AUTH_HEADER="Authorization: Bearer ${CF_API_TOKEN}"

# ---------------------------------------------------------------------------
# HTTP helpers -- thin wrappers around curl for Cloudflare API v4
# All return raw JSON; pipe to jq for formatting
# ---------------------------------------------------------------------------
# cf_get fails (returns 1, prints nothing) unless the response is a JSON object
# that does not report success:false. A 200 carrying an HTML page from a proxy,
# a truncated body, or an API-level failure must reach the caller as a fetch
# error: every pack treats a failed cf_get as "audit incomplete", whereas a body
# jq cannot parse would otherwise read as an empty list -- a false pass.
cf_get() {
  local body
  body=$(curl -sf -X GET "${CF_API}$1" \
    -H "${AUTH_HEADER}" \
    -H "Content-Type: application/json") || return 1
  printf '%s\n' "${body}" | jq -e 'type == "object" and .success != false' >/dev/null 2>&1 || return 1
  printf '%s\n' "${body}"
}

cf_post() {
  curl -sf -X POST "${CF_API}$1" \
    -H "${AUTH_HEADER}" \
    -H "Content-Type: application/json" \
    -d "$2"
}

cf_put() {
  curl -sf -X PUT "${CF_API}$1" \
    -H "${AUTH_HEADER}" \
    -H "Content-Type: application/json" \
    -d "$2"
}

cf_patch() {
  curl -sf -X PATCH "${CF_API}$1" \
    -H "${AUTH_HEADER}" \
    -H "Content-Type: application/json" \
    -d "$2"
}

cf_delete() {
  curl -sf -X DELETE "${CF_API}$1" \
    -H "${AUTH_HEADER}" \
    -H "Content-Type: application/json"
}

# ---------------------------------------------------------------------------
# cf_get_all PATH -- read EVERY page of a paginated list endpoint and print a
# single {"result":[...]} document. Whether another page follows comes from
# result_info: total_pages if present, else total_count / per_page; if the
# response carries neither, a full page means another page may follow, so it
# is read too. If any page fails to load the whole call fails -- an audit must
# never mistake the first page for the whole list. Pages are merged through
# stdin (never argv), so large accounts do not hit the argument-size limit.
# per_page=50 is within the documented bounds of every list endpoint the packs
# page through (tokens and members allow at most 50).
# ---------------------------------------------------------------------------
CF_PER_PAGE=50
cf_get_all() {
  local path=$1 sep='?' page=1 more=1 resp acc='[]'
  case "${path}" in *\?*) sep='&' ;; esac
  while [ "${more}" = "1" ]; do
    resp=$(cf_get "${path}${sep}page=${page}&per_page=${CF_PER_PAGE}") || return 1
    acc=$(printf '%s\n%s\n' "${acc}" "${resp}" | jq -cs '.[0] + (.[1].result // [])') || return 1
    more=$(printf '%s\n' "${resp}" | jq -r --argjson page "${page}" --argjson pp "${CF_PER_PAGE}" '
      (.result // []) as $r | (.result_info // {}) as $i
      | if $i.total_pages != null then (if $page < $i.total_pages then 1 else 0 end)
        elif $i.total_count != null then (if ($page * ($i.per_page // $pp)) < $i.total_count then 1 else 0 end)
        elif ($r | length) >= $pp then 1
        else 0 end') || return 1
    page=$((page + 1))
    [ "${page}" -le 1000 ] || return 1
  done
  printf '%s\n' "${acc}" | jq -c '{result: .}'
}

# ---------------------------------------------------------------------------
# Gateway expression helpers (jq). Prepend to a jq program:
#   jq "${JQ_GATEWAY_DEFS}"'[.result[] | select(positive_traffic | test("..."))]'
# positive_traffic is the rule's traffic expression with every negated part
# removed -- not(...) groups (including nested ones) and "x != y" comparisons --
# so a rule such as not(net.dst.port == 22) is not mistaken for a rule that
# blocks port 22. Gateway negates with not(...) and != only
# (developers.cloudflare.com/cloudflare-one/traffic-policies/expression-syntax/).
# ---------------------------------------------------------------------------
JQ_GATEWAY_DEFS='
def strip_negated_groups:
  (gsub("not\\s*\\([^()]*\\)"; " NEGATED ")
   | gsub("\\((?<inner>[^()]*)\\)"; "‹\(.inner)›")) as $next
  | if $next == . then . else ($next | strip_negated_groups) end;
def positive_traffic:
  (.traffic // "")
  | gsub("[A-Za-z0-9_.*\\[\\]]+\\s*!=\\s*(\"[^\"]*\"|[^\\s()]+)"; " NEGATED ")
  | strip_negated_groups;
'

# ---------------------------------------------------------------------------
# Profile level gate -- skip controls above current level
# Usage: should_apply 2 || return 0
# ---------------------------------------------------------------------------
should_apply() {
  local required_level=$1
  if [ "${HTH_PROFILE_LEVEL}" -lt "${required_level}" ]; then
    echo -e "${YELLOW}[SKIP]${NC} Requires L${required_level} (current: L${HTH_PROFILE_LEVEL})"
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Write gate -- every write is opt-in
# Usage: may_write "create the DNS blocking rule" || { increment_failed; summary; exit 0; }
# Returns 0 only when HTH_APPLY=1. Otherwise reports the write it would have
# made and returns 1, so a default run never changes the tenant.
# ---------------------------------------------------------------------------
may_write() {
  if [ "${HTH_APPLY}" = "1" ]; then
    return 0
  fi
  echo -e "${YELLOW}[DRY-RUN]${NC} Would $1 -- re-run with HTH_APPLY=1 to apply"
  return 1
}

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------
info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
pass()  { echo -e "${GREEN}[PASS]${NC} $1"; }
fail()  { echo -e "${RED}[FAIL]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
banner() {
  echo ""
  echo -e "${BLUE}================================================================${NC}"
  echo -e "${BLUE}  How to Harden -- Cloudflare Zero Trust API Hardening${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}  Profile Level: L${HTH_PROFILE_LEVEL}${NC}"
  echo -e "${BLUE}================================================================${NC}"
  echo ""
}

# ---------------------------------------------------------------------------
# Counters for summary reporting
# ---------------------------------------------------------------------------
CONTROLS_APPLIED=0
CONTROLS_SKIPPED=0
CONTROLS_FAILED=0

increment_applied()  { CONTROLS_APPLIED=$((CONTROLS_APPLIED + 1)); }
increment_skipped()  { CONTROLS_SKIPPED=$((CONTROLS_SKIPPED + 1)); }
increment_failed()   { CONTROLS_FAILED=$((CONTROLS_FAILED + 1)); }

summary() {
  echo ""
  echo -e "${BLUE}================================================================${NC}"
  echo -e "${BLUE}  Summary${NC}"
  echo -e "${GREEN}  Applied: ${CONTROLS_APPLIED}${NC}"
  echo -e "${YELLOW}  Skipped: ${CONTROLS_SKIPPED}${NC}"
  echo -e "${RED}  Failed:  ${CONTROLS_FAILED}${NC}"
  echo -e "${BLUE}================================================================${NC}"
  # A failed or incomplete check is a non-zero exit, never a silent 0
  if [ "${CONTROLS_FAILED}" -gt 0 ]; then
    exit 1
  fi
}
