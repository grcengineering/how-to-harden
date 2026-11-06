#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: claude-enterprise-4.1
#   guide: https://howtoharden.com/guides/claude-enterprise/#41-enforce-per-member-spend-limits
#   profile: L2
#   mode: read-only
#   requires: ANTHROPIC_ADMIN_KEY(read:spend_limits)
# Source: https://platform.claude.com/docs/en/manage-claude/spend-limits-api
set -euo pipefail
source "$(dirname "$0")/../../anthropic-claude/api/common.sh"
# HTH Guide Excerpt: begin effective-member-spend-limits
evidence=$(anthropic_evidence_dir)
trap 'rm -f "${evidence}/limits.pending"' EXIT
anthropic_page_token_all '/v1/organizations/spend_limits/effective?period%5B%5D=monthly' > "${evidence}/limits.pending"
jq -e 'all(.[]; (.scope|type)=="object" and (.period|type)=="string" and (.currency|type)=="string" and has("amount") and (.amount==null or ((.amount|type)=="string" and (.amount|test("^[0-9]+$")))))' "${evidence}/limits.pending" >/dev/null
mv "${evidence}/limits.pending" "${evidence}/effective-spend-limits.json"
printf 'Private effective-limit evidence: %s (amounts are currency minor units).\n' "${evidence}/effective-spend-limits.json"
# Empty or future scope/period results are evidence to review, never a healthy sweep.
jq -e 'length > 0 and all(.[]; .scope.type=="user" and (.scope.user_id|type)=="string" and .period=="monthly") and (map(.scope.user_id)|unique|length)==length' "${evidence}/effective-spend-limits.json" >/dev/null || exit 2
if jq -e 'any(.[]; .amount==null)' "${evidence}/effective-spend-limits.json" >/dev/null; then
  echo 'Unlimited monthly member limit found; review before changing inheritance.' >&2
  exit 1
fi
echo 'Returned monthly member rows have finite limits; reconcile membership and approved amounts separately.'
# HTH Guide Excerpt: end effective-member-spend-limits
