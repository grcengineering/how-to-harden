#!/usr/bin/env bash
# HTH ServiceNow Control 4.1: Configure Audit Logging
# Profile: L1 | NIST: AU-2
# https://howtoharden.com/guides/servicenow/#41-configure-audit-logging
source "$(dirname "$0")/common.sh"

banner "4.1: Configure Audit Logging"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "4.1 Auditing audit logging configuration..."

# ---------------------------------------------------------------------------
# Verify audit system properties
# ---------------------------------------------------------------------------
# HTH Guide Excerpt: begin api-check-audit-properties
info "4.1 Checking audit-related system properties..."

AUDIT_ACTIVE=$(sn_property "glide.sys.audit.active")
if [ "${AUDIT_ACTIVE}" = "true" ]; then
  pass "4.1 System audit is active (glide.sys.audit.active=true)"
  increment_applied
else
  fail "4.1 System audit is NOT active — set glide.sys.audit.active=true"
  increment_failed
fi

AUDIT_DELETE=$(sn_property "glide.sys.audit.delete")
if [ "${AUDIT_DELETE}" = "true" ]; then
  pass "4.1 Delete auditing is enabled (glide.sys.audit.delete=true)"
else
  warn "4.1 Delete auditing is not enabled — set glide.sys.audit.delete=true"
fi

LOGIN_TRACKING=$(sn_property "glide.ui.login_tracking")
if [ "${LOGIN_TRACKING}" = "true" ]; then
  pass "4.1 Login tracking is enabled (glide.ui.login_tracking=true)"
else
  warn "4.1 Login tracking is not enabled — set glide.ui.login_tracking=true"
fi
# HTH Guide Excerpt: end api-check-audit-properties

# ---------------------------------------------------------------------------
# Query recent audit entries to verify logging is operational
# ---------------------------------------------------------------------------
# HTH Guide Excerpt: begin api-query-recent-audits
info "4.1 Querying recent audit log entries..."
RECENT_AUDITS=$(sn_table_get "sys_audit" \
  "sysparm_query=ORDERBYDESCsys_created_on&sysparm_limit=10&sysparm_fields=sys_created_on,user,tablename,fieldname,newvalue,oldvalue" \
  2>/dev/null || true)

AUDIT_COUNT=$(echo "${RECENT_AUDITS}" | jq -r '.result | length' 2>/dev/null || echo "0")

if [ "${AUDIT_COUNT}" -gt 0 ]; then
  pass "4.1 Audit log is operational — found ${AUDIT_COUNT} recent entries"
  info "4.1 Latest audit entries:"
  echo "${RECENT_AUDITS}" | jq -r '.result[:5][] | "  - \(.sys_created_on) | \(.user) | \(.tablename).\(.fieldname) | \(.oldvalue // "-") -> \(.newvalue // "-")"' 2>/dev/null || true
else
  fail "4.1 No recent audit entries found — verify audit configuration"
  increment_failed
fi
# HTH Guide Excerpt: end api-query-recent-audits

# ---------------------------------------------------------------------------
# Check audit table rotation / retention
# ---------------------------------------------------------------------------
info "4.1 Checking audit table record count (retention indicator)..."
TOTAL_AUDITS=$(sn_get "/stats/sys_audit?sysparm_count=true" \
  | jq -r '.result.stats.count // empty' 2>/dev/null || true)

if [ -n "${TOTAL_AUDITS}" ]; then
  info "4.1 Total audit records: ${TOTAL_AUDITS}"
  if [ "${TOTAL_AUDITS}" -lt 1000 ] 2>/dev/null; then
    warn "4.1 Low audit record count (${TOTAL_AUDITS}) — verify retention policy"
  fi
else
  info "4.1 Could not retrieve audit record count (stats API may require elevated access)"
fi

summary
