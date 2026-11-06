#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: openai-ads-3.3
#   guide: https://howtoharden.com/guides/openai-ads/#33-limit-customer-audiences-and-reconcile-membership
#   profile: L2
#   mode: read-only
#   requires: jq, shasum; stdin JSON array of approved ASCII email addresses
# Source: https://developers.openai.com/ads/custom-audiences#prepare-an-audience-file
# Native email_sha256 CSV emitter; no upload. NIST 800-53 PT-2, SI-12.
set -euo pipefail
# HTH Guide Excerpt: begin hashed-audience
emails=$(jq -er 'if type == "array" and all(.[]; type == "string" and
  test("^[[:space:]]*[A-Za-z0-9.!#$%&\u0027*+/=?^_`{|}~-]+@[A-Za-z0-9.-]+[[:space:]]*$"))
  then .[] | gsub("^[[:space:]]+|[[:space:]]+$"; "") | ascii_downcase
  else error("Expected approved ASCII emails; handle international identifiers separately") end')
printf 'email_sha256\n'
while IFS= read -r email; do
  [[ -n "$email" ]] || continue
  printf '%s' "$email" | shasum -a 256 | cut -d ' ' -f 1
done <<<"$emails"
# Preserve email plus tags and dots. Hash UTF-8 without a trailing newline.
# Phone normalization differs between custom audiences and Pixel matching;
# never reuse a Pixel phone hash for the E.164 audience contract.
# HTH Guide Excerpt: end hashed-audience
