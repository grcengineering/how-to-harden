#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cognism-1.3
#   guide: https://howtoharden.com/guides/cognism/#13-detect-drift-in-account-contact-restrictions
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq, shasum, current approved Cognism M2M token and approved digest
# Source (checked 2026-11-27): https://docs.cognism.com/reference/getcompliancesettings
# Review locally; protect evidence from unnecessary disclosure.

# HTH Guide Excerpt: begin cognism-evidence
set +x
set -euo pipefail
: "${HTH_COGNISM_TOKEN:?Set an approved Cognism M2M access token.}"
: "${HTH_COGNISM_EXPECTED_DIGEST:?Set the approved canonical compliance JSON SHA-256.}"
[[ "$HTH_COGNISM_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ && "$HTH_COGNISM_EXPECTED_DIGEST" =~ ^[0-9a-f]{64}$ ]] ||
  { printf 'Invalid token or baseline digest.\n' >&2; exit 2; }
checksum=$(
  printf 'Authorization: Bearer %s\n' "$HTH_COGNISM_TOKEN" |
    curl -q --silent --show-error --fail --proto '=https' --connect-timeout 10 --max-time 30 --header @- --max-filesize 1048576 \
      --header 'Accept: application/json' 'https://api.cognism.com/settings/compliance' |
    jq -ceSs '
      if length == 1 and (.[0] | type) == "object" and (.[0] | length) > 0 and (.[0] | has("error") | not)
      then .[0] else error("Expected a nonempty compliance object") end' |
    shasum -a 256
)
if [[ "${checksum%% *}" == "$HTH_COGNISM_EXPECTED_DIGEST" ]]; then
  printf '{"matches_approved_baseline":true}\n'
else
  printf '{"matches_approved_baseline":false}\n'
  exit 1
fi
# HTH Guide Excerpt: end cognism-evidence
