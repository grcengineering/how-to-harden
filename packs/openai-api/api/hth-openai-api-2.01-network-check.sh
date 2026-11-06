#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: openai-api-2.1
#   guide: https://howtoharden.com/guides/openai-api/#21-restrict-api-ingress-and-test-scope-precedence
#   profile: L2
#   mode: read-only
#   requires: OPENAI_API_KEY, curl, jq, an independently approved network test path
# Source: https://developers.openai.com/api/docs/guides/ip-allowlist
# NIST 800-53 AC-4. Run separately from allowed and disallowed egress paths.
source "$(dirname "$0")/common.sh"
: "${OPENAI_API_KEY:?Inject a project key through your approved secret manager}"
unset OPENAI_ADMIN_KEY
# HTH Guide Excerpt: begin network-check
umask 077
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
trap 'exit 1' HUP INT TERM
tmp="$work/body"
status=$(openai_http_to_file '/models' "$tmp") || exit 2
if [[ "$status" == 200 ]]; then
  echo 'API reachable from this egress path with this credential'
elif [[ "$status" == 401 ]] && jq -e '.error.code == "ip_not_authorized"' "$tmp" >/dev/null; then
  echo 'IP allowlist rejected this egress path' >&2
  exit 3
else
  echo "Inconclusive network check: HTTP ${status}; inspect authentication and permissions separately" >&2
  exit 2
fi
# HTH Guide Excerpt: end network-check
