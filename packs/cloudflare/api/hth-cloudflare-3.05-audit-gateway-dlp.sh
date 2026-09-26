#!/usr/bin/env bash
# HTH Cloudflare Control 3.5: Configure Gateway Data Loss Prevention Profiles
# Profile: L2 | NIST: AC-4, SC-7(10) | CIS: 3.13
# https://howtoharden.com/guides/cloudflare/#35-configure-gateway-data-loss-prevention-profiles
#
# Read-only audit. Passes only when TLS decryption is on (DLP cannot inspect
# HTTPS payloads without it) AND at least one enabled HTTP policy with the
# Block action uses the DLP Profile selector (dlp.profiles) with a profile that
# exists. An Allow rule that merely matches a profile enforces nothing, and a
# negated match -- not(...) -- is ignored (common.sh positive_traffic).
source "$(dirname "$0")/common.sh"

banner "3.5: Configure Gateway Data Loss Prevention Profiles"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "3.5 Checking TLS decryption, DLP profiles and DLP policies..."

# HTH Guide Excerpt: begin api-audit-dlp
GW_CONFIG=$(cf_get "/accounts/${CF_ACCOUNT_ID}/gateway/configuration") || {
  fail "3.5 Unable to retrieve Gateway configuration"
  increment_failed
  summary
  exit 0
}
PROFILES=$(cf_get "/accounts/${CF_ACCOUNT_ID}/dlp/profiles") || {
  fail "3.5 Unable to list DLP profiles"
  increment_failed
  summary
  exit 0
}
RULES=$(cf_get "/accounts/${CF_ACCOUNT_ID}/gateway/rules") || {
  fail "3.5 Unable to retrieve Gateway rules"
  increment_failed
  summary
  exit 0
}

TLS_ON=$(echo "${GW_CONFIG}" | jq -r '.result.settings.tls_decrypt.enabled // false')
PROFILE_IDS=$(echo "${PROFILES}" | jq -c '[.result[].id]')
DLP_RULES=$(echo "${RULES}" | jq --argjson ids "${PROFILE_IDS}" "${JQ_GATEWAY_DEFS}"'[.result[]
  | select(.enabled == true and .action == "block" and (.filters | index("http")))
  | positive_traffic
  | select(test("dlp\\.profiles"))
  | select(. as $t | any($ids[]; . as $id | $t | contains($id)))] | length')
# DLP policies still in Allow (log-only) mode, e.g. the Terraform pack's default
LOG_ONLY=$(echo "${RULES}" | jq "${JQ_GATEWAY_DEFS}"'[.result[]
  | select(.enabled == true and .action == "allow" and (.filters | index("http")))
  | positive_traffic | select(test("dlp\\.profiles"))] | length')
info "3.5 DLP profiles: $(echo "${PROFILE_IDS}" | jq 'length'), enabled HTTP DLP block policies: ${DLP_RULES}, log-only (Allow) DLP policies: ${LOG_ONLY}"
# HTH Guide Excerpt: end api-audit-dlp

if [ "${TLS_ON}" != "true" ]; then
  fail "3.5 TLS decryption is off -- DLP cannot inspect HTTPS payloads"
  increment_failed
elif [ "${DLP_RULES}" = "0" ] && [ "${LOG_ONLY}" -gt 0 ]; then
  fail "3.5 ${LOG_ONLY} DLP policy(s) are in Allow (log-only) mode -- set the action to Block to enforce"
  increment_failed
elif [ "${DLP_RULES}" = "0" ]; then
  fail "3.5 No enabled HTTP Block policy uses a DLP profile"
  increment_failed
else
  pass "3.5 TLS decryption is on and ${DLP_RULES} HTTP policy(s) enforce DLP profiles"
  increment_applied
fi

summary
