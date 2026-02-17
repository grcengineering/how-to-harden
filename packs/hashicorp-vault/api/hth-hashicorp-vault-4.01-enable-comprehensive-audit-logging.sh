#!/usr/bin/env bash
# HTH HashiCorp Vault Control 4.1: Enable Comprehensive Audit Logging
# Profile: L1 | NIST: AU-2, AU-3, AU-6, AU-12 | SOC 2: CC7.2
# https://howtoharden.com/guides/hashicorp-vault/#41-enable-comprehensive-audit-logging
source "$(dirname "$0")/common.sh"

banner "4.1: Enable Comprehensive Audit Logging"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "4.1 Configuring audit logging devices..."

# Check existing audit devices
EXISTING_AUDIT=$(vault_get "/sys/audit" 2>/dev/null || echo '{}')
FILE_ENABLED=$(echo "${EXISTING_AUDIT}" | jq -r '.data["file/"] // .["file/"] // empty' 2>/dev/null || true)
SYSLOG_ENABLED=$(echo "${EXISTING_AUDIT}" | jq -r '.data["syslog/"] // .["syslog/"] // empty' 2>/dev/null || true)

# HTH Guide Excerpt: begin api-enable-audit
# Enable file audit device
if [ -n "${FILE_ENABLED}" ]; then
  pass "4.1 File audit device already enabled"
else
  info "4.1 Enabling file audit device..."
  vault_put "/sys/audit/file" '{
    "type": "file",
    "description": "File-based audit log for local retention",
    "options": {
      "file_path": "/var/log/vault/audit.log",
      "log_raw": false,
      "hmac_accessor": true,
      "mode": "0600"
    }
  }' > /dev/null 2>&1 && pass "4.1 File audit device enabled" \
    || { fail "4.1 Failed to enable file audit device"; increment_failed; }
fi

# Enable syslog audit device
if [ -n "${SYSLOG_ENABLED}" ]; then
  pass "4.1 Syslog audit device already enabled"
else
  info "4.1 Enabling syslog audit device..."
  vault_put "/sys/audit/syslog" '{
    "type": "syslog",
    "description": "Syslog audit device for SIEM integration",
    "options": {
      "tag": "vault-audit",
      "facility": "AUTH",
      "log_raw": false
    }
  }' > /dev/null 2>&1 && pass "4.1 Syslog audit device enabled" \
    || { fail "4.1 Failed to enable syslog audit device"; increment_failed; }
fi
# HTH Guide Excerpt: end api-enable-audit

# Verify all active audit devices
info "4.1 Verifying active audit devices..."
VERIFY_AUDIT=$(vault_get "/sys/audit" 2>/dev/null || echo '{}')
DEVICE_COUNT=$(echo "${VERIFY_AUDIT}" | jq '[.data // . | keys[] | select(. != "request_id" and . != "lease_id" and . != "renewable" and . != "lease_duration")] | length' 2>/dev/null || echo "0")

if [ "${DEVICE_COUNT}" -ge 2 ]; then
  pass "4.1 ${DEVICE_COUNT} audit device(s) active (minimum 2 recommended)"
  echo "${VERIFY_AUDIT}" | jq -r '.data // . | to_entries[] | select(.value.type?) | "  - \(.key) (type: \(.value.type))"' 2>/dev/null || true
  increment_applied
elif [ "${DEVICE_COUNT}" -ge 1 ]; then
  warn "4.1 Only ${DEVICE_COUNT} audit device active -- enable a second device for redundancy"
  increment_applied
else
  fail "4.1 No audit devices enabled -- Vault operations are not being logged"
  increment_failed
fi

summary
