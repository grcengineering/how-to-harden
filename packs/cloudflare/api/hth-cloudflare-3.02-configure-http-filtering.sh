#!/usr/bin/env bash
# HTH Cloudflare Control 3.2: Configure HTTP Filtering
# Profile: L1 | NIST: SC-7, SI-4 | CIS: 9.2, 13.3
# https://howtoharden.com/guides/cloudflare/#32-configure-http-filtering
#
# 1. Reads the account Gateway configuration and reports whether TLS
#    decryption and antivirus scanning ("Scan files for malware") are on.
#    Those are account-wide settings; this pack never changes them.
# 2. Looks for an enabled HTTP block rule on the Malware (117) security
#    category; creates one only with HTH_APPLY=1.
# Malware, Phishing, Spyware and Command and Control & Botnet are SECURITY
# categories, so the rule uses http.request.uri.security_category.
source "$(dirname "$0")/common.sh"

banner "3.2: Configure HTTP Filtering"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "3.2 Checking Gateway HTTP policies and inspection settings..."

GW_CONFIG=$(cf_get "/accounts/${CF_ACCOUNT_ID}/gateway/configuration") || {
  fail "3.2 Unable to retrieve Gateway configuration"
  increment_failed
  summary
  exit 0
}
TLS_ON=$(echo "${GW_CONFIG}" | jq -r '.result.settings.tls_decrypt.enabled // false')
AV_DOWNLOAD=$(echo "${GW_CONFIG}" | jq -r '.result.settings.antivirus.enabled_download_phase // false')
SETTINGS_OK=1
if [ "${TLS_ON}" = "true" ]; then
  info "3.2 TLS decryption is on"
else
  warn "3.2 TLS decryption is off -- HTTP policies cannot inspect HTTPS traffic"
  SETTINGS_OK=0
fi
if [ "${AV_DOWNLOAD}" = "true" ]; then
  info "3.2 Antivirus scanning of downloads is on"
else
  warn "3.2 Antivirus scanning of downloads is off (Traffic settings > Scan files for malware)"
  SETTINGS_OK=0
fi

# HTH Guide Excerpt: begin api-create-http-policy
# Create Gateway HTTP policy to block malware downloads
EXISTING=$(cf_get "/accounts/${CF_ACCOUNT_ID}/gateway/rules") || {
  fail "3.2 Unable to retrieve Gateway rules"
  increment_failed
  summary
  exit 0
}

MALWARE_RULES=$(echo "${EXISTING}" | jq "${JQ_GATEWAY_DEFS}"'[.result[]
  | select(.filters == ["http"] and .action == "block" and .enabled == true)
  | positive_traffic
  | select(test("http\\.request\\.uri\\.security_category"))
  | select(test("\\b117\\b"))] | length')

if [ "${MALWARE_RULES}" -eq 0 ]; then
  may_write "create the HTTP rule 'HTH: Block Malware Downloads (HTTP)'" || {
    fail "3.2 No enabled HTTP rule blocks the malware security category"
    increment_failed
    summary
    exit 0
  }
  info "3.2 Creating HTTP malware blocking rule..."
  RESPONSE=$(cf_post "/accounts/${CF_ACCOUNT_ID}/gateway/rules" '{
    "name": "HTH: Block Malware Downloads (HTTP)",
    "action": "block",
    "filters": ["http"],
    "traffic": "any(http.request.uri.security_category[*] in {80 117 131 153})",
    "enabled": true,
    "precedence": 10,
    "rule_settings": {
      "block_page_enabled": true,
      "block_reason": "Blocked: malware risk detected in download"
    }
  }') || {
    fail "3.2 Failed to create HTTP blocking rule"
    increment_failed
    summary
    exit 0
  }
  if [ "$(echo "${RESPONSE}" | jq -r '.success')" != "true" ]; then
    fail "3.2 HTTP rule creation failed"
    echo "${RESPONSE}" | jq '.errors'
    increment_failed
    summary
    exit 0
  fi
  pass "3.2 HTTP malware blocking rule created"
else
  pass "3.2 Found ${MALWARE_RULES} HTTP rule(s) blocking the malware security category"
fi
# HTH Guide Excerpt: end api-create-http-policy

if [ "${SETTINGS_OK}" = "1" ]; then
  increment_applied
else
  fail "3.2 TLS decryption and antivirus scanning of downloads must both be on"
  increment_failed
fi

summary
