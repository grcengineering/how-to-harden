#!/usr/bin/env bash
# HTH ServiceNow Control 2.2: Enable High-Security Plugins
# Profile: L2 | NIST: CM-6
# https://howtoharden.com/guides/servicenow/#22-enable-high-security-plugins
source "$(dirname "$0")/common.sh"

banner "2.2: Enable High-Security Plugins"

should_apply 2 || { increment_skipped; summary; exit 0; }
info "2.2 Auditing high-security plugin status and hardening properties..."

# ---------------------------------------------------------------------------
# Check if the High Security Settings plugin is active
# ---------------------------------------------------------------------------
# HTH Guide Excerpt: begin api-check-high-security-plugin
info "2.2 Checking High Security Settings plugin..."
HS_PLUGIN=$(sn_table_get "sys_plugins" \
  "sysparm_query=id=com.glide.security.high&sysparm_fields=id,active" \
  | jq -r '.result[0].active // empty' 2>/dev/null || true)

if [ "${HS_PLUGIN}" = "active" ]; then
  pass "2.2 High Security Settings plugin is active"
  increment_applied
else
  fail "2.2 High Security Settings plugin is NOT active"
  fail "2.2 Navigate to System Definition > Plugins and activate 'High Security Settings'"
  increment_failed
fi
# HTH Guide Excerpt: end api-check-high-security-plugin

# ---------------------------------------------------------------------------
# Verify key security properties enforced by the plugin
# ---------------------------------------------------------------------------
# HTH Guide Excerpt: begin api-check-security-properties
info "2.2 Checking security system properties..."

check_property() {
  local prop_name="$1"
  local expected="$2"
  local description="$3"

  local value
  value=$(sn_property "${prop_name}")

  if [ "${value}" = "${expected}" ]; then
    pass "2.2 ${description}: ${prop_name}=${value}"
  elif [ -z "${value}" ]; then
    warn "2.2 ${description}: ${prop_name} not set (expected: ${expected})"
  else
    fail "2.2 ${description}: ${prop_name}=${value} (expected: ${expected})"
  fi
}

check_property "glide.security.default.deny" "true" \
  "Default deny ACLs"
check_property "glide.security.use_secure_cookies" "true" \
  "Secure cookies"
check_property "glide.security.strict.xframe" "true" \
  "X-Frame-Options strict mode"
check_property "glide.basicauth.required.user_password" "true" \
  "Require password for basic auth"
check_property "glide.security.csrf_previous.enabled" "true" \
  "CSRF protection"
# HTH Guide Excerpt: end api-check-security-properties

# ---------------------------------------------------------------------------
# Verify ACL rules exist (default deny means ACLs are required)
# ---------------------------------------------------------------------------
info "2.2 Sampling ACL rules to confirm default-deny posture..."
ACL_COUNT=$(sn_table_get "sys_security_acl" \
  "sysparm_query=active=true&sysparm_limit=1&sysparm_fields=sys_id" \
  | jq -r '.result | length' 2>/dev/null || echo "0")

if [ "${ACL_COUNT}" -gt 0 ]; then
  info "2.2 Active ACL rules found — default-deny posture has explicit allow rules"
else
  warn "2.2 No active ACL rules found — verify ACL configuration"
fi

summary
