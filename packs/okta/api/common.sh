#!/usr/bin/env bash
# HTH Okta Code Pack -- Common Utilities
# Source this file: source "$(dirname "$0")/common.sh"
#
# Required environment variables:
#   OKTA_DOMAIN       -- Your Okta domain (e.g., yourorg.okta.com)
#   OKTA_API_TOKEN    -- SSWS API token. An SSWS token carries no scopes of its own:
#                        it inherits the admin role of the user who created it, so
#                        mint audit-only tokens as a Read-Only Administrator.
#   HTH_PROFILE_LEVEL -- 1 (Crawl), 2 (Walk), 3 (Run) [default: 1]
#
# https://howtoharden.com/guides/okta/

set -euo pipefail

# Required environment variables
: "${OKTA_DOMAIN:?Set OKTA_DOMAIN (e.g., yourorg.okta.com)}"
: "${OKTA_API_TOKEN:?Set OKTA_API_TOKEN}"
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

OKTA_BASE="https://${OKTA_DOMAIN}"

# ---------------------------------------------------------------------------
# HTTP helpers -- thin wrappers around curl for Okta API calls.
#
# * The SSWS token reaches curl on a file descriptor (-H @<(printf ...)), never
#   as a command-line argument, so it does not appear in `ps` output. printf is
#   a shell builtin, so no child process sees the token in its argv.
# * Every call checks the HTTP status. A transport error or a non-2xx response
#   prints a [FAIL] line to stderr and returns non-zero. Callers must let that
#   failure stop the pack -- never mask it with `|| echo "[]"` or `|| true`:
#   an audit whose read failed has scanned nothing and must not report
#   "nothing found".
# * On success the response body is written to stdout (raw JSON; pipe to jq).
# ---------------------------------------------------------------------------
_okta_call_failed() {
  echo -e "${RED}[FAIL]${NC} Okta API $1 $2 -> $3" >&2
}

_okta_request() {
  local method=$1 path=$2 body=${3-} response status
  if [ -n "${body}" ]; then
    response=$(curl -sS -X "${method}" "${OKTA_BASE}${path}" \
      -H @<(printf 'Authorization: SSWS %s\n' "${OKTA_API_TOKEN}") \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      --data-binary "${body}" \
      -w $'\n%{http_code}') || { _okta_call_failed "${method}" "${path}" "transport error"; return 1; }
  else
    response=$(curl -sS -X "${method}" "${OKTA_BASE}${path}" \
      -H @<(printf 'Authorization: SSWS %s\n' "${OKTA_API_TOKEN}") \
      -H "Accept: application/json" \
      -w $'\n%{http_code}') || { _okta_call_failed "${method}" "${path}" "transport error"; return 1; }
  fi
  status=${response##*$'\n'}
  response=${response%$'\n'*}
  case "${status}" in
    2??) printf '%s' "${response}" ;;
    *)   _okta_call_failed "${method}" "${path}" "HTTP ${status}"; return 1 ;;
  esac
}

okta_get()    { _okta_request GET    "$1"; }
okta_post()   { _okta_request POST   "$1" "$2"; }
okta_put()    { _okta_request PUT    "$1" "$2"; }
okta_delete() { _okta_request DELETE "$1"; }

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
  echo -e "${BLUE}  How to Harden -- Okta API Hardening${NC}"
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
HTH_SUMMARY_DONE=0

increment_applied()  { CONTROLS_APPLIED=$((CONTROLS_APPLIED + 1)); }
increment_skipped()  { CONTROLS_SKIPPED=$((CONTROLS_SKIPPED + 1)); }
increment_failed()   { CONTROLS_FAILED=$((CONTROLS_FAILED + 1)); }

# Prints the summary and exits 1 when any control failed, so a pack that
# printed [FAIL] can never finish with exit code 0.
summary() {
  HTH_SUMMARY_DONE=1
  echo ""
  echo -e "${BLUE}================================================================${NC}"
  echo -e "${BLUE}  Summary${NC}"
  echo -e "${GREEN}  Applied: ${CONTROLS_APPLIED}${NC}"
  echo -e "${YELLOW}  Skipped: ${CONTROLS_SKIPPED}${NC}"
  echo -e "${RED}  Failed:  ${CONTROLS_FAILED}${NC}"
  echo -e "${BLUE}================================================================${NC}"
  if [ "${CONTROLS_FAILED}" -gt 0 ]; then
    exit 1
  fi
}

# A pack stopped by `set -e` (for example, by a failed API read) exits before
# it reaches summary(). Say so, and keep the non-zero exit status.
_hth_on_exit() {
  local rc=$?
  if [ "${HTH_SUMMARY_DONE}" -eq 0 ] && [ "${rc}" -ne 0 ]; then
    echo -e "${RED}[FAIL]${NC} Pack aborted (exit ${rc}) before completing -- no result above is conclusive" >&2
  fi
  exit "${rc}"
}
trap _hth_on_exit EXIT
