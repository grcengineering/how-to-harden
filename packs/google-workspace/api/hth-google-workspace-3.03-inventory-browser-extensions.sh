#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: google-workspace-3.3
#   guide: https://howtoharden.com/guides/google-workspace/#33-govern-managed-chrome-extensions-across-their-lifecycle
#   profile: L2
#   mode: read-only
#   requires: bash, curl, jq; authorized Chrome Management Reports access
# HTH 3.3: Read-only managed Chrome application inventory
# Profile: L2 (Walk); NIST 800-53 CM-8
# Guide: https://howtoharden.com/guides/google-workspace/#33
# Source: https://developers.google.com/chrome/management/reference/rest/v1/customers.reports/countInstalledApps
# OAuth scope: https://www.googleapis.com/auth/chrome.management.reports.readonly
# Requires browser reporting and the View Extensions List Report admin privilege.
# Outputs installed app records (apps as well as extensions); does not enforce policy.
# HTH Guide Excerpt: begin inventory-browser-extensions
set -euo pipefail
: "${HTH_PROFILE_LEVEL:=1}"
[[ "$HTH_PROFILE_LEVEL" =~ ^[234]$ ]] || { echo 'Requires HTH_PROFILE_LEVEL=2 or higher' >&2; exit 2; }
: "${GOOGLE_ACCESS_TOKEN:?Supply an authorized short-lived access token}"
customer="${GOOGLE_CUSTOMER_ID:-my_customer}"
[[ "$customer" =~ ^[A-Za-z0-9_-]+$ ]] || { echo 'Invalid customer ID' >&2; exit 1; }
# Bearer token must not become a curl option/config injection or process argument.
[[ "$GOOGLE_ACCESS_TOKEN" != *$'\r'* && "$GOOGLE_ACCESS_TOKEN" != *$'\n'* ]] || { echo 'Invalid token' >&2; exit 1; }
auth=${GOOGLE_ACCESS_TOKEN//\\/\\\\}
auth=${auth//\"/\\\"}
page_token=''
seen=()
umask 077
output=$(mktemp)
trap 'rm -f "$output"' EXIT
while :; do
  args=(-q --fail --silent --show-error --get --proto '=https'
    --connect-timeout 15 --max-time 60 --config -
    --data-urlencode 'pageSize=100')
  [[ -z "$page_token" ]] || args+=(--data-urlencode "pageToken=$page_token")
  response=$(printf 'header = "Authorization: Bearer %s"\n' "$auth" | curl "${args[@]}" "https://chromemanagement.googleapis.com/v1/customers/${customer}/reports:countInstalledApps")
  # Slurp ensures exactly one JSON object; an API error is not an empty inventory.
  jq -se 'length == 1 and (.[0] | type == "object" and (has("error") | not) and
    (.installedApps == null or (.installedApps | type == "array")) and
    (.nextPageToken == null or (.nextPageToken | type == "string")))' <<<"$response" >/dev/null
  jq -c '.installedApps[]?' <<<"$response" >> "$output"
  next=$(jq -r '.nextPageToken // empty' <<<"$response")
  [[ -n "$next" ]] || break
  for previous in ${seen[@]+"${seen[@]}"}; do
    [[ "$previous" != "$next" ]] || { echo 'Repeated pagination token; inventory incomplete' >&2; exit 1; }
  done
  seen+=("$next")
  page_token="$next"
done
# Emit only after every page succeeds, so late errors cannot appear complete.
cat "$output"
# HTH Guide Excerpt: end inventory-browser-extensions
