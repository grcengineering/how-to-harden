#!/usr/bin/env bash
# HTH Cloudflare Control 5.3: Detect and Block TryCloudflare Quick Tunnel Abuse
# Profile: L1 | NIST: CM-7(2), SI-4 | CIS: 4.8, 13.3
# https://howtoharden.com/guides/cloudflare/#53-detect-and-block-trycloudflare-quick-tunnel-abuse
#
# Read-only audit. Passes when an enabled Gateway DNS block rule matches
# trycloudflare.com; warns when no HTTP block rule backs it up. Only the
# non-negated part of a rule's expression counts (common.sh positive_traffic),
# so not(...) or != "trycloudflare.com" does not look like a block.
source "$(dirname "$0")/common.sh"

banner "5.3: Detect and Block TryCloudflare Quick Tunnel Abuse"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "5.3 Checking Gateway rules for trycloudflare.com blocks..."

# HTH Guide Excerpt: begin api-audit-trycloudflare
RULES=$(cf_get "/accounts/${CF_ACCOUNT_ID}/gateway/rules") || {
  fail "5.3 Unable to retrieve Gateway rules"
  increment_failed
  summary
  exit 0
}
DNS_BLOCKS=$(echo "${RULES}" | jq "${JQ_GATEWAY_DEFS}"'[.result[]
  | select(.enabled == true and .action == "block" and (.filters | index("dns")))
  | positive_traffic
  | select(test("trycloudflare\\.com"))] | length')
HTTP_BLOCKS=$(echo "${RULES}" | jq "${JQ_GATEWAY_DEFS}"'[.result[]
  | select(.enabled == true and .action == "block" and (.filters | index("http")))
  | positive_traffic
  | select(test("trycloudflare\\.com"))] | length')
# HTH Guide Excerpt: end api-audit-trycloudflare

[ "${HTTP_BLOCKS}" -gt 0 ] || warn "5.3 No HTTP block rule for trycloudflare.com (defence in depth)"
if [ "${DNS_BLOCKS}" -gt 0 ]; then
  pass "5.3 ${DNS_BLOCKS} enabled DNS rule(s) block trycloudflare.com"
  increment_applied
else
  fail "5.3 No enabled DNS rule blocks trycloudflare.com"
  increment_failed
fi

summary
