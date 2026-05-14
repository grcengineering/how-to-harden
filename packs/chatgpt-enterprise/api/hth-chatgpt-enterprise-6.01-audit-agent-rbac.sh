#!/usr/bin/env bash
# HTH ChatGPT Enterprise Control 6.1: Audit Workspace Agent RBAC Posture
# Profile: L1 | NIST: AC-2, AC-6 | SOC 2: CC6.1
# https://howtoharden.com/guides/chatgpt-enterprise/#61-keep-workspace-agents-disabled-until-governance-is-in-place
#
# Workspace agents inherit the workspace's RBAC roles. There is no Compliance
# API endpoint that lists "who can build agents" directly — that information
# lives in the Global Admin Console. This script samples USER_LOG events to
# discover who has been authenticated as agent builders / runners, so the
# auditor can cross-reference against the role membership exported from the
# admin console (Workspace settings → Members → Roles).

source "$(dirname "$0")/common.sh"

banner "6.1: Audit Workspace Agent RBAC Posture"
require_compliance_key

AFTER="${AFTER:-$(date -u -v-30d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '30 days ago' +%Y-%m-%dT%H:%M:%SZ)}"

# HTH Guide Excerpt: begin api-audit-rbac
# Pull recent authentication events to identify the active user set whose
# agent privileges should be reviewed in the Global Admin Console.
info "Listing USER_LOG events since ${AFTER}..."
LOG_IDS=$(compliance_paginate_log_ids "USER_LOG" "${AFTER}" 100) || {
  fail "6.1 Failed to list USER_LOG events — confirm COMPLIANCE_API_KEY scope"
  summary; exit 0
}

COUNT=$(echo "${LOG_IDS}" | grep -c . || true)
info "Retrieved ${COUNT} USER_LOG file(s) for the window"

if [[ "${COUNT}" -eq 0 ]]; then
  warn "6.1 No USER_LOG entries returned — verify principal scope and event_type spelling"
else
  pass "6.1 USER_LOG sample retrieved — export role membership from Workspace settings → Members → Roles and cross-reference manually"
fi
# HTH Guide Excerpt: end api-audit-rbac

echo ""
info "Next step: in the Global Admin Console → Agents, confirm the list of"
info "agents and their owners matches your authorized agents-build group."

summary
