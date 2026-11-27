#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: bird-email-2.1
#   guide:   https://howtoharden.com/guides/bird-email/
#   profile: L2
#   mode:    read-only
#   requires: BIRD_EMAIL_REGION, BIRD_EXPECTED_WORKSPACE_ID, BIRD_EXPECTED_SENDING_DOMAIN, BIRD_EMAIL_DOMAIN_ID, BIRD_EMAIL_READ_KEY (domains:read), curl, jq
# First-party source: https://bird.com/en-gb/docs/api/reference/get-domain
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
region=${BIRD_EMAIL_REGION:?Set us1 or eu1}
workspace=${BIRD_EXPECTED_WORKSPACE_ID:?Set expected ws_ ID}
domain=${BIRD_EXPECTED_SENDING_DOMAIN:?Set the exact approved DNS sending domain}
id=${BIRD_EMAIL_DOMAIN_ID:?Set approved dom_ ID}
[[ "$region" =~ ^(us1|eu1)$ && "$workspace" =~ ^ws_[a-z0-9]+$ && "$id" =~ ^dom_[a-z0-9]+$ ]] || exit 2
[[ "$domain" =~ ^[a-z0-9.-]+$ ]] || exit 2

token=${BIRD_EMAIL_READ_KEY:?Set an authorized bearer credential}
[[ "$token" != *$'\r'* && "$token" != *$'\n'* ]] || exit 2

[[ "$token" == "bk_${region}_"* ]] || exit 2

body=$(printf 'Authorization: Bearer %s\n' "$token" |
  curl -q --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 40 --header @- "https://$region.platform.bird.com/v1/email/domains/$id")

result=$(jq -ce --arg id "$id" --arg ws "$workspace" --arg domain "$domain" '
  if .id==$id and .workspace_id==$ws and .domain==$domain
    and (.status|IN("pending","verified","failed","temporary_failure","rejected"))
    and (.capabilities.sending.status|IN("pending","verified","warning","failed","temporary_failure","not_configured"))
  then {id, workspace_id, domain, ownership_status:.status,
        sending_status:.capabilities.sending.status,
        verified:(.status=="verified" and .capabilities.sending.status=="verified")}
  else error("Bird sending domain identity or verification state not verified") end
' <<<"$body")
printf '%s\n' "$result"
jq -e '.verified' <<<"$result" >/dev/null
# HTH Guide Excerpt: end read-evidence
