#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: redis-cloud-1.2
#   guide: https://howtoharden.com/guides/redis-cloud/#12-limit-database-source-networks
#   profile: L1
#   mode: read-only
#   requires: Bash, curl, jq, REDIS_CLOUD_PLAN, REDIS_CLOUD_SUBSCRIPTION_ID, REDIS_CLOUD_DATABASE_ID, REDIS_CLOUD_ACCOUNT_KEY, REDIS_CLOUD_USER_KEY
# Vendor contract: https://github.com/RedisLabs/rediscloud-go-api/tree/v0.52.1/service
# HTH Guide Excerpt: begin inspect-database-source-ranges
set +x
set -euo pipefail

: "${REDIS_CLOUD_PLAN:?Set essentials or pro for the approved database}"
: "${REDIS_CLOUD_SUBSCRIPTION_ID:?Set the approved subscription ID}"
: "${REDIS_CLOUD_DATABASE_ID:?Set the approved database ID}"
: "${REDIS_CLOUD_ACCOUNT_KEY:?Inject the approved Cloud account key}"
: "${REDIS_CLOUD_USER_KEY:?Inject the approved Cloud user key}"
id_pattern='^[1-9][0-9]{0,14}$'
[[ "$REDIS_CLOUD_SUBSCRIPTION_ID" =~ $id_pattern && "$REDIS_CLOUD_DATABASE_ID" =~ $id_pattern ]] || exit 2
key_pattern='^[A-Za-z0-9._~+/=-]+$'
[[ "$REDIS_CLOUD_ACCOUNT_KEY" =~ $key_pattern && "$REDIS_CLOUD_USER_KEY" =~ $key_pattern ]] || exit 2
case "$REDIS_CLOUD_PLAN" in
  essentials) prefix=/fixed ;;
  pro) prefix= ;;
  *) echo "Use essentials or pro (non-Active-Active)." >&2; exit 2 ;;
esac
response=$(
  printf 'x-api-key: %s\nx-api-secret-key: %s\n' "$REDIS_CLOUD_ACCOUNT_KEY" "$REDIS_CLOUD_USER_KEY" |
    curl -q --fail --silent --show-error --proto '=https' --max-time 30 \
      --header @- --header 'Accept: application/json' \
      "https://api.redislabs.com/v1$prefix/subscriptions/$REDIS_CLOUD_SUBSCRIPTION_ID/databases/$REDIS_CLOUD_DATABASE_ID"
)

# Do not print the full response: security objects may contain database credentials.
jq -e --argjson id "$REDIS_CLOUD_DATABASE_ID" --arg subscriptionId "$REDIS_CLOUD_SUBSCRIPTION_ID" '
  if .databaseId != $id or (.activeActiveRedis == true) or (.security | type) != "object"
  then error("unexpected database or missing security data")
  elif (.security.sourceIps | type) == "null"
  then {subscriptionId: $subscriptionId, databaseId, sourceIpEvidence: "not-reported", sourceIps: null}
  elif (.security.sourceIps | type) != "array" or any(.security.sourceIps[]; type != "string")
  then error("invalid source IP evidence; verify in console")
  else {subscriptionId: $subscriptionId, databaseId, sourceIpEvidence: "reported", sourceIps: .security.sourceIps}
  end
' <<< "$response"
# HTH Guide Excerpt: end inspect-database-source-ranges
