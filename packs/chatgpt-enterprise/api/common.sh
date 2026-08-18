set -euo pipefail

# Shared helpers for OpenAI ChatGPT Enterprise Compliance API scripts.
# Compliance API base + auth are documented at:
#   https://help.openai.com/en/articles/9261474-compliance-apis-for-enterprise-customers
#   https://developers.openai.com/cookbook/examples/chatgpt/compliance_api/logs_platform

CHATGPT_COMPLIANCE_BASE="${CHATGPT_COMPLIANCE_BASE:-https://api.chatgpt.com/v1/compliance}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'

info()  { printf "${BLUE}[INFO]${NC}  %s\n" "$*"; }
pass()  { printf "${GREEN}[PASS]${NC}  %s\n" "$*"; APPLIED=$((APPLIED+1)); }
fail()  { printf "${RED}[FAIL]${NC}  %s\n" "$*"; FAILED=$((FAILED+1)); }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; SKIPPED=$((SKIPPED+1)); }

APPLIED=0; FAILED=0; SKIPPED=0

banner() {
  echo ""
  printf "${BLUE}━━━ HTH ChatGPT Enterprise: %s ━━━${NC}\n" "$1"
  echo ""
}

summary() {
  echo ""
  printf "${BLUE}──── Summary ────${NC}\n"
  printf "  Applied: ${GREEN}%d${NC}  Failed: ${RED}%d${NC}  Skipped: ${YELLOW}%d${NC}\n" \
    "${APPLIED}" "${FAILED}" "${SKIPPED}"
  echo ""
}

require_compliance_key() {
  if [[ -z "${COMPLIANCE_API_KEY:-}" ]]; then
    echo "ERROR: COMPLIANCE_API_KEY is not set."
    echo "Provision one in the ChatGPT Global Admin Console:"
    echo "  Global Admin Console → API keys → Compliance API key"
    exit 1
  fi
  if [[ -z "${OPENAI_PRINCIPAL_ID:-}" ]]; then
    echo "ERROR: OPENAI_PRINCIPAL_ID is not set."
    echo "Set to your workspace ID (UUID) or organization ID (starts with 'org-')."
    exit 1
  fi
}

# Derive scope segment from principal ID. org-* → organizations, otherwise workspaces.
compliance_scope() {
  if [[ "${OPENAI_PRINCIPAL_ID}" == org-* ]]; then
    echo "organizations"
  else
    echo "workspaces"
  fi
}

# List logs of a given event_type since an ISO 8601 timestamp.
# Usage: compliance_list_logs <event_type> <after_iso8601> [limit]
compliance_list_logs() {
  local event_type="$1"
  local after="$2"
  local limit="${3:-100}"
  local scope
  scope=$(compliance_scope)

  curl -sf -G "${CHATGPT_COMPLIANCE_BASE}/${scope}/${OPENAI_PRINCIPAL_ID}/logs" \
    -H "Authorization: Bearer ${COMPLIANCE_API_KEY}" \
    --data-urlencode "limit=${limit}" \
    --data-urlencode "event_type=${event_type}" \
    --data-urlencode "after=${after}"
}

# Download the JSONL body of a single log file by ID.
compliance_download_log() {
  local log_id="$1"
  local scope
  scope=$(compliance_scope)

  curl -sf -L "${CHATGPT_COMPLIANCE_BASE}/${scope}/${OPENAI_PRINCIPAL_ID}/logs/${log_id}" \
    -H "Authorization: Bearer ${COMPLIANCE_API_KEY}"
}

# Paginated puller. Walks has_more / last_end_time until exhausted.
# Emits one log ID per line on stdout.
compliance_paginate_log_ids() {
  local event_type="$1"
  local after="$2"
  local limit="${3:-100}"
  local cursor="${after}"

  while :; do
    local resp
    resp=$(compliance_list_logs "${event_type}" "${cursor}" "${limit}") || return 1
    echo "${resp}" | jq -r '.data[].id'
    local has_more
    has_more=$(echo "${resp}" | jq -r '.has_more // false')
    [[ "${has_more}" == "true" ]] || break
    cursor=$(echo "${resp}" | jq -r '.last_end_time // empty')
    [[ -n "${cursor}" ]] || break
  done
}
