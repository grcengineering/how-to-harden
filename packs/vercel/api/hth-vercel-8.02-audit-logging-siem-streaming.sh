#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 8.2: Enable Audit Logging with SIEM Streaming
# Profile Level: L2 (Hardened)
# Frameworks: NIST AU-2, AU-3, AU-12
# Source: https://howtoharden.com/guides/vercel/#82-enable-audit-logging-with-siem-streaming
# =============================================================================

set -euo pipefail

# HTH Guide Excerpt: begin api

# --- Retrieve recent audit log events (Enterprise) ---
echo "=== Recent Audit Log Events ==="
curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  "https://api.vercel.com/v1/events?teamId=${VERCEL_TEAM_ID}&limit=20&types=team.member.role.updated,project.env_variable.created,saml.updated" | \
  jq '.events[]? | {
    id,
    type,
    createdAt,
    actor: .actor.slug,
    entityId: .entityId
  }'

# --- List security-critical event types to monitor ---
echo ""
echo "=== Critical Events for SIEM Alerting ==="
echo "Configure SIEM detection rules for these event types:"
echo "  - team.member.role.updated     (privilege escalation)"
echo "  - team.member.invited          (new access grants)"
echo "  - team.member.removed          (access revocation)"
echo "  - project.env_variable.created (secret addition)"
echo "  - project.env_variable.updated (secret modification)"
echo "  - deployment-protection.updated (protection changes)"
echo "  - password_protection.disabled  (protection removal)"
echo "  - saml.updated                  (SSO config changes)"
echo "  - integration.installed         (new integrations)"
echo "  - domain.added                  (domain changes)"

# --- Export audit log CSV (for compliance reporting) ---
echo ""
echo "=== Export Audit Log (last 30 days) ==="
# Navigate to Team Settings > Security > Audit Log > Export CSV
echo "Manual export available at: https://vercel.com/team/${VERCEL_TEAM_ID}/settings/security"

# --- Verify log drain is receiving audit events ---
echo ""
echo "=== Log Drain Status ==="
curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  "https://api.vercel.com/v1/log-drains?teamId=${VERCEL_TEAM_ID}" | \
  jq '.[] | {id, name, url: .endpoint, status, sources, environments}'

# HTH Guide Excerpt: end api
