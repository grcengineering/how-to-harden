#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: bright-security-2.1
#   guide: https://howtoharden.com/guides/bright-security/
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq; BRIGHT_API_KEY with projects:read; BRIGHT_INTEGRATION_NAME for partner use
# HTH Guide Excerpt: begin audit-project-sample
set +x
set -euo pipefail
umask 077

token="${BRIGHT_API_KEY:?Set BRIGHT_API_KEY using your secret manager}"
integration="${BRIGHT_INTEGRATION_NAME:-}"
unset BRIGHT_API_KEY
[[ "$token" =~ ^[A-Za-z0-9._~+/=-]+$ ]] ||
  { printf '%s\n' 'Invalid API key format.' >&2; exit 2; }
args=()
if [[ -n "$integration" ]]; then
  [[ "$integration" =~ ^[A-Za-z0-9._[:space:]-]+$ ]] &&
    [[ "$integration" != *$'\n'* && "$integration" != *$'\r'* ]] ||
    { printf '%s\n' 'Invalid X-Bright-Integration value.' >&2; exit 2; }
  args=(--header "X-Bright-Integration: $integration")
fi
# The vendor partner guide requires an approved integration identity for partner traffic.
if [[ ${#args[@]} -eq 0 ]]; then
  args=(--header 'Accept: application/json')
fi
printf 'header = "Authorization: Api-Key %s"\n' "$token" |
  curl -q --config - --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 45 \
    "${args[@]}" --get --data-urlencode 'limit=100' --data-urlencode 'offset=0' \
    'https://app.brightsec.com/api/v2/projects' |
  jq -e '
    if type != "array" or any(.[]; type != "object") then error("Unexpected Bright project list")
    else {sampled: length, offset: 0, requestedLimit: 100, completenessVerified: false}
    end'

# HTH Guide Excerpt: end audit-project-sample
