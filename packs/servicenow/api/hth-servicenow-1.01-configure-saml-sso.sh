#!/usr/bin/env bash
# HTH ServiceNow Control 1.1: Configure SAML Single Sign-On
# Profile: L1 | NIST: IA-2, IA-8
# https://howtoharden.com/guides/servicenow/#11-configure-saml-single-sign-on
source "$(dirname "$0")/common.sh"

banner "1.1: Configure SAML Single Sign-On"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.1 Auditing SAML SSO configuration..."

# ---------------------------------------------------------------------------
# Check if Multi-Provider SSO plugin is active
# ---------------------------------------------------------------------------
# HTH Guide Excerpt: begin api-check-sso-plugin
info "1.1 Checking Multi-Provider SSO plugin status..."
SSO_PLUGIN=$(sn_table_get "sys_plugins" \
  "sysparm_query=id=com.snc.integration.sso.multi&sysparm_fields=id,active" \
  | jq -r '.result[0].active // empty' 2>/dev/null || true)

if [ "${SSO_PLUGIN}" = "active" ]; then
  pass "1.1 Multi-Provider SSO plugin is active"
else
  fail "1.1 Multi-Provider SSO plugin is NOT active — enable via Plugins"
  increment_failed
fi
# HTH Guide Excerpt: end api-check-sso-plugin

# ---------------------------------------------------------------------------
# Check SSO properties for SAML configuration
# ---------------------------------------------------------------------------
# HTH Guide Excerpt: begin api-check-sso-properties
info "1.1 Checking SSO properties..."
SSO_ENABLED=$(sn_table_get "sys_properties" \
  "sysparm_query=name=glide.authenticate.sso.redirect.url&sysparm_fields=name,value" \
  | jq -r '.result[0].value // empty' 2>/dev/null || true)

if [ -n "${SSO_ENABLED}" ]; then
  pass "1.1 SAML SSO redirect URL is configured: ${SSO_ENABLED}"
else
  warn "1.1 SAML SSO redirect URL not found — SSO may not be configured"
fi

# Verify SAML 2.0 IdP records exist
IDP_COUNT=$(sn_table_get "sso_properties" \
  "sysparm_query=protocol=saml2&sysparm_fields=name,protocol,is_default" \
  | jq -r '.result | length' 2>/dev/null || echo "0")

if [ "${IDP_COUNT}" -gt 0 ]; then
  pass "1.1 Found ${IDP_COUNT} SAML 2.0 Identity Provider configuration(s)"
  increment_applied
else
  fail "1.1 No SAML 2.0 IdP configurations found — configure SSO in Multi-Provider SSO"
  increment_failed
fi
# HTH Guide Excerpt: end api-check-sso-properties

# ---------------------------------------------------------------------------
# Verify account recovery administrator is set (Control 1.2)
# ---------------------------------------------------------------------------
info "1.1 Checking for local admin break-glass account..."
LOCAL_ADMINS=$(sn_table_get "sys_user_has_role" \
  "sysparm_query=role.name=admin&sysparm_fields=user.user_name,user.name" \
  | jq -r '.result | length' 2>/dev/null || echo "0")

if [ "${LOCAL_ADMINS}" -gt 0 ]; then
  info "1.1 Found ${LOCAL_ADMINS} admin role assignment(s) — verify break-glass account exists"
else
  warn "1.1 No admin role assignments found — ensure a recovery admin account exists"
fi

summary
