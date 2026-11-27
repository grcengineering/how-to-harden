#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: articulate-360-2.1
#   guide:   https://howtoharden.com/guides/articulate-360/
#   profile: L2
#   mode:    read-only
#   requires: REACH360_REGION, REACH360_USER_ID, REACH360_APPROVED_ROLE, REACH360_API_KEY, curl, jq
# First-party source: https://www.articulatesupport.com/article/Reach-360-Users-API
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
region=${REACH360_REGION:?Set us or eu for the approved data region}
user=${REACH360_USER_ID:?Set the selected Reach user ID}
expected=${REACH360_APPROVED_ROLE:?Set the independently approved role}
case "$region" in
  us) host=api.reach360.com ;;
  eu) host=api.reach360.eu ;;
  *) exit 2 ;;
esac
[[ "$user" =~ ^[A-Za-z0-9_-]+$ ]] || exit 2
case "$expected" in
  learner|author|reporter|manager|admin) ;;
  *) exit 2 ;;
esac

token=${REACH360_API_KEY:?Set a previously authorized bearer credential}
[[ "$token" != *$'\r'* && "$token" != *$'\n'* ]] || exit 2

body=$(printf 'Authorization: Bearer %s\n' "$token" |
  curl -q --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 40 --header @-  "https://$host/users/$user")

result=$(jq -ce --arg id "$user" --arg expected "$expected" '
  if .id==$id and (.role|IN("learner","author","reporter","manager","admin"))
  then {id,role,matches:(.role==$expected)}
  else error("Reach user ID or role not verified") end
' <<<"$body")
printf '%s\n' "$result"
jq -e '.matches' <<<"$result" >/dev/null
# HTH Guide Excerpt: end read-evidence
