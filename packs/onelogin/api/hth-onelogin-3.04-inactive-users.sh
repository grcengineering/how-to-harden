#!/usr/bin/env bash
# HTH OneLogin Control 3.4: Automatically Suspend Inactive Users
# Profile: L1 | CIS Controls: 5.3 | NIST 800-53: AC-2(3)
# https://howtoharden.com/guides/onelogin/#34-automatically-suspend-inactive-users
#
# Interface: OneLogin REST API v2 (first-party).
#   OAuth token: https://developers.onelogin.com/api-docs/2/oauth20-tokens/generate-tokens-2
#   List Users:  https://developers.onelogin.com/api-docs/2/users/list-users
# The user policy's automatic suspension is configured in the console; this
# script is the VERIFICATION side — it finds accounts whose last_login predates
# the cutoff so you can confirm suspension is actually working and catch
# dormant accounts the policy has not yet caught.
#
# Environment:
#   ONELOGIN_SUBDOMAIN      e.g. mycompany (for mycompany.onelogin.com)
#   ONELOGIN_CLIENT_ID      API credential pair client ID (Read All or higher)
#   ONELOGIN_CLIENT_SECRET  API credential pair client secret

set -euo pipefail
: "${ONELOGIN_SUBDOMAIN:?Set ONELOGIN_SUBDOMAIN}"
: "${ONELOGIN_CLIENT_ID:?Set ONELOGIN_CLIENT_ID}"
: "${ONELOGIN_CLIENT_SECRET:?Set ONELOGIN_CLIENT_SECRET}"
BASE_URL="https://${ONELOGIN_SUBDOMAIN}.onelogin.com"

# HTH Guide Excerpt: begin api-get-token
# Client-credentials access token (valid 10 hours).
ACCESS_TOKEN=$(curl -sf "${BASE_URL}/auth/oauth2/v2/token" \
  -X POST \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=client_credentials' \
  --data-urlencode "client_id=${ONELOGIN_CLIENT_ID}" \
  --data-urlencode "client_secret=${ONELOGIN_CLIENT_SECRET}" | jq -r '.access_token')
# HTH Guide Excerpt: end api-get-token

# HTH Guide Excerpt: begin api-find-inactive-users
# List accounts whose last login predates the inactivity cutoff.
# last_login_until is a documented v2 List Users filter (ISO8601).
# 90 days mirrors OneLogin's documented default inactivity period —
# tighten the window for admin and contractor policies.
CUTOFF=$(date -u -d "90 days ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-90d +%Y-%m-%dT%H:%M:%SZ)

curl -sf -G "${BASE_URL}/api/2/users" \
  --data-urlencode "last_login_until=${CUTOFF}" \
  --data-urlencode "fields=id,username,email,state,status,last_login" \
  -H "Authorization: bearer ${ACCESS_TOKEN}" |
  jq -r '.[] | [.id, .username, (.email // "-"), (.last_login // "never"), .status, .state] | @tsv'
# HTH Guide Excerpt: end api-find-inactive-users

# HTH Guide Excerpt: begin api-find-never-logged-in
# Accounts created before the cutoff that have never signed in — unclaimed
# accounts are unclaimed credentials and belong in the same review.
curl -sf -G "${BASE_URL}/api/2/users" \
  --data-urlencode "created_until=${CUTOFF}" \
  --data-urlencode "fields=id,username,email,created_at,last_login" \
  -H "Authorization: bearer ${ACCESS_TOKEN}" |
  jq -r '.[] | select(.last_login == null) | [.id, .username, (.email // "-"), .created_at] | @tsv'
# HTH Guide Excerpt: end api-find-never-logged-in
