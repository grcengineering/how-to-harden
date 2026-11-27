#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: gainsight-1.2
#   guide: https://howtoharden.com/guides/gainsight/
#   profile: L1
#   mode: read-only
#   requires: curl, jq, Gainsight tenant access key
# HTH Gainsight CS §1.2 Review Privileged Users | L1 | NIST AC-6
# Guide: https://howtoharden.com/guides/gainsight/
# Source: https://support.gainsight.com/docs/user-management-apis-1#fetch-user-details
# HTH Guide Excerpt: begin assess-super-admins
set -euo pipefail
set +x
: "${GAINSIGHT_URL:?Set the exact HTTPS origin of your Gainsight tenant}"
: "${GAINSIGHT_ACCESS_KEY:?Supply an approved tenant access key}"
if [[ ! "$GAINSIGHT_URL" =~ ^https://[A-Za-z0-9][A-Za-z0-9.-]+/?$ ]] ||
   [[ "$GAINSIGHT_ACCESS_KEY" == *$'\r'* || "$GAINSIGHT_ACCESS_KEY" == *$'\n'* ]]; then
  printf 'Invalid tenant origin or key format.\n' >&2
  exit 2
fi

origin=${GAINSIGHT_URL%/}
key=$GAINSIGHT_ACCESS_KEY
unset GAINSIGHT_ACCESS_KEY
umask 077
work=$(mktemp -d)
trap 'rm -f -- "$work/users.jsonl"; rmdir -- "$work"' EXIT
: > "$work/users.jsonl"
page=0
limit=25
seen=0
expected=-1
while (( page < 1000 )); do
  query=$(jq -cn --argjson page "$page" --argjson limit "$limit" '{
    includeTotal: true, page: $page, limit: $limit,
    orderBy: {Gsid: "asc"}, select: ["Gsid", "IsSuperAdmin"]
  }')
  # POST is the documented read query. Never follow redirects or write tenant records.
  reply=$(printf 'Accesskey: %s\n' "$key" |
    curl -q --silent --show-error --fail --proto '=https' --max-time 30 --header @- \
      --header 'Content-Type: application/json' --data-binary "$query" \
      "$origin/v1/users/services/list")
  if ! jq -e --argjson page "$page" '
    .result == true and .data.page == $page
    and (.data.total | type == "number" and . >= 0 and . == floor)
    and (.data.users | type == "array")
    and all(.data.users[]; (.Gsid | type == "string" and length > 0)
      and (.IsSuperAdmin | type == "boolean"))
  ' >/dev/null <<< "$reply"; then
    printf 'Gainsight returned a failed query or unexpected response.\n' >&2
    exit 1
  fi
  total=$(jq -r '.data.total' <<< "$reply")
  count=$(jq -r '.data.users | length' <<< "$reply")
  if (( expected < 0 )); then expected=$total; fi
  if (( total != expected || count > limit || seen + count > expected || (count < limit && seen + count < expected) )); then
    printf 'Inconsistent pagination. Retry and reconcile with the admin console.\n' >&2
    exit 1
  fi
  jq -c '.data.users[] | {Gsid, IsSuperAdmin}' <<< "$reply" >> "$work/users.jsonl"
  seen=$((seen + count))
  if (( seen == expected )); then
    jq -es '
      if ([.[].Gsid] | unique | length) != length then
        error("Duplicate user IDs across pages; rerun and reconcile")
      else
        {users: length, super_admins: (map(select(.IsSuperAdmin)) | length)}
      end
    ' "$work/users.jsonl"
    exit
  fi
  page=$((page + 1))
done
printf 'Audit reached the configured pagination ceiling; no result reported.\n' >&2
exit 1
# HTH Guide Excerpt: end assess-super-admins
