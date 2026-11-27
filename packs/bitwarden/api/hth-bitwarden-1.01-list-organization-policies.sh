#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: bitwarden-1.1
#   guide: https://howtoharden.com/guides/bitwarden/#11-require-two-step-login-or-enforced-sso
#   profile: L1
#   mode: read-only
#   requires: Bash, curl, jq, BITWARDEN_ORG_BEARER_TOKEN, BITWARDEN_REGION(optional), BITWARDEN_CONTINUATION_TOKEN(optional)
# Bitwarden 1.1 | L1 | NIST IA-2 | https://howtoharden.com/guides/bitwarden/#11-require-two-step-login-or-enforced-sso
# Evidence only: https://bitwarden.com/help/public-api/
# HTH Guide Excerpt: begin list-bitwarden-policy-page
set +x
set -euo pipefail

: "${BITWARDEN_ORG_BEARER_TOKEN:?Inject a short-lived organization API bearer token}"
[[ "$BITWARDEN_ORG_BEARER_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || exit 2
case "${BITWARDEN_REGION:-us}" in
  us) api=https://api.bitwarden.com ;;
  eu) api=https://api.bitwarden.eu ;;
  *) printf '%s\n' 'BITWARDEN_REGION must be us or eu' >&2; exit 2 ;;
esac

query=(--get)
if [[ -n "${BITWARDEN_CONTINUATION_TOKEN:-}" ]]; then
  query+=(--data-urlencode "continuationToken=$BITWARDEN_CONTINUATION_TOKEN")
fi
response=$(
  printf 'Authorization: Bearer %s\n' "$BITWARDEN_ORG_BEARER_TOKEN" |
    curl -q --fail --silent --show-error --proto '=https' --max-time 30 \
      --header @- "${query[@]+${query[@]}}" "$api/public/policies"
)
jq -e '
    if (.data | type) != "array" then error("not a policy list")
    elif (.continuationToken != null and (.continuationToken | type) != "string") then error("invalid continuation token")
    elif any(.data[]; ((.id | type) != "string") or ((.enabled | type) != "boolean") or (.type == null)) then error("invalid policy metadata")
    else {policies: [.data[] | {id, type, enabled}], continuationToken}
    end' <<< "$response"
# HTH Guide Excerpt: end list-bitwarden-policy-page
